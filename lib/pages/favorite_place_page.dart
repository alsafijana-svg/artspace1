import 'package:cloud_firestore/cloud_firestore.dart';// read and write data to Firestore
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart'; //UI widgets
import 'user_workshop_detail_page.dart';

//Uses a StatefulWidget because the list of favorites will update
class FavoritePlacePage extends StatefulWidget {
  const FavoritePlacePage({super.key});


  @override
  State<FavoritePlacePage> createState() => _FavoritePlacePageState();

}
class _FavoritePlacePageState extends State<FavoritePlacePage> {
  // List to hold favorite places
  List<Map<String, dynamic>> favoritePlaces = [];

  @override
  // Initialize state and load favorites from Firestore
  void initState() {
    super.initState();
    _loadFirebaseFavorites();

  }
  // Load favorite places from Firestore
  Future<void> _loadFirebaseFavorites() async {
    // Get current user
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return; // If no user, exit
  // Query Firestore for favorite places
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .where('isFavorite', isEqualTo: true)
        .get();
    setState(() {
      // Update favoritePlaces list with data from Firestore
      favoritePlaces = snapshot.docs.map((doc) => doc.data()).toList();

    });

    // طباعة المستندات للتأكد من الحقول

    for (var doc in snapshot.docs) {
      print(doc.data());

    }
  
    setState(() {//Update the UI by calling setState
      //Converts Firestore documents into a List of Maps
      favoritePlaces = snapshot.docs.map((doc) => doc.data()).toList();

    });

  }


  @override

  Widget build(BuildContext context) {
// Check if the current locale is Arabic
    final isAr = context.locale.languageCode == 'ar';
    // Build the UI
    return Scaffold(
      backgroundColor: const Color(0xFFFCF7F2),
      appBar: AppBar(
        title: Text(
          "Favorite Places".tr(),
          style: const TextStyle(
              color: Color(0xFF582C0A), fontWeight: FontWeight.bold),

        ),
        backgroundColor: const Color(0xFFECDBC9),
        centerTitle: true,
        elevation: 2,
        shadowColor: Colors.grey.withOpacity(0.5),

      ),
// If no favorite places, show message; else show list
      body: favoritePlaces.isEmpty

          ? Center(child: Text("No favorite places yet.".tr(), style: TextStyle(
        color: Color(0xFF582C0A),
        fontWeight: FontWeight.bold,
      ),),)
      :ListView.builder( // Build a list of favorite places
        itemCount: favoritePlaces.length,// Number of items
        itemBuilder: (context, index) {// Build each item
          final place = favoritePlaces[index];// Get place data
          return GestureDetector(
            onTap: () async {
           await Navigator.push(
          context,
          MaterialPageRoute(
           builder: (_) => UserWorkshopDetailPage(
            workshop: place), // تمرير بيانات الورشة كاملة
              ),
           );
           _loadFirebaseFavorites();// إعادة تحميل المفضلات بعد العودة
            },
            child: Container(
              margin: EdgeInsets.fromLTRB(15, index == 0 ? 20 : 10, 15, 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFDFC),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),

              child: Row(
                children: [
                  // الصورة — من النت وليس assets
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                    ),
                    child: Image.network(
                      //image handling with placeholder
                      (place['images'] != null &&
                          place['images'].isNotEmpty)
                          //If not the show a placeholder image
                          ? place['images'][0]
                          : "https://via.placeholder.com/100",
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                  ),

                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Displays title and description
                          Text(
                            place['title'] ?? '',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Color(0xFF582C0A),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            place['description'] ?? '',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF582C0A),
                            ),
                            maxLines: 2,
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
    );
  }
}

