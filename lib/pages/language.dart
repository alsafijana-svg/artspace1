import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class LanguagePage extends StatelessWidget {
  const LanguagePage({super.key});
//build UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // layout structure
      backgroundColor: const Color(0xFFFCF7F2),
      appBar: AppBar(
        //Displays the top bar
        title: Text("Language".tr(), style: const TextStyle(
        color: Color(0xFF582C0A), fontWeight: FontWeight.bold
      ),  ),

      backgroundColor: const Color(0XFFECDBC9),
        elevation: 3,
        centerTitle: true,
        shadowColor: Colors.grey.withOpacity(0.5),
      ),
      body: Center(
        child: Column(
          //Uses a Column for vertical stacking
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(tr("Choose Language"), style: const TextStyle(fontSize: 20)),
            //vertical spacing between the text and buttons
            const SizedBox(height: 20),
            //for select English 
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF895735),// button color 
                foregroundColor: Colors.white,//text color
                shape:RoundedRectangleBorder(
                  //Rounded corners
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 10),
              ),
            //onPressed: sets the app locale to English using context.setLocale
              onPressed: () {
                context.setLocale(const Locale('en'));
              },
              child:  Text("English".tr()),
            ),
            //small spacer between English and Arabic buttons
            const SizedBox(),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF895735),
                foregroundColor: Colors.white,
                shape:RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 10),
              ),
              onPressed: () {
                context.setLocale(const Locale('ar'));
              },
              child:  Text("Arabic".tr()),
            ),
          ],
        ),
      ),
    );
  }
}
