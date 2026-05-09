import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart'; // for translations
import 'partnership_form_page.dart';

//Helper function to return the correct translation of a field
String _lx(Map<String, dynamic> m, String base, bool isAr) {
  final ar = m['${base}_ar']; //بيس حقل اساسي
  final en = m['${base}_en'];
  final plain = m[base];
  return isAr ? (ar ?? en ?? plain ?? '') : (en ?? ar ?? plain ?? '');
}
//a list of artists and allow interactions
class ArtistAndArtistPage extends StatefulWidget {
  const ArtistAndArtistPage({super.key});

  @override
  State<ArtistAndArtistPage> createState() => _ArtistAndArtistPageState();
}

class _ArtistAndArtistPageState extends State<ArtistAndArtistPage> {
  List<Map<String, dynamic>> artists = []; //جلب اسماء الارتست
  bool isLoading = true; //shows a spinner while fetching data

  @override
  void initState() {
    super.initState();
    fetchArtists(); // نجيب قائمه الفنانين من الفاير
  }

  // جلب الفنانين من Firestore مرة واحدة
  //Gets the current user to prevent self-partnership
  Future<void> fetchArtists() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser; // اجيب المستخدم الحالي عشان استثنيه من الصفحه زي ماقالت الاء

      final snapshot = await FirebaseFirestore.instance
          .collection('users') // اروح لهذا الكولكشن واعمل فلتره واخد بيناتات الارتست
          .where('userType', isEqualTo: 'Artist')
          .get();

      // الفنان مايقدر يعمل شراكه مع نفسه
      artists = snapshot.docs
          .map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      })
          .where((artist) => artist['id'] != currentUser?.uid)
          .toList();

      setState(() => isLoading = false);

      //معالجه الاخطاء
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching users: $e'.tr())),
      );
    }
  }
// Build the UI
  @override
  Widget build(BuildContext context) {
    final bool isArabic = context.locale.languageCode == 'ar';

    return Scaffold(
      backgroundColor: const Color(0xFFFCF7F2),
      appBar: AppBar(
        title: Text(
          'Artist Partner'.tr(),
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
          ? const Center(child: CircularProgressIndicator())
          : artists.isEmpty // مافي فنانين "No Artists" if list is empty
          ? Center(
        child: Text(
          'No Artists'.tr(),
          style: const TextStyle(fontSize: 16, color: Colors.grey),
        ),
      )
          : ListView.builder( // في فنانين موجودين
        padding: const EdgeInsets.all(12),
        itemCount: artists.length, //عددهم
        itemBuilder: (context, index) { // كل فنان له كارد
          final artist = artists[index];

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
                  //profile image or default icon if no image
                  //ClipRRect for rounded image corners
                  //---- الصورة ----
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: artist['profileImage'] != null &&
                        artist['profileImage'].toString().isNotEmpty
                        ? Image.network(
                      artist['profileImage'],
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    )
                        : const Icon(Icons.person,
                        size: 80, color: Colors.grey),
                  ),

                  const SizedBox(width: 15),

                  //---- البيانات ----
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // الاسم مترجم
                        Text(
                          _lx(artist, "name", isArabic),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF582C0A),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),

                        // المدينة مترجمة
                        Text(
                          _lx(artist, "city", isArabic),
                          style: const TextStyle(color: Colors.grey),
                          overflow: TextOverflow.ellipsis,
                        ),

                        const SizedBox(height: 5),
                        // تقيم الفنان
                        Row(
                          children: [
                            const Icon(Icons.star,
                                color: Colors.amber, size: 18),
                            Text(
                              '${'rating'.tr()}: ${artist['rating'] ?? 0.0}', // يطلع الريتنق من بيانات الفنان اذا مافي 0و0
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
                                  receiverId: artist['id'], // الرقم المعرف حقه من الفاير
                                  receiverName: // اسمه
                                  _lx(artist, "name", isArabic),
                                ),
                              ),
                            );
                          },//خصائص الزر 
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
