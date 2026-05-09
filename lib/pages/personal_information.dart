
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';

class PersonalInformationPage extends StatefulWidget {
  const PersonalInformationPage({super.key});

  @override
  State<PersonalInformationPage> createState() => _PersonalInformationPageState();
}

class _PersonalInformationPageState extends State<PersonalInformationPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Controllers & state
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController(); // موجود كما هو
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  String? _gender;
  String? _city;

  final List<String> _genders =  ['Male'.tr(), 'Female'.tr()];
  final List<String> _cities = ["Riyadh".tr(), "Jeddah".tr(), "Makkah".tr(), "Madinah".tr(),
  "Dammam".tr(), "Taif".tr(), "Abha".tr(), "Tabuk".tr(), "Najran".tr(), "Hail".tr()];
  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Personal Information".tr(),
            style: const TextStyle(color: Color(0xFF582C0A), fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFECDBC9),
        centerTitle: true,
        elevation: 2,
        shadowColor: Colors.grey.withOpacity(0.5),
      ),
      backgroundColor: const Color(0xFFFCF7F2),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              FullNameField(controller: _fullNameController),
              const SizedBox(height: 16),
              PhoneField(controller: _phoneController),
              const SizedBox(height: 16),
              DobField(controller: _dobController),
              const SizedBox(height: 16),
              GenderDropdown(
                value: _gender,
                items: _genders,
                onChanged: (v) => setState(() => _gender = v),
              ),
              const SizedBox(height: 16),
              CityDropdown(
                value: _city,
                items: _cities,
                onChanged: (v) => setState(() => _city = v),
              ),
              const SizedBox(height: 24),
              SaveButton(
                formKey: _formKey,
                fullNameController: _fullNameController,
                phoneController: _phoneController,
                city: _city,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

//name

class FullNameField extends StatelessWidget {
  final TextEditingController controller;
  const FullNameField({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: "Full Name".tr(),
        labelStyle: const TextStyle(color: Colors.brown),
        prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF582C0A)),
        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Colors.brown),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Color(0xFF895735), width: 2),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return "Enter full name".tr();
        // Only letters, 1–3 words
        final nameRegex = RegExp(r'^[A-Za-z]+(?: [A-Za-z]+){0,2}$');
        if (!nameRegex.hasMatch(value.trim())) {
          return "Full name must contain only letters (1 to 3 words)".tr();
        }
        return null;
      },
    );
  }
}
//phone

class PhoneField extends StatelessWidget {
  final TextEditingController controller;
  const PhoneField({super.key, required this.controller});

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
        prefixIcon: const Icon(Icons.phone_outlined, color: Color(0xFF582C0A)),
        labelStyle: const TextStyle(color: Colors.brown),
        border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
          borderSide: BorderSide(color: Color(0xFF582C0A)),
        ),
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return "Please enter phone number".tr();
        if (v.length < 10) return "Number must be 10 digits".tr();
        return null;
      },
    );
  }
}

class DobField extends StatelessWidget {
  final TextEditingController controller;
  const DobField({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      readOnly: true,
      controller: controller,
      decoration: InputDecoration(
        labelText: 'Date of Birth'.tr(),
        labelStyle: const TextStyle(color: Colors.brown),
        border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
          borderSide: BorderSide(color: Color(0xFF582C0A)),
        ),
        prefixIcon: const Icon(Icons.calendar_today, color: Color(0xFF582C0A)),
      ),
      onTap: () async {
        final pickedDate = await showDatePicker(
          context: context,
          initialDate: DateTime(2000),
          firstDate: DateTime(1900),
          lastDate: DateTime.now(),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: ColorScheme.light(
                  primary: Color(0xFF582C0A),       // لون الهيدر
                  onPrimary: Colors.white,          // لون النص فوق الهيدر
                  surface: Color(0xFFFFFDFC),       // خلفية البوب أب
                  onSurface: Color(0xFF582C0A),     // لون النصوص داخل التقويم
                ),
              ),
              child: child!,
            );
          },
        );

        if (pickedDate != null) {
          controller.text = "${pickedDate.day}/${pickedDate.month}/${pickedDate.year}";
        }
      },
      validator: (value) => (value == null || value.isEmpty) ? 'Please select date of birth'.tr() : null,
    );
  }
}

class GenderDropdown extends StatelessWidget {
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  const GenderDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      dropdownColor: const Color(0xFFFCF7F2),
      style: const TextStyle(color: Color(0xFF582C0A)),
      iconEnabledColor: const Color(0xFF582C0A),
      items: items
          .map((g) => DropdownMenuItem(
        value: g,
        child: Text(g.tr(), style: const TextStyle(color: Color(0xFF582C0A),fontWeight: FontWeight.bold)),
      ))
          .toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: 'Gender'.tr(),
        border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
          borderSide: BorderSide(color: Color(0xFF582C0A)),
        ),
        prefixIcon: const Icon(Icons.male, color: Color(0xFF582C0A)),
        labelStyle: const TextStyle(color: Colors.brown),
      ),
      validator: (v) => (v == null || v.isEmpty) ? 'Please select gender'.tr() : null,
    );
  }
}

class CityDropdown extends StatelessWidget {
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  const CityDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      dropdownColor: const Color(0xFFFCF7F2),
      style: const TextStyle(color: Color(0xFF582C0A)),
      iconEnabledColor: const Color(0xFF582C0A),
      items: items
          .map((c) => DropdownMenuItem(
        value: c,
        child: Text(c.tr(), style: const TextStyle(color: Color(0xFF582C0A),fontWeight:FontWeight.bold,)),
      ))
          .toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: 'City'.tr(),
        border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
          borderSide: BorderSide(color: Color(0xFF582C0A)),
        ),
        prefixIcon: const Icon(Icons.location_city, color: Color(0xFF582C0A)),
        labelStyle: const TextStyle(color: Colors.brown),
      ),
      validator: (v) => (v == null || v.isEmpty) ? 'Please select city'.tr() : null,
    );
  }
}


class SaveButton extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController fullNameController;
  final TextEditingController phoneController;
  final String? city;

  const SaveButton({
    super.key,
    required this.formKey,
    required this.fullNameController,
    required this.phoneController,
    required this.city,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF895735),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        onPressed: () async {
          if (formKey.currentState!.validate()) {
            final user = FirebaseAuth.instance.currentUser;
            if (user != null) {
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .set({
                'name': fullNameController.text.trim(),
                 'phone' :phoneController.text.trim(),
                'city' :city,
              },
                  SetOptions(merge: true));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Information saved successfully".tr()),
                backgroundColor: Colors.brown,
                 behavior: SnackBarBehavior.floating,
                  duration: Duration(seconds: 2),

                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("User not logged in".tr())),
              );
            }
          }
        },
        child: Text(
          "Save Change".tr(),
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFF4F0E7)),
        ),
      ),
    );
  }
}


