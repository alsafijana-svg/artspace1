import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class EditProfilePage extends StatelessWidget {
  const EditProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCF7F2),
      appBar: AppBar(
        title:  Text(
          "Edit Profile".tr(),
          style: TextStyle(
              color: Color(0xFF582C0A), fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFECDBC9),
        centerTitle: true,
        elevation: 2,
        shadowColor: Colors.brown.withOpacity(0.5),
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: EditProfileForm(),
      ),
    );
  }
}

/// Form section for editing profile
class EditProfileForm extends StatefulWidget {
  const EditProfileForm({super.key});

  @override
  State<EditProfileForm> createState() => _EditProfileFormState();
}

class _EditProfileFormState extends State<EditProfileForm> {
  final formKey = GlobalKey<FormState>();
  final usernameController = TextEditingController();
  final fullnameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();

  bool obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        children: [
          const SizedBox(height: 20),
          InputFieldWidget(
            controller: usernameController,
            label: "Username".tr(),
            hint: "Enter your Username".tr(),
            icon: Icons.person,
            validator: (value) =>
                value == null || value.isEmpty ? 'Please enter your username' .tr(): null,
          ),
          const SizedBox(height: 20),
          InputFieldWidget(
            controller: fullnameController,
            label: "Full Name".tr(),
            hint: "Enter your full name".tr(),
            icon: Icons.person,
          ),
          const SizedBox(height: 20),
          InputFieldWidget(
            controller: emailController,
            label: "Email".tr(),
            hint: "example@gmail.com".tr(),
            icon: Icons.email,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Please enter your email'.tr();
              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                return "Enter valid email".tr();
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          InputFieldWidget(
            controller: phoneController,
            label: "Phone Number".tr(),
            hint: "05xxxxxxxx".tr(),
            icon: Icons.phone,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 20),
          PasswordFieldWidget(
            controller: passwordController,
            obscureText: obscurePassword,
            toggleObscure: () {
              setState(() {
                obscurePassword = !obscurePassword;
              });
            },
          ),
          const SizedBox(height: 20),
          SaveButtonWidget(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Profile Updated !".tr())),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

/// Generic input field widget
class InputFieldWidget extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;

  const InputFieldWidget({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.brown),
        hintText: hint,
        hintStyle: TextStyle(color: Colors.brown.withOpacity(0.6)),
        prefixIcon: Icon(icon, color: const Color(0xFF582C0A)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Color(0xFF582C0A)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Color(0xFF582C0A)),
        ),
      ),
      validator: validator,
    );
  }
}

/// Password field widget with show/hide toggle
class PasswordFieldWidget extends StatelessWidget {
  final TextEditingController controller;
  final bool obscureText;
  final VoidCallback toggleObscure;

  const PasswordFieldWidget({
    super.key,
    required this.controller,
    required this.obscureText,
    required this.toggleObscure,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: TextInputType.visiblePassword,
      decoration: InputDecoration(
        labelText: "Password".tr(),
        labelStyle: const TextStyle(color: Colors.brown),
        hintText: "Enter your password".tr(),
        hintStyle: TextStyle(color: Colors.brown.withOpacity(0.6)),
        prefixIcon: const Icon(Icons.lock, color: Color(0xFF582C0A)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Color(0xFF582C0A)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Color(0xFF582C0A)),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            obscureText ? Icons.visibility_off : Icons.visibility,
            color: const Color(0xFF582C0A),
          ),
          onPressed: toggleObscure,
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return "Please enter your password".tr();
        if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).+$').hasMatch(value)) {
          return "Password must contain:\n- uppercase letter\n- lowercase letter\n- number".tr();
        }
        return null;
      },
    );
  }
}

/// Save button widget
class SaveButtonWidget extends StatelessWidget {
  final VoidCallback onPressed;
  const SaveButtonWidget({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF895735),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      onPressed: onPressed,
      child:  Text(
        "Save Changes".tr(),
        style: TextStyle(
            color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }
}
