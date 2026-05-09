import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; //for input formatters
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../main.dart'; //imports LoginPage or other shared widgets.

//user’s details
class PigeonUserDetails {
  final String userId;
  final String name;
  final String surname;
  final String email;
  final String phone;
  final String? city; //can be null
  final String? userType; //can be null 
  final String profileImage;

  PigeonUserDetails({
    //Constructor initializes fields
    required this.userId,
    required this.name,
    required this.surname,
    required this.email,
    required this.phone,
    this.city,
    this.userType,
    required this.profileImage,
  });
  //convert Firestore map into a PigeonUserDetails object
  factory PigeonUserDetails.fromMap(Map<String, dynamic> map, {String? fallbackId}) {
    return PigeonUserDetails(
      userId: (map['userId'] ?? fallbackId ?? '') as String,
      name: (map['name'] ?? '') as String,
      surname: (map['surname'] ?? '') as String,
      email: (map['email'] ?? '') as String,
      phone: (map['phone'] ?? '') as String,
      city: map['city'] as String?,
      userType: map['userType'] as String?,
      profileImage: (map['profileImage'] ?? '') as String,
    );
  }
}
// Create account page 
//for screen page 
class CreateAccountPage extends StatefulWidget {
  const CreateAccountPage({super.key});

  @override
  State<CreateAccountPage> createState() => _CreateAccountPageState();
}

class _CreateAccountPageState extends State<CreateAccountPage> {
  final _formKey = GlobalKey<FormState>();
//Controllers for each input field to read or modify user input
  final nameController = TextEditingController();
  final surnameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();

  String? selectedCity; //holds the chosen city
  String? userType; // Artist or WorkshopOwner
  bool obscurePassword = true; //controls password visibility.

//the dropdown menu
  final List<String> cities = [
    "Riyadh".tr(), "Jeddah".tr(), "Makkah".tr(), "Madinah".tr(),
    "Dammam".tr(), "Taif".tr(), "Abha".tr(), "Tabuk".tr(), "Najran".tr(), "Hail".tr()
  ];
      //Function create account 
      //read email , password , phone 
  Future<void> createAccount() async {
    final email = emailController.text.trim();
    final phone = phoneController.text.trim();
    final password = passwordController.text.trim();
     //Ensures password is at least 6 characters
    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        //if too short show in snackBar 
        SnackBar(content: Text("Password must be at least 6 characters.".tr())),
      );
      return;
    }
  //Creates a Firebase user with email/password
  //UID of new user 
    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      final uid = userCredential.user!.uid;
      //Creates a Firestore reference for the new user document.
      final userDoc = FirebaseFirestore.instance.collection("users").doc(uid);
         //user data map to store in Firestore
      final userData = {
        "userId": uid,
        "name": nameController.text.trim(),
        "surname": surnameController.text.trim(),
        "email": email,
        "phone": phone,
        "city": selectedCity,
        "userType": userType,
        "profileImage": "", //empty by default 
        "createdAt": FieldValue.serverTimestamp(), //uses server timestamp
      };
       //save user data in firestore 
      await userDoc.set(userData);
        //a success dialog with a check icon
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          //Automatically closes after 2 seconds and navigates to LoginPage
          Future.delayed(const Duration(seconds: 2), () {
            Navigator.of(context).pop();
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const LoginPage()),
            );
          });
               //Dialog UI: check icon + success message
          return AlertDialog(
            backgroundColor: const Color(0xFFFCF7F2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children:  [
                Icon(
                  Icons.check_circle,
                  color: Color(0xFF895735),
                  size: 80,
                ),
                SizedBox(height: 15),
                Text(
                  "Account Created Successfully".tr(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF582C0A),
                  ),
                ),
              ],
            ),
          );
        },
      );

      Future.delayed(const Duration(seconds: 1), () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );
      });
      //error handling 
      //duplicate email, weak password
    } on FirebaseAuthException catch (e) {
      String message = "Something went wrong".tr();
      if (e.code == 'email-already-in-use') message = "Email already in use".tr();
      if (e.code == 'weak-password') message = "Password is weak".tr();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        //show a generic SnackBar with the error.
        SnackBar(content: Text('unexpected_error'.tr(args: [e.toString()]))),
      );
    }
  }
//Frees memory when the widget is removed.
  @override
  void dispose() {
    nameController.dispose();
    surnameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    super.dispose();
  }
 //build UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCF7F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFECDBC9),
        centerTitle: true,
        elevation: 2,
        shadowColor: Colors.grey.withOpacity(0.5),

        title: Text(
          "Create Account".tr(),
          style: const TextStyle(color: Color(0xFF582C0A), fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              //Custom stateless widgets for input validation
              const SizedBox(height: 20),
              NameField(controller: nameController),
              const SizedBox(height: 16),
              SurnameField(controller: surnameController),
              const SizedBox(height: 16),
              EmailInput(controller: emailController),
              const SizedBox(height: 16),
              PhoneInput(controller: phoneController),
              const SizedBox(height: 16),
              PasswordInput(
                controller: passwordController,
                obscurePassword: obscurePassword,
                toggleObscure: () {
                  setState(() {
                    obscurePassword = !obscurePassword;
                  });
                },
              ),
              const SizedBox(height: 16),
              //to select city 
              CityDropdown(
                cities: cities,
                //Validator ensures a city is chosen
                selectedCity: selectedCity,
                onChanged: (val) => setState(() => selectedCity = val),
              ),
              const SizedBox(height: 16),
              //Radio buttons to choose between "Artist" or "WorkshopOwner"
              RoleSelector(
                userType: userType,
                //Validator ensures a role is chosen
                onChanged: (val) => setState(() => userType = val),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF895735),
                  ),
                  //Validates all form fields
                  //Checks if city and role are selected
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      if (selectedCity == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Please choose city".tr())),
                        );
                        return;
                      }
                      if (userType == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Please choose role".tr())),
                        );
                        return;
                      }
                      //calls
                      createAccount();
                    }
                  },
                  child: Text(
                    "Create Account".tr(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFF4F0E7),
                    ),
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


// Widgets for Inputs

class NameField extends StatelessWidget {
  final TextEditingController controller;
  const NameField({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.name,
      inputFormatters: [
        //Only allow letters
        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\u0600-\u06FF]')),
      ],
      decoration: InputDecoration(
        labelText: "Name".tr(),
        labelStyle: const TextStyle(color: Colors.brown),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
          borderSide: BorderSide(color: Color(0xFF582C0A)),
        ),
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return "Please enter name".tr();
        return null;
      },
    );
  }
}

class SurnameField extends StatelessWidget {
  final TextEditingController controller;
  const SurnameField({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.name,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\u0600-\u06FF]')),
      ],
      decoration: InputDecoration(
        labelText: "Surname".tr(),
        labelStyle: const TextStyle(color: Colors.brown),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
          borderSide: BorderSide(color: Color(0xFF582C0A)),
        ),
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return "Please enter surname".tr();
        return null;
      },
    );
  }
}

class EmailInput extends StatelessWidget {
  final TextEditingController controller;
  const EmailInput({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.emailAddress,
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
      //Validates email format.
      validator: (v) {
        if (v == null || v.isEmpty) return "Please enter email".tr();
        final emailRegex = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w{2,}$');
        if (!emailRegex.hasMatch(v)) return "Enter valid email".tr();
        return null;
      },
    );
  }
}

class PhoneInput extends StatelessWidget {
  final TextEditingController controller;
  const PhoneInput({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(10),
      ],
      decoration: InputDecoration(
        labelText: "Phone Number".tr(),
        labelStyle: const TextStyle(color: Colors.brown),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
          borderSide: BorderSide(color: Color(0xFF582C0A)),
        ),
      ),
      validator: (v) {
        //Only digits, max 10.
        if (v == null || v.isEmpty) return "Please enter phone".tr();
        if (v.length < 10) return "Number must be 10 digits".tr();
        return null;
      },
    );
  }
}

class PasswordInput extends StatelessWidget {
  final TextEditingController controller;
  final bool obscurePassword;
  final VoidCallback toggleObscure;

  const PasswordInput({
    super.key,
    required this.controller,
    required this.obscurePassword,
    required this.toggleObscure,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscurePassword,
      inputFormatters: [LengthLimitingTextInputFormatter(8)],
      decoration: InputDecoration(
        labelText: "Password (6-8)".tr(),
        labelStyle: const TextStyle(color: Colors.brown),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
          borderSide: BorderSide(color: Color(0xFF582C0A)),
        ),
        suffixIcon: IconButton(
          icon: Icon(obscurePassword ? Icons.visibility_off : Icons.visibility),
          onPressed: toggleObscure,
        ),
      ),
      validator: (v) {
        //6–8 characters, toggle visibility.
        if (v == null || v.isEmpty) return "Please enter password".tr();
        if (v.length < 6 || v.length > 8) return "Password must be 6–8 characters".tr();
        return null;
      },
    );
  }
}

class CityDropdown extends StatelessWidget {
  final List<String> cities;
  final String? selectedCity;
  final ValueChanged<String?> onChanged;

  const CityDropdown({
    super.key,
    required this.cities,
    required this.selectedCity,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      dropdownColor: Color(0xFFFCF7F2),
      value: selectedCity,
      decoration: InputDecoration(
        labelText: "City".tr(),
        labelStyle: const TextStyle(color: Colors.brown),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
          borderSide: BorderSide(color: Color(0xFF582C0A)),
        ),
      ),
      //Dropdown menu with city list
      items: cities.map((c) => DropdownMenuItem(value: c, child: Text(c,style:const TextStyle(
        color: Color(0xFF582C0A),fontWeight:FontWeight.bold,
      ),),)).toList(),
      onChanged: onChanged,
      validator: (v) => v == null ? "Please select city".tr() : null,
    );
  }
}
class RoleSelector extends StatelessWidget {
  final String? userType;
  final ValueChanged<String?> onChanged;

  const RoleSelector({super.key, required this.userType, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      validator: (value) {
        if (userType == null || userType!.isEmpty) return "Please choose role".tr();
        return null;
      },
      builder: (state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                //Radio buttons for role selection
                Radio<String>(
                  value: "Artist",
                  groupValue: userType,
                  activeColor: const Color(0xFF582C0A),
                  onChanged: (val) {
                    onChanged(val);
                    state.didChange(val);
                  },
                ),
                Text("Artist".tr(), style: const TextStyle(color: Color(0xFF582C0A))),
                Radio<String>(
                  value: "WorkshopOwner",
                  groupValue: userType,
                  activeColor: const Color(0xFF582C0A),
                  onChanged: (val) {
                    onChanged(val);
                    state.didChange(val);
                  },
                ),
                Text("Workshop Owner".tr(), style: const TextStyle(color: Color(0xFF582C0A))),
              ],
            ),
            if (state.hasError)
              Padding(
                padding: const EdgeInsets.only(top: 5, left: 5),
                child: Text(
                  state.errorText!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
