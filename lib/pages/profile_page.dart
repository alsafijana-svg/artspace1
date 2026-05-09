
import 'package:artspace1/pages/partnership_requests_page.dart';
import 'package:artspace1/pages/partnership_responses_page.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../main.dart';
import 'package:artspace1/pages/favorite_place_page.dart';
import 'view_reservation_page.dart';
import 'cancel_reservation_page.dart';
import 'account_settings_page.dart';

// Supabase client
final supabase = Supabase.instance.client; // جلب صورت المستخد الحالي

class ProfilePage extends StatefulWidget {
  final List<Map<String, dynamic>> famousPlaces; // قائمه المشاهير
  final List<Map<String, dynamic>> offers; // قائمه

  const ProfilePage({
    super.key,
    required this.famousPlaces,
    required this.offers,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

Future<String?> getUserName() async { // تجيب المستخدم الحالي
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return null; //اذا مافي

  final doc = await FirebaseFirestore.instance //من كولكشن جيب اليوزر
      .collection('users')
      .doc(user.uid)
      .get();

  return doc.data()?['name']; // نرجع قيمه حقل الاسم
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) { // يعني ضيف
      return Scaffold(
        backgroundColor: const Color(0xFFFCF7F2),
        body: Center(
          child: Text(
            "Please Log in to see your profile".tr(),
            style: const TextStyle(color: Colors.brown, fontSize: 18),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFCF7F2),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 20),
              const ProfileAvatar(),
              const SizedBox(height: 10),

              FutureBuilder<String?>( // ينتظر النتيجه او يظهر دائره التحميل
                future: getUserName(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  } // لو في اسم استخدمه
                  final displayName =
                  (snapshot.data?.trim().isNotEmpty ?? false)
                      ? snapshot.data!
                      : "No name".tr(); // لو مافي اسم

                  return UserInfoWidget( // فيه الاسم والايميل
                    displayName: displayName,
                    email: user.email ?? "No email".tr(),
                  );
                },
              ),

              const SizedBox(height: 20),
              const FavoritePlacesTileWidget(),
              const SizedBox(height: 20),
              const PartnershipRequestsTileWidget(),
              const SizedBox(height: 20),
              const SentPartnershipResponsesTileWidget(),
              const SizedBox(height: 20),
              const SettingsSectionWidget(),
              const SizedBox(height: 20),
              const LogoutTileWidget(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
// ────────────────────────────────
// Profile Avatar
// ────────────────────────────────



class ProfileAvatar extends StatefulWidget {
  const ProfileAvatar({super.key});

  @override
  State<ProfileAvatar> createState() => _ProfileAvatarState();
}

class _ProfileAvatarState extends State<ProfileAvatar> {
  final supabase = Supabase.instance.client;
  File? imageFile;
  String? imageUrl; // رابط الصورة من Supabase
  final ImagePicker picker = ImagePicker();

  @override
  void initState() { // ننادي عشان نجيب الصور
    super.initState();
    _loadProfileImage();
  }

  // تحميل الصورة من Firestore
  Future<void> _loadProfileImage() async { // نجيب الاي دي للمستخدم الحالي
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();

    setState(() {
      imageUrl = doc.data()?['profileImage'];
    });
  }

  // اختيار صورة من الجهاز
  Future<void> pickImage() async {
    final XFile? picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final file = File(picked.path);

    try {
      setState(() {
        imageFile = file; // نحفظها هنا مؤقت
      });

      final uid = FirebaseAuth.instance.currentUser!.uid;
      final fileName =
          DateTime.now().millisecondsSinceEpoch.toString() + ".jpg";
      final path = "$uid/$fileName";

      // رفع الصورة
      await supabase.storage.from('profile_images').upload(path, file);

      // جلب رابط الصورة
      final publicUrl =
      supabase.storage.from('profile_images').getPublicUrl(path);

      // حفظ الرابط داخل Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update({'profileImage': publicUrl});

      if (!mounted) return;

      setState(() {
        imageUrl = publicUrl;
      });
    } catch (e) {
      print("Upload error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to upload image".tr())),
      );
    }
  }

  // قائمة الخيارات
  void showOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFFCF7F2),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_library,
                      color: Color(0xFF895735)),
                  title:  Text(
                    "Choose from Gallery".tr(),
                    style: TextStyle(
                        color: Color(0xFF582C0A),
                        fontWeight: FontWeight.w600),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    pickImage();
                  },
                ),
                if (imageUrl != null)
                  ListTile(
                    leading: const Icon(Icons.delete_outline,
                        color: Color(0xFF895735)),
                    title:  Text(
                      "Remove Photo".tr(),
                      style: TextStyle(
                          color: Color(0xFF582C0A),
                          fontWeight: FontWeight.w600),
                    ),
                    onTap: ()  async{
           final userId = FirebaseAuth.instance.currentUser!.uid;

        // تحديث Firestore ومسح رابط الصورة
         await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .update({'profileImage': ''});

        // تحديث الواجهة
        setState(() {
        imageUrl = null;
        });

        Navigator.pop(context);
        },

                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack( // عشان نحط الصوره وفوقها زر الزايد
      alignment: Alignment.bottomRight,
      children: [
        CircleAvatar( // الدائره
          radius: 45,
          backgroundColor: const Color(0xFFECDBC9),
          // اختيار الصوره
          backgroundImage: imageFile != null
              ? FileImage(imageFile!) as ImageProvider
              : (imageUrl != null && imageUrl!.isNotEmpty)
              ? NetworkImage(imageUrl!)
              : null,


          // ايقونه افتراضيه
          child: (imageUrl == null || imageUrl!.isEmpty) && imageFile == null
          //child: (imageUrl == null && imageFile == null)
              ? const Icon(Icons.person,
              size: 50, color: Color(0xFFE6C8B4))
              : null,
        ),
        GestureDetector(
          onTap: showOptions,
          child: Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF895735),
            ),
            padding: const EdgeInsets.all(6),
            child: const Icon(Icons.add, color: Colors.white, size: 20),
          ),
        ),
      ],
    );
  }
}


class UserInfoWidget extends StatelessWidget {
  final String displayName;
  final String email;

  const UserInfoWidget({
    super.key,
    required this.displayName,
    required this.email,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(displayName,
            style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF582C0A))),
        Text(email, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }
}

class FavoritePlacesTileWidget extends StatelessWidget {
  const FavoritePlacesTileWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return MenuTileWidget(
      icon: Icons.favorite_outline,
      title: "Favorite Places".tr(),
      onTap: () {
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const FavoritePlacePage()));
      },
    );
  }
}


class PartnershipRequestsTileWidget extends StatelessWidget {
  const PartnershipRequestsTileWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return MenuTileWidget(
      icon: Icons.mail_outline,
      title: "Partnership Requests".tr(),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => const PartnershipRequestsPage()),
      ),
    );
  }
}



class SentPartnershipResponsesTileWidget
    extends StatelessWidget {
  const SentPartnershipResponsesTileWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return MenuTileWidget(
      icon: Icons.reply_all_outlined,
      title: "Partnership Responses".tr(),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => const PartnershipResponsesPage()),
      ),
    );
  }
}

class SettingsSectionWidget extends StatelessWidget {
  const SettingsSectionWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SectionTitle(title: "Settings".tr()),
        MenuTileWidget(
          icon: Icons.person_outline,
          title: "Account settings".tr(),
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const AccountSettingsPage())),
        ),
      ],
    );
  }
}

class LogoutTileWidget extends StatelessWidget {
  const LogoutTileWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDFC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading:
        const Icon(Icons.logout, color: Color(0xFF895735)),
        title: Text("Logout".tr(),
            style: const TextStyle(color: Color(0xFF895735))),
        onTap: () async {
          await FirebaseAuth.instance.signOut();
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const LoginPage()),
                (route) => false,
          );
        },
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String title;
  const SectionTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding:
      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(title,
          style: const TextStyle(
              fontSize: 18,
              color: Color(0xFF582C0A),
              fontWeight: FontWeight.bold)),
    );
  }
}

class MenuTileWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const MenuTileWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin:
      const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDFC),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withOpacity(0.15),
              blurRadius: 6,
              offset: const Offset(0, 3))
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 4),
        leading: Icon(icon, color: const Color(0xFF895735)),
        title: Text(title,
            style: const TextStyle(
                color: Color(0xFF582C0A),
                fontWeight: FontWeight.w700)),
        trailing: const Icon(Icons.arrow_forward_ios,
            size: 16, color: Color(0xFF895735)),
        onTap: onTap,
      ),
    );
  }
}
