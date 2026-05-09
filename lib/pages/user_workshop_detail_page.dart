import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'workshop_booking_page.dart';
import 'package:easy_localization/easy_localization.dart';

class UserWorkshopDetailPage extends StatefulWidget {
  final Map<String, dynamic> workshop;

  const UserWorkshopDetailPage({super.key, required this.workshop});

  @override
  State<UserWorkshopDetailPage> createState() => _UserWorkshopDetailPageState();
}

class _UserWorkshopDetailPageState extends State<UserWorkshopDetailPage> {
  String? userType;
  bool isFavorite = false;

  // === COMMENTS VARIABLES ===
  final TextEditingController commentController = TextEditingController();
  bool showAddComment = false;
  List<Map<String, dynamic>> comments = [];

  // ------------------ Fetch user type ------------------
  Future<void> getUserType() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      userType = "guest";
      setState(() {});
      return;
    }

    final doc =
    await FirebaseFirestore.instance.collection('users').doc(uid).get();

    userType = doc.data()?['userType'] ?? "guest";
    setState(() {});
  }

  // ------------------ Load Comments ------------------
  Future<void> loadComments() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('comments')
        .where('workshopId', isEqualTo: widget.workshop['id'])
        .get();

    comments = snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();

// ترتيب محلي حسب createdAt
    comments.sort((a, b) => a['createdAt'].compareTo(b['createdAt']));

    setState(() {});
  }

  // ------------------ Post Comment ------------------
  Future<void> postComment() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final text = commentController.text.trim();
    if (text.isEmpty) return;

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    final name = userDoc.data()?['name'] ?? "User";
    final avatar = userDoc.data()?['profileImage'] ?? "";

    await FirebaseFirestore.instance.collection('comments').add({
      'workshopId': widget.workshop['id'],
      'userId': user.uid,
      'name': name,
      'avatar': avatar,
      'text': text,
      'createdAt': Timestamp.now(),
    });

    commentController.clear();
    showAddComment = false;
    loadComments();
  }

  @override
  void initState() {
    super.initState();
    getUserType();
    loadComments();
    checkIfFavorite();
  }
  Future<void> checkIfFavorite() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .doc(widget.workshop['id']);

    final docSnap = await docRef.get();

    setState(() {
      isFavorite = docSnap.exists;
    });
  }



  @override
  Widget build(BuildContext context) {
    final workshop = widget.workshop;

    final images = workshop['images'] ?? [];
    final title = workshop['title'] ?? '';
    final city = workshop['city'] ?? '';
    final description = workshop['description'] ?? "No description provided".tr();
    final facilities = workshop['facilities'] ?? [];
    final openingHours = workshop['openingHours'] ?? "No hours provided".tr();
    final price = workshop['price'] ?? "Not provided".tr();

    final lat = workshop['location']?['lat'];
    final lng = workshop['location']?['lng'];

    const labelStyle = TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.bold,
      color: Color(0xFF895735),
    );

    const valueStyle = TextStyle(
      fontSize: 18,
      color: Color(0xFF582C0A),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(title,
            style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF582C0A))),
        backgroundColor: const Color(0xFFECDBC9),
        elevation: 2,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF582C0A)),
        actions: [
          IconButton(
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: Color(0xFF582C0A),
            ),
            onPressed: () async {
              final user = FirebaseAuth.instance.currentUser;
              if (user == null) return;

              final favRef = FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .collection('favorites')
                  .doc(widget.workshop['id']);
              if (isFavorite) {
                await favRef.delete();
              } else {
                await favRef.set({
                  'id': widget.workshop['id'],
                  'title': widget.workshop['title'] ??  '',
                  'description': widget.workshop['description'] ?? '',
                  'city': widget.workshop['city'] ?? tr("city"),
                  'images': widget.workshop['images'] ?? [],
                  'facilities': widget.workshop['facilities'] ?? [],
                  'openingHours': widget.workshop['openingHours'] ?? '',
                  'location': widget.workshop['location'] ?? {},
                  'price': widget.workshop['price'] ?? '',
                  'userId': widget.workshop['userId'] ?? '',
                  'type': 'userWorkshop', // تمييز الورشة المضافة من التطبيق
                  'isFavorite': true, // ⭐ إضافة هذا الحقل مهم جداً
                });
              }


              setState(() {
                isFavorite = !isFavorite;
              });
            },
          ),
        ],
      ),

      backgroundColor: const Color(0xFFFCF7F2),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ====================== IMAGES ======================
            if (images.isNotEmpty)
              SizedBox(
                height: 200,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: images.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (_, i) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        images[i],
                        width: 250,
                        height: 200,
                        fit: BoxFit.cover,
                      ),
                    );
                  },
                ),
              ),

            const SizedBox(height: 20),

            // ====================== DESCRIPTION ======================
            Text("Description:".tr(), style: labelStyle),
            Text(description, style: valueStyle),

            const SizedBox(height: 20),
            const Divider(),

            // ====================== OPENING HOURS ======================
            const SizedBox(height: 20),
            Text("Opening Hours:".tr(), style: labelStyle),
            Text(openingHours, style: valueStyle),

            const SizedBox(height: 20),
            const Divider(),
            // ====================== PRICE ======================
            const SizedBox(height: 20),
            Text("Price:".tr(), style: labelStyle),
            Text(price.toString(), style: valueStyle),

            const SizedBox(height: 20),
            const Divider(),

            // ====================== CITY ======================
            const SizedBox(height: 20),
            Text("City:".tr(), style: labelStyle),
            Text(city, style: valueStyle),

            const SizedBox(height: 20),
            const Divider(),

            // ====================== MAP ======================
            const SizedBox(height: 20),
            Text("Location:".tr(), style: labelStyle),

            if (lat != null && lng != null)
              SizedBox(
                height: 250,
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: LatLng(lat, lng),
                    initialZoom: 15,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                      "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                      userAgentPackageName: "com.example.artspace1",
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: LatLng(lat, lng),
                          width: 40,
                          height: 40,
                          child: const Icon(Icons.location_on,
                              color: Colors.red, size: 40),
                        ),
                      ],
                    ),
                  ],
                ),
              )
            else
              Text("No location provided".tr(), style: valueStyle),

            const SizedBox(height: 20),
            const Divider(),

            // ====================== FACILITIES ======================
            const SizedBox(height: 20),
            Text("Facilities:".tr(), style: labelStyle),

            facilities.isNotEmpty
                ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: facilities
                  .map<Widget>((f) => Text("- $f", style: valueStyle))
                  .toList(),
            )
                :  Text("No facilities provided".tr(), style: valueStyle),

            const SizedBox(height: 30),
            const Divider(),

            // ====================== COMMENTS SECTION ======================
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Comments:".tr(), style: labelStyle),
                if (userType == "Artist" || userType == "WorkshopOwner")
                  IconButton(
                    icon: const Icon(Icons.add,
                        size: 28, color: Color(0xFF895735)),
                    onPressed: () {
                      setState(() {
                        showAddComment = !showAddComment;
                      });
                    },
                  )
              ],
            ),

// ====================== ADD COMMENT CARD ======================
            if (showAddComment)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFDFC),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: commentController,
                      maxLines: 3,
                      decoration:  InputDecoration(
                        hintText: "Write your comment...".tr(),
                        border: InputBorder.none,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // CANCEL LEFT
                        TextButton(
                          onPressed: () {
                            setState(() {
                              showAddComment = false;
                              commentController.clear();
                            });
                          },
                          child:  Text(
                            "Cancel".tr(),
                            style: TextStyle(
                              color: Color(0xFF895735),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        // POST RIGHT
                        ElevatedButton(
                          onPressed: () async {
                            await postComment(); // يحفظ
                            await loadComments(); // يعرض مباشرة
                            setState(() {}); // يحدث الصفحة
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF895735),
                          ),
                          child:  Text(
                            "Post".tr(),
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            // ====================== SHOW COMMENTS ======================
            Column(
              children: comments.map((c) {
                final currentUser = FirebaseAuth.instance.currentUser;
                bool canDelete =
                    currentUser != null && currentUser.uid == c['userId'];

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFDFC),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Avatar
                      CircleAvatar(
                        radius: 20,
                        backgroundImage:
                        (c['avatar'] == "" || c['avatar'] == null)
                            ? const AssetImage("images/default_avatar.png")
                            : NetworkImage(c['avatar']) as ImageProvider,
                      ),
                      const SizedBox(width: 12),

                      // Name + Comment Text
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              c['name'] ?? "User".tr(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF895735),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              c['text'],
                              style: const TextStyle(
                                color: Color(0xFF582C0A),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // DELETE BUTTON WITH CONFIRMATION
                      if (canDelete)
                        IconButton(
                          icon: const Icon(Icons.delete,
                              color: Colors.brown, size: 22),
                          onPressed: () async {
                            // عرض رسالة تأكيد قبل الحذف
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title:  Text("Confirm Deletion".tr(),
                                  style: TextStyle(
                                    color: Color(0xFF895735),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                  ),

                                ),
                                content:  Text(
                                  "Are you sure you want to delete this comment?".tr(),
                                  style: TextStyle(
                                    color: Color(0xFF582C0A),
                                    fontSize: 16,
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(false),
                                    child:  Text("Cancel".tr(),
                                      style: TextStyle(
                                        color: Color(0xFF895735),
                                        fontWeight: FontWeight.bold,
                                      ),

                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(true),
                                    child:  Text("Delete".tr(),
                                      style: TextStyle(
                                        color: Color(0xFF895735),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              await FirebaseFirestore.instance
                                  .collection('comments')
                                  .doc(c['id'])
                                  .delete();
                              loadComments();
                            }
                          },
                        ),
                    ],
                  ),
                );
              }).toList(),
            ),

            // ====================== BOOK BUTTON ======================
            if (userType == null)
              const Center(child: CircularProgressIndicator())
            else if (userType == "Artist")
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF895735),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => WorkshopBookingPage(title: title),
                      ),
                    );
                  },
                  child:  Text(
                    "Book Now".tr(),
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}