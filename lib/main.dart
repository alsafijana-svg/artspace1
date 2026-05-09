import 'package:flutter/material.dart'; // import flutter's core UI
import 'package:firebase_core/firebase_core.dart'; // allow initializaing firebase when the app start
import 'package:firebase_auth/firebase_auth.dart'; // provides firebase authintication functionality for sign up, sgin in , current user etc
import 'package:cloud_firestore/cloud_firestore.dart'; // read and write data from cloud firebase (NoSQL database)
import 'package:easy_localization/easy_localization.dart'; // allow lcoalization /transliation support with .tr() and multiple language 
import 'package:supabase_flutter/supabase_flutter.dart'; //alternative backend DB and auth 

// استيراد الصفحات
import 'pages/reset_password_page.dart';
import 'pages/forget_password_page.dart';
import 'pages/create_account_page.dart';
import 'pages/home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); //flutter initiazed before doing start setup 
  await Firebase.initializeApp();  // you can use services like auth firestore etc
  await EasyLocalization.ensureInitialized(); //ensures is ready before the app runs 
// initialize supabase with a URL and anonymous key for the storage images and will call the images in firebase 
  await Supabase.initialize(
    url: 'https://davzycbloedfcemymacp.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRhdnp5Y2Jsb2VkZmNlbXltYWNwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjM1NzA0OTUsImV4cCI6MjA3OTE0NjQ5NX0.zuIzEc8pxyKwrWe-UsvKFVwiEgqDZ3ThJ7kh9fQe4r8',
  );

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('ar')],
      path: 'assets/translations',//where translation files are stored 
      fallbackLocale: const Locale('en'),
      saveLocale: true,
      startLocale: const Locale('en'),
      child: const MyApp(),
    ),
  );
}
//the roos of the app 
class MyApp extends StatelessWidget {
  const MyApp({super.key});
// defines a stateless widget MyApp 

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,// hides DEBUS banner while development 
      //To enable translation support
      locale: context.locale, 
      supportedLocales: context.supportedLocales,
      localizationsDelegates: context.localizationDelegates,
      //Defines the global theme(background color ,text style ,etc.)
      theme: ThemeData(
        popupMenuTheme: const PopupMenuThemeData(
          color: Color(0xFF9C573B),
          textStyle: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      //first screen of the app 
      home: const LoginPage(),
    );
  }
}
// because we need to manage user input and state (passwoard visibility , form validity)
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>(); //to do validation 
  final emailController = TextEditingController(); //manage the text fields for email and password 
  final passwordController = TextEditingController();
  final ValueNotifier<bool> obscurePassword = ValueNotifier(true); // track whether password is hidden or visible // eyes emoji 

  @override
  Widget build(BuildContext context) {
    return Scaffold( //basic layout 
      backgroundColor: const Color(0xFFFCF7F2),
      body: Padding(
        padding: const EdgeInsets.all(24),
        //centers the content 
        child: Center(
          // if screen is small 
          child: SingleChildScrollView(
            child: Form(
              // to manage validation 
              key: _formKey,
              child: Column(
                children: [
                  //Loads an image asset at width 150 px
                  Image.asset(
                    "images/WhatsApp Image 2025-07-14 at 22.17.24_88ab71ab.jpg",
                    width: 150,
                  ),
                  const SizedBox(height: 20),// spacing 
                  Text(
                    "Log in".tr(),// translated 
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF582C0A),
                    ),
                  ),
                  const SizedBox(height: 20),// spacing
                  //inserts custom EmailField and PasswordField widgets for user input
                  EmailField(controller: emailController),
                  const SizedBox(height: 16),
                  PasswordField(
                    controller: passwordController,
                    obscurePassword: obscurePassword,
                  ),
                  const SizedBox(height: 20),
                  //Adds the login button, passing the form key and controllers.
                  LoginButton(
                    formKey: _formKey,
                    emailController: emailController,
                    passwordController: passwordController,
                  ),
                  const SizedBox(height: 16),
                  const ForgetPasswordLink(),
                  const SizedBox(height: 8),
                  const Divider(height: 20),//horizontal divider line with a total vertical space
                  const SizedBox(height: 16),//empty vertical space of 8 pixels
                  const CreateAccountLink(),
                  Text("or".tr(),
                      style: const TextStyle(color: Color(0XFFC8643D))),
                  const SizedBox(height: 8),
                  const GuestLoginLink(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}


//email field widget 

class EmailField extends StatelessWidget {// for email input 
  final TextEditingController controller;
  const EmailField({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      //styling
      cursorColor: Color(0xFF582C0A),
      controller: controller,
      decoration: InputDecoration(
        labelText: "Email".tr(),
        labelStyle: const TextStyle(color: Colors.brown),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
          borderSide: BorderSide(color: Color(0xFF582C0A)),
        ),
      ),
      //Keyboard type set to email
      keyboardType: TextInputType.emailAddress, //لايقبل رقم او حروف خاصة
      //تحقق
      validator: (value) {
        //checks field isn't empty 
        if (value == null || value.isEmpty) {
          return "Please enter email".tr();
        }
        //checks pattern matches a simple email regex. If invalid, returns translated error messages.
        final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
        if (!emailRegex.hasMatch(value)) {
          return "Please enter a valid email".tr();
        }
        return null;
      },
    );
  }
}

//PasswordField widget

class PasswordField extends StatelessWidget {
  final TextEditingController controller;//It lets you read, change, or clear the tex
  final ValueNotifier<bool> obscurePassword;
//When its value changes, the widget updates automatically
//
  const PasswordField({
    super.key,
    required this.controller,
    required this.obscurePassword,
  });

  @override
  Widget build(BuildContext context) {
    //to rebuild when obscurePassword.value changes 
    return ValueListenableBuilder(
      valueListenable: obscurePassword,
      builder: (context, value, child) {
        return TextFormField(
          cursorColor: Color(0xFF582C0A),
          controller: controller,
          //when true, password is masked; when false, visible.
          obscureText: value,
        //  Decoration includes a suffix icon (eye / eye-off) to toggle visibility. On pressing it flips
          decoration: InputDecoration(
            labelText: "Password".tr(),
            labelStyle: const TextStyle(color: Colors.brown),
            border: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(20)),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(20)),
              borderSide: BorderSide(color: Color(0xFF582C0A)),
            ),
            suffixIcon: IconButton(
              icon: Icon(value ? Icons.visibility_off : Icons.visibility),
              onPressed: () {
                obscurePassword.value = !value;
              },
            ),
          ),
          //Validator ensures the field is not empty
          validator: (value) {
            if (value == null || value.isEmpty) {
              return "Please enter password".tr();
            }
            return null;
          },
        );
      },
    );
  }
}
//Login button 

class LoginButton extends StatelessWidget {
  //Receives form key and controllers so it can validate and read user input.
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;

//Constructor
  const LoginButton({
    super.key,
    required this.formKey,
    required this.emailController,
    required this.passwordController,
  });
//Button styled with custom background, text color, padding
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF895735),
          foregroundColor: const Color(0xFFF4F0E7),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      //  If invalid, do nothing.
        onPressed: () async {
          if (!formKey.currentState!.validate()) return;
             //Retrieves the email and password values
          final email = emailController.text.trim(); //trim to remove any space 
          final password = passwordController.text.trim();
          // Attempts to sign in using Firebase Auth
          try {
            UserCredential userCredential = await FirebaseAuth.instance
                .signInWithEmailAndPassword(email: email, password: password);
              //extracts the user UID
            String uid = userCredential.user!.uid;
                   //If no document found, throws an exception.
                   //call data from firebase 
            final userDoc = await FirebaseFirestore.instance
                .collection('users')
                .doc(uid)
                .get();

            if (!userDoc.exists) {
              throw Exception("User data not found in Firestore");
            }
               //If everything is fine, navigates to HomePage and replaces the login screen (user cannot go back to login).
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => HomePage(),
              ),
            );
            //If a Firebase auth error occurs catch it, get its message
          } on FirebaseAuthException catch (e) {
            String message = e.message ?? 'Login failed'.tr();

            //   error message (translated), styled (background color, floating behavior, margin, rounded corners).
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: const Color(0xFFB8402A),
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                content: Text(
                  message.tr(),
                  style: const TextStyle(color: Colors.white),
                ),
                duration: const Duration(seconds: 2),
              ),
            );
          //  If any other error occurs
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: const Color(0xFFB8402A),
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                content: Text(
                  'Something went wrong: $e',
                  style: const TextStyle(color: Colors.white),
                ),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        },
        child: Text("Log in".tr(), style: const TextStyle(fontSize: 20)),
      ),
    );
  }
}

// Links 
class ForgetPasswordLink extends StatelessWidget {
  const ForgetPasswordLink({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => const ForgetPasswordPage()));
      },
      child: Text("Forget Password ?".tr(),
          style: const TextStyle(color: Color(0xFF582C0A))),
    );
  }
}

class CreateAccountLink extends StatelessWidget {
  const CreateAccountLink({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => const CreateAccountPage()));
      },
      child: Text("Create an account".tr(),
          style: const TextStyle(color: Color(0xFF582C0A))),
    );
  }
}

class GuestLoginLink extends StatelessWidget {
  const GuestLoginLink({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HomePage(),
          ),
        );
      },
      child: Text(
        "Login as a guest".tr(),
        style: const TextStyle(color: Color(0xFF582C0A)),
      ),
    );
  }
}