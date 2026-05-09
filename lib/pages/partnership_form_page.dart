import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';

class PartnershipFormPage extends StatefulWidget {
  //variables
  final String receiverId;      // المستخدم الذي سنرسل له الطلب
  final String receiverName;    // اسم الشخص لإظهاره في الـ AppBar

  const PartnershipFormPage({
    //Constructor
    super.key,
    required this.receiverId,
    required this.receiverName,
  });

  @override
  State<PartnershipFormPage> createState() => _PartnershipFormPageState();
}

class _PartnershipFormPageState extends State<PartnershipFormPage> {
  // مفتاح النموذج للتحقق من صحة الإدخالات
  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final specialtyController = TextEditingController();
  final projectNameController = TextEditingController();
  final descriptionController = TextEditingController();

  @override
  // استدعاء عند بدء الصفحة
  void initState() {// جلب بيانات المستخدم الحالي عند بدء الصفحة
    super.initState();
    

    // جلب بيانات المستخدم الحالي
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      emailController.text = user.email ?? "";// تعيين البريد الإلكتروني من FirebaseAuth

      FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .get()
          .then((doc) {
        if (doc.exists) {
          final data = doc.data();
          setState(() {
            nameController.text = data?['name'] ?? "";
            phoneController.text = data?['phone'] ?? "";
          });
        }
      });
    }
  }

  // إرسال الطلب وعرض Dialog
  Future<void> sendPartnershipRequest() async {
    final sender = FirebaseAuth.instance.currentUser;
    if (sender == null) return;

    // إضافة الطلب إلى Firestore
    await FirebaseFirestore.instance.collection("partnership_requests").add({
      "senderId": sender.uid,
      "receiverId": widget.receiverId,
      "receiverName": widget.receiverName,
      "name": nameController.text.trim(),
      "email": emailController.text.trim(),
      "phone": phoneController.text.trim(),
      "specialty": specialtyController.text.trim(),
      "projectName": projectNameController.text.trim(),
      "description": descriptionController.text.trim(),
      "status": "pending",
      "timestamp": Timestamp.now(),
    });

    // التأكد أن الصفحة ما زالت موجودة
    if (!mounted) return;

    // عرض رسالة Dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(// تصميم الرسالة
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: const Color(0xFFECDBC9),
          title:  Text(
            "Request Sent".tr(),
            style: TextStyle(
              color: Color(0xFF582C0A),
              fontWeight: FontWeight.bold,
            ),
          ),
          content:  Text(
            "Your partnership request has been sent successfully!".tr(),
            style: TextStyle(
              color: Color(0xFF582C0A),
              fontSize: 16,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // يغلق الرسالة
                Navigator.pop(context); // يرجع للصفحة السابقة
              },
              child:  Text(
                "OK".tr(),
                style: TextStyle(
                  color: Color(0xFF582C0A),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // تصميم حقل النصوص
  Widget buildField(String label, TextEditingController controller,
      {int maxLines = 1}) {// دالة لبناء حقل نصي مع التحقق من الصحة
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        cursorColor: Color(0xFF582C0A),
        controller: controller,
        maxLines: maxLines,
        // التحقق من صحة الإدخال
        validator: (value) {
          if (value == null || value.isEmpty) return "Required field".tr();
          return null;
        },
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(        // هنا لون النص اللي بالـ label
          color: Color(0xFF582C0A),  
          ),
          filled: true,
          fillColor: const Color(0xFFFCF7F2),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(color: Color(0xFF582C0A)), // لون الحافة
          ),
           focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Color(0xFF582C0A)), // لون الحافة عند التركيز
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Color(0xFF582C0A)),
        ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCF7F2),
      appBar: AppBar(
        title: Text(
          
          "Partner".tr(args: [widget.receiverName]),// عنوان الـ AppBar مع اسم المستلم
          style: const TextStyle(
            color: Color(0xFF582C0A),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 2,
        centerTitle: true,
        shadowColor: Colors.grey.withOpacity(0.5),
        backgroundColor: const Color(0xFFECDBC9),
        iconTheme: const IconThemeData(color: Color(0xFF582C0A)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
           children: [
            buildField('Your Name'.tr(), nameController),
            buildField('Email'.tr(), emailController),
            buildField('Phone Number'.tr(), phoneController),
            buildField('Your Specialty'.tr(), specialtyController),
            buildField('Project Name'.tr(), projectNameController),
            buildField('Project Description'.tr(), descriptionController, maxLines: 4),
            const SizedBox(height: 20),
  
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    sendPartnershipRequest();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF895735),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)
                  ),
                  textStyle: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                child: Text("Send Request".tr()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}