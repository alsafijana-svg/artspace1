import 'package:artspace1/pages/language.dart';
import 'package:flutter/material.dart';
import 'package:artspace1/pages/profile_page.dart';
import 'personal_information.dart';
import 'change_password.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:artspace1/main.dart'; // Add this import for LoginPage


//Create Screen for Account Settings
//the roots of the app 
class AccountSettingsPage extends StatefulWidget {
  const AccountSettingsPage({super.key}); //helps Flutter manage the widget efficiently
  //the const optimized performance

//This connects the widget with its state class below.
  @override
  State<AccountSettingsPage> createState() => _AccountSettingsPageState();
}

class _AccountSettingsPageState extends State<AccountSettingsPage> {
  bool _notificationsEnabled = true; //stores the switch value

  @override
  Widget build(BuildContext context) {
    //the main structure of the screen
    return Scaffold(
      backgroundColor: const Color(0XFFFCF7F2),
      // App bar at the top of the screen
      appBar: AppBar(
        title: Text(
          "Account Settings".tr(),
          style:
              TextStyle(color: Color(0xFF582C0A), 
              fontWeight: FontWeight.bold),//تجعل العنوان غامق
        ),
        // AppBar styling
        backgroundColor: const Color(0XFFECDBC9),
        elevation: 3,
        centerTitle: true,
        shadowColor: Colors.grey.withOpacity(0.5),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.brown),// Left-arrow icon 
            onPressed: () {
              Navigator.pop(context); // Go back to the previous screen
            } 
            ),
      ),
      //scrollable
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 10),

          // Personal Information
          SettingCard(
            icon: Icons.person_outline, // person icon 
            title: "Personal Information".tr(),
            subtitle: "View and edit your details".tr(),// النص الصغير اللي  يظهر تحت النص الرئيسي 
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const PersonalInformationPage()),//navigates 
              );
            },
          ),

          // Change Password
          SettingCard(
            icon: Icons.lock_outline,
            title: "Change Password".tr(),
            subtitle: "Update your password".tr(),
            onTap: () {
              // الانتقال لصفحة تغيير الباسوورد
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChangePasswordPage()),
              );
            },
          ),

          // Language
          SettingCard(
            icon: Icons.language,
            title: "Language".tr(),
            subtitle: "English".tr(),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LanguagePage()),
              );
            },
          ),

          // Notifications
          NotificationCard(
            // custom widget for notifications with switch
            notificationsEnabled: _notificationsEnabled,
            onChanged: (value) {
              setState(() {
                _notificationsEnabled = value;
              });
            },
          ),

          const SizedBox(height: 40),

          // Delete Account Button
          Center(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.delete_outline, color: Colors.white),
              label: Text(
                "Delete Account".tr(),
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF895735),
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 3,
              ),
              // when pressed, show confirmation dialog
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    title: Text("Confirm Delete".tr(),
                        style: TextStyle(
                            color: Color(0xFF895735),
                            fontWeight: FontWeight.bold)),
                    content: Text(
                      "Are you sure you want to permanently delete your account?"
                          .tr(),
                      style: TextStyle(color: Colors.black87),
                    ),
                    actions: [
                    TextButton(
  onPressed: () async {
    Navigator.pop(ctx); // أغلق الـ Dialog أولاً
    try {
      // احصل على المستخدم الحالي
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.delete(); // يحذف الحساب
        // بعد الحذف، يمكنك إعادة التوجيه لصفحة تسجيل الدخول
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => LoginPage()), // Navigate to login page after account deletion
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Account deleted successfully".tr(),
        
          )),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        // إذا كان يحتاج لإعادة تسجيل الدخول
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Please log in again to delete your account".tr(),style: TextStyle(
            
          ))),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${e.message}")),
        );
      }
    }
  },
  child: Text(
    "Delete".tr(),
    style: TextStyle(color: Color(0xFF895735)),
  ),
),

                      TextButton(
                        onPressed: () {
                          Navigator.pop(ctx); // أغلق الـ Dialog
                        },
                        child: Text(
                          "Cancel".tr(),
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Stateless widget for a generic setting card
class SettingCard extends StatelessWidget {
  final IconData icon;// icon to display 
  final String title; // title of the setting
  final String subtitle; // subtitle/description
  final VoidCallback onTap; // function to execute on tap

  const SettingCard({
    //constructor
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    //create the card UI
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFDF7F4),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            blurRadius: 6, // soften the shadow
            offset: const Offset(0, 3), // move 3 down
          ),
        ],
      ),
      child: ListTile( //Currently only closes the dialog
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Icon(icon, color: const Color(0xFF6F4E37)),
        title: Text(
          title,
          style: const TextStyle(
              color: Color(0xFF582C0A), fontWeight: FontWeight.w600),
        ),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.grey)),
        trailing: const Icon(Icons.arrow_forward_ios,
            size: 16, color: Color(0xFF6F4E37)),
        onTap: onTap,
      ),
    );
  }
}

//  Stateless widget for the notifications card with switch
class NotificationCard extends StatelessWidget {
  final bool notificationsEnabled;
  final ValueChanged<bool> onChanged;

  const NotificationCard({
    super.key,
    required this.notificationsEnabled,
    required this.onChanged, // function to execute on switch toggle
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFDF7F4),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        secondary:
            const Icon(Icons.notifications_outlined, color: Color(0xFF6F4E37)),
        title: Text(
          "Enable Notifications".tr(),
          style:
              TextStyle(color: Color(0xFF582C0A), fontWeight: FontWeight.w600),
        ),
        value: notificationsEnabled,
        activeColor: const Color(0xFF6F4E37),
        onChanged: onChanged,
      ),
    );
  }
}
