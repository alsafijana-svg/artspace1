import 'package:flutter/material.dart'; //material design widgets.
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';

//Widget
//defines statefulwidget for the forget password screen
class ForgetPasswordPage extends StatefulWidget {
  const ForgetPasswordPage({super.key});

  @override
  //returns the _ForgetPasswordPageState, which contains all the logic and UI.
  State<ForgetPasswordPage> createState() => _ForgetPasswordPageState();
}

class _ForgetPasswordPageState extends State<ForgetPasswordPage> {
  //Tracks the state of the form for validation.
  final _formKey = GlobalKey<FormState>();
  //Controls the text input for the email field.
  final _emailController = TextEditingController();

//is an async function that triggers when the user taps the button.

//Checks if the form is valid using validate(). If not valid, it does nothing.
  Future<void> _resetPassword() async {
    if (_formKey.currentState!.validate()) {
      //Sends a password reset email using Firebase Auth.
      try {
        await FirebaseAuth.instance.sendPasswordResetEmail(
          //trim() removes any leading/trailing whitespace from the email.
          email: _emailController.text.trim(),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          //confirm the reset email was sent
          SnackBar(
            content:
                Text("A password reset link has been sent to your email.".tr()),
            backgroundColor: Colors.green,
          ),
        );
        //Closes the Forget Password page and returns to the previous screen
        Navigator.pop(context);
        //Catches any Firebase-specific error
      } on FirebaseAuthException catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            //for error message
            content: Text(e.message ?? 'something_went_wrong'.tr()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

//build the UI
  @override
  Widget build(BuildContext context) {
    // use for page layout
    return Scaffold(
      backgroundColor: const Color(0xFFFCF7F2),
      //top bar
      appBar: AppBar(
        title: Text(
          "Forgot Password".tr(),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF582C0A),
          ),
        ),
        //styling of appbar
        backgroundColor: const Color(0xFFECDBC9),
        centerTitle: true,
        elevation: 2,
        shadowColor: Colors.grey.withOpacity(0.5),
      ),

      body: Padding(
        //padding around content
        padding: const EdgeInsets.all(24),
        child: Center(
          //Centers content and allows scrolling for small screens
          child: SingleChildScrollView(
            //Wraps all widgets in a Form for validation.
            child: Form(
              key: _formKey,
              //stack widgets vertically
              child: Column(
                children: [
                  Text(
                    "Enter your email to receive a password reset link.".tr(),
                    style: TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  //vertical spaceing
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    //rounded border
                    decoration: InputDecoration(
                      labelText: "Email".tr(),
                      labelStyle: TextStyle(color: Colors.brown),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(20)),
                        borderSide: const BorderSide(color: Color(0xFF582C0A)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(20)),
                        borderSide: const BorderSide(color: Color(0xFF582C0A)),
                      ),
                    ),
                    //Validator checks:
                    //Field is not empty
                    //Email matches a simple regex pattern
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Please enter your email".tr();
                      }
                      /*
                      ^ → Start of the string
                     [\w-\.]+ → One or more characters that can be:
                     \w → any letter, digit, or underscore
                     - → a hyphen
                     @ → the literal @ symbol
                     ([\w-]+\.)+ → One or more groups of:
                     letters, digits, underscores, or hyphens followed by a dot
                     This allows for domains like example. or sub.example.
                     [\w-]{2,4} → 2 to 4 letters/digits/underscores/hyphens for the top-level domain (like com, net, org)
                     $ → End of the string
                        */
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                          .hasMatch(value)) {
                        //Returns translated error messages if invalid
                        return "Invalid email".tr();
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    //Button takes full width
                    width: double.infinity,
                    child: ElevatedButton(
                      //calls from tap
                      onPressed: _resetPassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color(0xFF895735), //0xFF895735 لون الزر
                        foregroundColor:
                            const Color(0xFFF4F0E7), //لون الخط داخل المربع
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        "Send Reset Link".tr(),
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
