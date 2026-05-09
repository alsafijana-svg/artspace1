import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';
//that represents the screen for changing the user's password
class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}//createState(): Initializes the state of the widget by returning an instance of _ChangePasswordPageState

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  // نموذج للتحقق من صحة الإدخالات
  //final 
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
//Controllers for password fields
  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
// Firebase Auth instance
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void dispose() {//Cleans up the controllers when the widget
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
//handles the password change logic
  Future<void> _changePassword() async {
    //Variables that store
    final user = _auth.currentUser;
    final oldPass = _oldPasswordController.text.trim();
    final newPass = _newPasswordController.text.trim();
    final confirmPass = _confirmPasswordController.text.trim();
//If validation fails, the function returns early.
    if (!_formKey.currentState!.validate()) return;

    if (newPass != confirmPass) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("New passwords do not match".tr())),
      );//If validation fails, the function returns early.
      return;
    }

    try {
      
      // إعادة التوثيق بالباس القديم
      final cred = EmailAuthProvider.credential(email: user!.email!, password: oldPass);
      await user.reauthenticateWithCredential(cred);

      // تغيير الباسورد
      await user.updatePassword(newPass);

      ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Password updated successfully".tr())),
      );

      // مسح الحقول
      _oldPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
    } on FirebaseAuthException catch (e) {
      String message = "Failed to update password".tr();
      if (e.code == 'wrong-password'.tr()) message = "Old password is incorrect".tr();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e".tr())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(

        title: Text("Change Password".tr(),style: TextStyle(color: Color(0xFF582C0A), fontWeight: FontWeight.bold),),
        backgroundColor: const Color(0xFFECDBC9),
        centerTitle: true,
        elevation: 2,
        shadowColor: Colors.grey.withOpacity(0.5),
      ),
      backgroundColor: const Color(0xFFFCF7F2),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // باسورد قديم
              TextFormField(
                controller: _oldPasswordController,
                obscureText: _obscureOld,
                decoration: InputDecoration(
                  labelText: "Old Password".tr(),
                  labelStyle: const TextStyle(color: Colors.brown),
                  border: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(20))),
                  focusedBorder: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                      borderSide: BorderSide(color: Color(0xFF582C0A))),

                  suffixIcon: IconButton(
                    icon: Icon(_obscureOld ? Icons.visibility_off : Icons.visibility),
                    onPressed: () {
                      setState(() => _obscureOld = !_obscureOld);
                    },
                  ),

                ),
                validator: (v) => v == null || v.isEmpty ? "Enter old password".tr() : null,
              ),
              const SizedBox(height: 16),

              // باسورد جديد
              TextFormField(
                controller: _newPasswordController,
                obscureText: _obscureNew,
                decoration: InputDecoration(
                  labelText: "New Password".tr(),
                  // خصائص المستطيل
                  labelStyle: const TextStyle(color: Colors.brown),
                  border: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(20))),
                  focusedBorder: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                      borderSide: BorderSide(color: Color(0xFF582C0A))),

                  suffixIcon: IconButton(
                    icon: Icon(_obscureNew ? Icons.visibility_off : Icons.visibility),
                    onPressed: () {
                      setState(() => _obscureNew = !_obscureNew);
                    },
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return "Enter new password".tr();
                  if (v.length < 6) return "Password must be at least 6 characters".tr();
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // تأكيد باسورد جديد
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirm,
                decoration: InputDecoration(
                  labelText: "Confirm New Password".tr(),
                  // خصائص المستطيل
                  labelStyle: const TextStyle(color: Colors.brown),
                  border: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(20))),
                  focusedBorder: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                      borderSide: BorderSide(color: Color(0xFF582C0A))),

                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility),
                    onPressed: () {
                      setState(() => _obscureConfirm = !_obscureConfirm);
                    },
                  ),
                ),
                validator: (v) => v == null || v.isEmpty ? "Confirm new password".tr(): null,
              ),
              const SizedBox(height: 24),

              SizedBox(
                height: 60,
                child: ElevatedButton(
                  onPressed: _changePassword,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF895735)),
                  child: Text(
                    "Change Password".tr(),
                    style: TextStyle(fontSize: 18, color: Color(0xFFF4F0E7)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}