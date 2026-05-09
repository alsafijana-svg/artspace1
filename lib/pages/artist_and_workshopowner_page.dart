import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'partnership_form_page.dart';//استيراد صفحة نموذج الشراكة

// ---------- دالة الترجمة للحقول ----------
String _lx(Map<String, dynamic> m, String base, bool isAr) {
  final ar = m['${base}_ar']; // يقرا الاسم نسخه بالعربي
  final en = m['${base}_en']; // يقرا الاسم نسخه بالانقلش
  final plain = m[base]; // نستخدمه اذا مافي ترجمه
  // تير نري اوبريتر
  return isAr ? (ar ?? en ?? plain ?? '') : (en ?? ar ?? plain ?? '');
}
//a list of workshop owners that the user can partner with
class ArtistAndWorkshopOwnerPage extends StatefulWidget {
  const ArtistAndWorkshopOwnerPage({super.key});

  @override
  State<ArtistAndWorkshopOwnerPage> createState() =>
      _ArtistAndWorkshopOwnerPageState();
}

class _ArtistAndWorkshopOwnerPageState
    extends State<ArtistAndWorkshopOwnerPage> {
  //  String=name,ccity
  //dynamic= double, int,string
  List<Map<String, dynamic>> owners = []; //list to store qorkshop owners
  bool isLoading = true; //the page is still loading the data or not.

  @override
  void initState() {
    super.initState(); // استدعاء مالكين الورشات
    fetchOwners();
  }

  //-- جلب المستخدمين من Firestore --
  //The list of workshop owners from Firestore
  Future<void> fetchOwners() async {
    try {
      // نستثنيه من القائمه
      final currentUser = FirebaseAuth.instance.currentUser;
      final snapshot = await FirebaseFirestore.instance
          // فلترتهت من الكولكشن اخد بس مالكين الورشه
          .collection('users')
          .where('userType', isEqualTo: 'WorkshopOwner')//Firestore query filters users by type
          .get();

      owners = snapshot.docs
          .map((doc) {
            final data = doc.data();
            data['id'] = doc.id; // حقل جديد اسمه id
            return data;
          })
          // اذا الحقل  نستثنيه من القائمه id== uid
          .where((owner) => owner['id'] != currentUser?.uid)
          .toList();

      setState(() => isLoading = false); // update loading state
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching users: $e'.tr())),//display error message
      );
    }
  }
//Building the UI of the page
  @override
  Widget build(BuildContext context) {
    final bool isArabic = context.locale.languageCode == 'ar';//// Check if the current language is Arabic

    return Scaffold(
      backgroundColor: const Color(0xFFFCF7F2),
      appBar: AppBar(
        title: Text(
          'Workshop Partner'.tr(),
          style: const TextStyle(
            color: Color(0xFF582C0A),
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFFECDBC9),
        elevation: 2,
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())// Show a loading spinner if data is being fetched
          : owners.isEmpty
              ? Center(
                  child: Text(
                    'No Workshop Owners'.tr(),
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: owners.length, // // The number of workshop owners to display
                  itemBuilder: (context, index) {
                    final owner = owners[index];

                    return Card(
                      color: const Color(0xFFFFFDFC),
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 3,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Profile Image
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child:
                                  owner['profileImage'] != null && owner['profileImage'] .toString().isNotEmpty
                                      ? Image.network(
                                          owner['profileImage'],
                                          width: 80,
                                          height: 80,
                                          fit: BoxFit.cover,
                                        )
                                      : const Icon(Icons.person,
                                          size: 80, color: Colors.grey),
                            ),

                            const SizedBox(width: 15),

                         //Data 
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // الاسم مترجم
                                  Text(
                                    _lx(owner, "name", isArabic),
                                    // بيانات الاونر
                                    // اسمه
                                    // يحدد يرجع الاسم عربي او انقلش
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF582C0A),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),

                                  // المدينة مترجمة
                                  Text(
                                    _lx(owner, "city", isArabic),
                                    // بيانات الاونر
                                    // اسمه
                                    // يحدد يرجعه عربي او انقلش
                                    style: const TextStyle(color: Colors.grey),// Default icon if no image
                                    overflow: TextOverflow.ellipsis,
                                  ),

                                  const SizedBox(height: 5),

                                  // التقييم
                                  Row(
                                    children: [
                                      const Icon(Icons.star,
                                          color: Colors.amber, size: 18),
                                      Text(
                                        '${'rating'.tr()}: ${owner['rating'] ?? 0.0}', //طلع الريتنق من بيانات الفنان اذا مافي 0و0
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 8),

                                  // زر بدء الشراكة
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => PartnershipFormPage(
                                            receiverId: owner['id'],
                                            receiverName:
                                                // نرسل اسموو باللغه الحااااااااااااليه
                                                _lx(owner, "name", isArabic),
                                          ),
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF895735),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      textStyle: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    child: Text(
                                      'Start a partnership'.tr(),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

