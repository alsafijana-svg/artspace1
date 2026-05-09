import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'profile_page.dart';
import 'plus_page.dart';
import 'partnerships_page.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:artspace1/pages/reservation_page.dart';
import 'manage_page.dart';
import 'user_workshop_detail_page.dart';


class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0; // تحديد الصفحة الحالية من bottom navigation bar
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();


  List<Map<String, dynamic>> mostFamous = [];
  bool isLoadingFamous = true;

  String? userType; // تحديد الواجهة حسب نوع المستحدم
  bool isLoadingUser = true;

  @override
  void initState() {
    super.initState();
    _fetchUserType();
    loadMostFamous();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ------------------------ Load Most Famous Workshops ------------------------
  void loadMostFamous() async {
    try {
      final reservationsSnapshot =
      await FirebaseFirestore.instance
          .collection('reservations')
          .where('status', isEqualTo: "Confirm") // خذ الحجوزات المؤكدة فقط
          .get();

      Map<String, int> bookingCounts = {};

      // عد الحجوزات لكل ورشة
      for (var doc in reservationsSnapshot.docs) {
        String? title = doc.data()['title'] as String?;
        if (title != null) {
          bookingCounts[title] = (bookingCounts[title] ?? 0) + 1;
        }
      }

      List<Map<String, dynamic>> tempList = [];

      for (var entry in bookingCounts.entries) {
        final workshopSnapshot = await FirebaseFirestore.instance
            .collection('user_workshops')
            .where('title', isEqualTo: entry.key)
            .limit(1)
            .get();

        // ===== فحص إذا الورشة مفضلة =====
        bool isFavorite = false;
        final user = FirebaseAuth.instance.currentUser;

        if (user != null && workshopSnapshot.docs.isNotEmpty) {
          final workshopId = workshopSnapshot.docs.first.id;

          final favSnapshot = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('favorites')
              .doc(workshopId)
              .get();

          if (favSnapshot.exists && favSnapshot.data()?['isFavorite'] == true) {
            isFavorite = true;
          }
        }

        // ===== إضافة الورشة للقائمة =====
        if (workshopSnapshot.docs.isNotEmpty) {
          final data = workshopSnapshot.docs.first.data();
          tempList.add({
            "id": workshopSnapshot.docs.first.id, // مهم للتحديث والحذف
            "title": data['title'] ?? entry.key,
            "count": entry.value,
            "images": data['images'] ?? [],
            "description": data['description'] ?? "",
            "price": data['price'] ?? "Not provided",
            "city": data['city'] ?? "",
            "openingHours": data['openingHours'] ?? "",
            "facilities": data['facilities'] ?? [],
            "location": data['location'] ?? "",
            "isFavorite": isFavorite, // ← القلب محدد أو لا
          });
        } else {
          // إذا الورشة موجودة في reservations فقط
          tempList.add({
            "id": entry.key, // استخدم title كـ id مؤقت إذا ما فيه doc
            "title": entry.key,
            "count": entry.value,
            "images": [],
            "description": "Not provided",
            "price": "Not Provided",
            "city": "Not provided",
            "openingHours": "Not provided",
            "facilities": [],
            "location": "Not provided",
            "isFavorite": isFavorite,
          });
        }
      }

      // ترتيب حسب عدد الحجوزات
      tempList.sort((a, b) => (b["count"] ?? 0).compareTo(a["count"] ?? 0));

      setState(() {
        mostFamous = tempList;
        isLoadingFamous = false;
      });
    } catch (e) {
      print("Error loading most famous workshops: $e");
      setState(() {
        mostFamous = [];
        isLoadingFamous = false;
      });
    }
  }
  // ------------------------ Fetch User Type ------------------------
  Future<void> _fetchUserType() async {
    try {
      final user = FirebaseAuth.instance.currentUser; // تتاكد من وجود المستخدم اذا غير موجود ما رح نبحث في قاعدة البيانات
      if (user == null) {
        setState(() {
          userType = "Guest";
          isLoadingUser = false;
        });
        return;
      }

      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        setState(() {
          userType = doc.data()?['userType'] ?? "Guest";
          isLoadingUser = false;
        });
      } else { // المستخدم موجود لكن بياناته محذوفة نخليه ضيف
        setState(() {
          userType = "Guest";
          isLoadingUser = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching user type: $e");
      setState(() {
        userType = "Guest";
        isLoadingUser = false;
      });
    }
  }

  // ------------------------ Helpers ------------------------
  String _lx(Map<String, dynamic> m, String base, bool isAr) {
    final ar = m['${base}_ar'];
    final en = m['${base}_en'];
    final plain = m[base];
    return isAr ? (ar ?? en ?? plain ?? '') : (en ?? ar ?? plain ?? '');
  }

  List<String> _mapFacilities(dynamic raw, bool isAr) {
    if (raw is List) {
      return raw.map<String>((e) {
        if (e is Map<String, dynamic>) {
          final ar = e['text_ar'];
          final en = e['text_en'];
          final plain = e['text'];
          return isAr ? (ar ?? en ?? plain ?? '') : (en ?? ar ?? plain ?? '');
        }
        return e?.toString() ?? '';
      }).where((s) => s.isNotEmpty).toList();
    }
    return const [];
  }

  // ------------------------ HOME UI ------------------------
  Widget _homePage() {
    if (isLoadingFamous) {
      return const Center(child: CircularProgressIndicator());
    }


    final isArabic = context.locale.languageCode == 'ar';

    // ✅ ListView عمودي كامل لتجنب overflow
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [

        // ---------------- MOST FAMOUS WORKSHOPS ----------------
        Text(
          "Famous Places".tr(),
          style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF582C0A)),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 250, // ✅ ارتفاع ListView ليشمل الكارد بالكامل
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: mostFamous.length,
            itemBuilder: (context, index) {
              final item = mostFamous[index];

              return GestureDetector(
                onTap: () {
                  // ✅ عند الضغط، مرر الورشة كاملة إلى صفحة التفاصيل
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => UserWorkshopDetailPage(
                        workshop: item, // مرر كل البيانات كما هي من Firestore
                      ),
                    ),
                  );
                },
                child: Container(
                  width: 180,
                  height: 220,
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(16),
                            topRight: Radius.circular(16)),
                        child: Image.network(
                          // ✅ استخدم الصورة الأولى فقط من قائمة الصور
                          (item["images"] != null && item["images"].isNotEmpty)
                              ? item["images"][0]
                              : "https://via.placeholder.com/180x170", // رابط احتياطي
                          height: 170,
                          width: 180,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(6.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Text(
                                item["title"] ?? "",
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w600, color:Color(0xFF582C0A)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "Booked by ${item["count"] ?? 0} users",
                                style: const TextStyle(fontSize: 14, color: Color(0xFF895735)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 24),

        // ---------------- USER WORKSHOPS ----------------
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection("user_workshops").snapshots(), // ستريم (تدفق بيانات مباشر) يتابع الكوليكشن على المدى الطويل كل ما اضيفت ورشة تظهر في الواجهة
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return SizedBox(
                  height: 180,
                  child: const Center(child: CircularProgressIndicator()));
            }

            final docs = snapshot.data!.docs;
            if (docs.isEmpty) return const SizedBox();

            List<Map<String, dynamic>> workshops = docs.map((doc) {
              final d = doc.data() as Map<String, dynamic>;
              return {
                "id": doc.id,
                "title": d["title"],
                "city": d["city"],
                "images": d["images"] ?? [],
                "price": d["price"],
                "description": d["description"],
                "openingHours": d["openingHours"],
                "facilities": d["facilities"],
                "location": d["location"],
              };
            }).toList();


            final cities = workshops.map((w) => w["city"]).toSet();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: cities.map((city) {  // المرور على قائمة المدن
                final cityWorkshops = workshops.where((w) => w["city"] == city).toList(); // يحط الورش اللي المدينة في نفس اللستة 

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "workshops_in_city".tr(args: [city.toString().toLowerCase().tr()]),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF582C0A),
                      ),
                    ),

                    const SizedBox(height: 12),
                    SizedBox(
                      height: 220, // ارتفاع الكارد
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: cityWorkshops.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          final ws = cityWorkshops[index];
                          final img = ws["images"].isNotEmpty ? ws["images"][0] : "";

                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => UserWorkshopDetailPage(workshop: ws),
                                ),
                              );
                            },
                            child: Container(
                              width: 180,
                              margin: const EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  )
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(16),
                                      topRight: Radius.circular(16),
                                    ),
                                    child: Image.network(
                                      img.isNotEmpty ? img : "https://via.placeholder.com/180x170",
                                      height: 170,
                                      width: 180,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.all(6.0),
                                      child: Text(
                                        ws['title'] ?? "",
                                        style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF582C0A)),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }


 // -------------------------- geust denied----------------------------------

  void _blockGuest(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Color(0xFFFCF7F2), // نفس خلفية التطبيق
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          "Login Required",
          style: TextStyle(
            color: Color(0xFF895735),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          "You must log in to use this feature.",
          style: TextStyle(
            color: Color(0xFF895735),
            fontSize: 15,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "OK",
              style: TextStyle(
                color: Color(0xFF895735),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }



  // ------------------------ Build Pages ------------------------
  Widget _profilePage() => ProfilePage(famousPlaces: [], offers: []);
  Widget _plusPage() => const PlusPage();
  Widget _partnershipsPage() => const PartnershipsPage();
  Widget _reservationPage() => const ReservationPage();
  Widget _managePage() => const ManagePage();

  Widget _buildPage() {
    if (userType == "Artist") {
      switch (_selectedIndex) {
        case 0:
          return _homePage();
        case 1:
          return _partnershipsPage();
        case 2:
          return _reservationPage();
        case 3:
          return _profilePage();
        default:
          return _homePage();
      }
    } else {
      switch (_selectedIndex) {
        case 0:
          return _homePage();
        case 1:
          return _plusPage();
        case 2:
          return _managePage();
        case 3:
          return _partnershipsPage();
        case 4:
          return _profilePage();
        default:
          return _homePage();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoadingUser) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final titles = userType == "Artist"
        ? ['Home'.tr(), 'Partnerships'.tr(), 'Reservation'.tr(), 'Profile'.tr()]
        : ['Home'.tr(), 'Add Workshop'.tr(), 'Manage'.tr(), 'Partnerships'.tr(), 'Profile'.tr()];

    final navItems = userType == "Artist"
        ? [
      BottomNavigationBarItem(icon: const Icon(Icons.home), label: 'Home'.tr()),
      BottomNavigationBarItem(icon: const Icon(Icons.handshake), label: 'Partnerships'.tr()),
      BottomNavigationBarItem(icon: const Icon(Icons.list_alt), label: 'Reservation'.tr()),
      BottomNavigationBarItem(icon: const Icon(Icons.person), label: 'Profile'.tr()),
    ]
        : [
      BottomNavigationBarItem(icon: const Icon(Icons.home), label: 'Home'.tr()),
      BottomNavigationBarItem(icon: const Icon(Icons.add_circle_outline), label: 'Add Workshop'.tr()),
      BottomNavigationBarItem(icon: const Icon(Icons.dashboard_customize), label: 'Manage'.tr()),
      BottomNavigationBarItem(icon: const Icon(Icons.handshake), label: 'Partnerships'.tr()),
      BottomNavigationBarItem(icon: const Icon(Icons.person), label: 'Profile'.tr()),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFFCF7F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFECDBC9),
        elevation: 2,
        shadowColor: Colors.grey.withOpacity(0.5),
        centerTitle: true,
        title: !_isSearching
            ? Text(
          titles[_selectedIndex],
          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF582C0A)),
        )
            : TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
              hintText: "Search...", border: InputBorder.none, hintStyle: TextStyle(color: Color(0xFF582C0A))),
          style: const TextStyle(color: Color(0xFF582C0A), fontSize: 18),
          cursorColor: const Color(0xFF582C0A),
        ),
        actions: [
          !_isSearching
              ? IconButton(
            icon: const Icon(Icons.search, color: Color(0xFF582C0A)),
            onPressed: () => setState(() => _isSearching = true),
          )
              : IconButton(
            icon: const Icon(Icons.close, color: Color(0xFF582C0A)),
            onPressed: () {
              setState(() {
                _isSearching = false;
                _searchController.clear();
              });
            },
          ),
        ],
      ),
      body: _buildPage(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF895735),
        unselectedItemColor: const Color(0xFFE6C8B4),
        onTap: (index) {
          // 🔥 هنا بالضبط تحط كود منع الضيف
          if (userType == "Guest") {
            if (index != 0) {
              _blockGuest(context);
              return; // يمنعه يفتح أي صفحة غير الهوم
            }
          }

          setState(() {
            _selectedIndex = index;
            _isSearching = false;
            _searchController.clear();
          });
        },

        items: navItems,
      ),

    );
  }
}