import 'package:flutter/material.dart';
// استيراد الصفحات الجديدة
import 'artist_and_workshopowner_page.dart';
import 'artist_and_artist_page.dart';
import 'package:easy_localization/easy_localization.dart';

class PartnershipsPage extends StatelessWidget {
  const PartnershipsPage({super.key});
//build UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCF7F2),
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,// محاذاة النص في الوسط
          mainAxisAlignment: MainAxisAlignment.center,// محاذاة العناصر في الوسط عمودياً
          children: [


            //  ==الصندوق الاول===
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ArtistAndWorkshopOwnerPage()),// الانتقال للصفحة الجديدة
                );
              },// عند الضغط على الصندوق
              child: BoxWidget(text: "Contract to set up a workshop".tr()),
            ),
            const SizedBox(height: 20),

            // ==الصندوق الثاني==
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ArtistAndArtistPage()),// الانتقال للصفحة الجديدة
                );
              },// عند الضغط على الصندوق
              child:  BoxWidget(text: "Search for a artist partner".tr()),
            ),
          ],
        ),
      ),
    );
  }
}

class BoxWidget extends StatelessWidget {
  final String text;
  const BoxWidget({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90,
      width: 350,
      decoration: BoxDecoration(
        color: Color(0xFFFFFDFC), // لون الكارد الجديد (فاتح)
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            spreadRadius: 1,
            offset: const Offset(2, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF5B3A1A), // بني غامق جميل يناسب التطبيق
          ),
        ),
      ),
    );
  }
}

