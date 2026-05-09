import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class ResetPasswordPage extends StatelessWidget {
  final String oobCode;
  final String password1;
  final String password2;
  final String message;

  final ValueChanged<String> onPassword1Changed;
  final ValueChanged<String> onPassword2Changed;
  final VoidCallback onConfirm;

  const ResetPasswordPage({
    super.key,
    required this.oobCode,
    this.password1 = "",
    this.password2 = "",
    this.message = "",
    required this.onPassword1Changed,
    required this.onPassword2Changed,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Reset Password".tr(), style: TextStyle(color: Color(0xFF582C0A))),
          backgroundColor: const Color(0xFFFCF7F2),
          elevation: 2,
          centerTitle: true),
      backgroundColor: const Color(0xFFFCF7F2),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              obscureText: true,
              decoration:  InputDecoration(labelText: "New Password".tr()),
              onChanged: onPassword1Changed,
            ),
            const SizedBox(height: 20),
            TextField(
              obscureText: true,
              decoration:  InputDecoration(labelText: "Confirm Password".tr()),
              onChanged: onPassword2Changed,
            ),
            const SizedBox(height: 30),
            Center(
              child: SizedBox(
                width: 200,
                child: ElevatedButton(
                  onPressed: onConfirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC8643D),
                    foregroundColor: const Color(0xFF582C0A),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child:  Text("Confirm".tr(), style: TextStyle(fontSize: 18)),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(message),
          ],
        ),
      ),
    );
  }
}
