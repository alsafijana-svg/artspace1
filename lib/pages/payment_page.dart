import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'view_reservation_page.dart';
import 'package:easy_localization/easy_localization.dart';

class MaxWordsInputFormatter extends TextInputFormatter {
  final int maxWords; // الحد الأقصى لعدد الكلمات
  MaxWordsInputFormatter({
    required this.maxWords // تعيين الحد الأقصى لعدد الكلمات
    });
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {// تحقق من عدد الكلمات
    final words = newValue.text.split(RegExp(r'\s+'));// تقسيم النص إلى كلمات
    if (words.length > maxWords) return oldValue;// إذا تجاوز الحد، أعد القيمة القديمة
    return newValue;
  }
}

class PaymentPage extends StatelessWidget {
  final String userId;
  final String reservationId;
  PaymentPage({super.key, required this.userId, required this.reservationId});

  final _formKey = GlobalKey<FormState>();// مفتاح النموذج للتحقق من الصحة
  final _nameController = TextEditingController();// متحكمات حقول الإدخال
  final _cardNumberController = TextEditingController();// متحكم لحقل رقم البطاقة
  final _expiryController = TextEditingController(); // متحكم لحقل تاريخ الانتهاء
  final _cvvController = TextEditingController(); // متحكم لحقل CVV

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser; // جلب المستخدم الحالي
    final hasExternalUserId = userId.isNotEmpty;// تحقق من وجود userId خارجي

    if (user == null && !hasExternalUserId) { // إذا لم يكن هناك مستخدم مسجل دخول ولا userId خارجي
      Future.microtask(() {// عرض رسالة تطالب بتسجيل الدخول
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Please login first!".tr())),// عرض رسالة
        );
        Navigator.pop(context);// العودة إلى الصفحة السابقة
      });
      return const SizedBox.shrink();// إرجاع عنصر فارغ مؤقتًا
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFCF7F2),
      appBar: AppBar(
        title:  Text("Payment".tr(),
            style: TextStyle(color: Color(0xFF582C0A), fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFECDBC9),
        elevation: 2,
        centerTitle: true,
        shadowColor: Colors.brown.withOpacity(0.5),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey, // تعيين مفتاح النموذج
          child: ListView(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,// محاذاة الصور
                children: [
                  Image.asset("images/mada.png", width: 80),// صورة مدا
                  Image.network("https://upload.wikimedia.org/wikipedia/commons/0/04/Mastercard-logo.png", width: 80),// صورة ماستر كارد
                  Image.network("https://upload.wikimedia.org/wikipedia/commons/4/41/Visa_Logo.png", width: 80),// صورة فيزا
                ],
              ),
              const SizedBox(height: 20),
              NameField(controller: _nameController),// حقل اسم حامل البطاقة
              const SizedBox(height: 20),
              CardNumberField(controller: _cardNumberController),// حقل رقم البطاقة
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: ExpiryField(controller: _expiryController)),// حقل تاريخ الانتهاء
                  const SizedBox(width: 16),
                  Expanded(child: CVVField(controller: _cvvController)),// حقل CVV
                ],
              ),
              const SizedBox(height: 30),
              PaymentButton(
                formKey: _formKey,// زر الدفع مع تمرير المتحكمات
                nameController: _nameController, // متحكم اسم حامل البطاقة
                cardController: _cardNumberController, // متحكم رقم البطاقة
                expiryController: _expiryController,// متحكم تاريخ الانتهاء
                cvvController: _cvvController,// متحكم CVV
                reservationId: reservationId, // معرف الحجز
                userId: userId,// معرف المستخدم
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =================== Fields ===================
class NameField extends StatelessWidget {
  final TextEditingController controller;
  const NameField({super.key, required this.controller});

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    cursorColor: Color(0xFF582C0A),
    decoration:  InputDecoration(
      hintText: "Card Holder Name".tr(),
      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(20)),
        borderSide: BorderSide(color: Color(0xFF582C0A)),
      ),
    ),


    inputFormatters: [// تنسيقات الإدخال
      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')), // السماح فقط بالحروف والمسافات
      MaxWordsInputFormatter(maxWords: 3),// الحد الأقصى لعدد الكلمات هو 3 كلمات
    ],
    validator: (v) => v == null || v.isEmpty ? "Required".tr() : null, // التحقق من الصحة
  );
}

class CardNumberField extends StatelessWidget {
  final TextEditingController controller;
  const CardNumberField({super.key, required this.controller});
  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    cursorColor: Color(0xFF582C0A),
    keyboardType: TextInputType.number,
    inputFormatters: [
      FilteringTextInputFormatter.digitsOnly,
      LengthLimitingTextInputFormatter(16),
    ],
    decoration:  InputDecoration(
      hintText: "Card Number".tr(),
      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(20)),
        borderSide: BorderSide(color: Color(0xFF582C0A)),
      ),
    ),


    validator: (v) {
      if (v == null || v.isEmpty) return "Required".tr(); // التحقق من الصحة
      if (v.length != 16) return "Card number must be 16 digits".tr(); // تحقق من الطول
      return null; 
    },
  );
}

class ExpiryField extends StatelessWidget {
  final TextEditingController controller;
  const ExpiryField({super.key, required this.controller});
  @override
  Widget build(BuildContext context) {
    controller.addListener(() {// تنسيق النص ليكون MM/YY
      String text = controller.text.replaceAll("/", "");// إزالة الشرطات المائلة
      if (text.length > 4) text = text.substring(0, 4);// الحد الأقصى للطول إلى 4 أرقام
      String newText = "";// بناء النص الجديد
      for (int i = 0; i < text.length; i++) {// إضافة الشرطة المائلة بعد الرقم الثاني
        if (i == 2) newText += "/";// إضافة الشرطة المائلة
        newText += text[i];// إضافة الرقم الحالي
      }
      if (newText != controller.text) {// تحديث النص إذا كان مختلفًا
        controller.value = controller.value.copyWith(// تحديث قيمة المتحكم
          text: newText,// النص الجديد
          selection: TextSelection.collapsed(offset: newText.length),// وضع المؤشر في النهاية
        );
      }
    });

    return TextFormField(
      controller: controller,
      cursorColor: Color(0xFF582C0A),
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(
        hintText: "MM/YY",
        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(20))
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
          borderSide: BorderSide(color: Color(0xFF582C0A)),
        ),
      ),

      validator: (v) {// التحقق من الصحة
        if (v == null || v.isEmpty) return "Required".tr();// التحقق من الحقل الفارغ
        final parts = v.split("/");// تقسيم النص إلى جزئين
        if (parts.length != 2) return "Invalid format".tr();// التحقق من التنسيق
        if (parts[0].length != 2 || parts[1].length != 2) return "Invalid format".tr();// التحقق من الطول
        final month = int.tryParse(parts[0]);// تحويل الجزء الأول إلى رقم
        final year= int.tryParse(parts[1]);// تحويل الجزء الثاني إلى رقم
        if (month == null || year == null) return "Invalid format".tr();// التحقق من التحويل
        if (month < 1 || month > 12) return "Invalid month".tr();// التحقق من الشهر
        if (year < 26) return "Invalid year".tr();// التحقق من السنة (افتراضًا أن السنة الحالية هي 2024)
        return null;
      },
    );
  }
}

class CVVField extends StatelessWidget {
  final TextEditingController controller;
  const CVVField({super.key, required this.controller});
  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    cursorColor: Color(0xFF582C0A),
    keyboardType: TextInputType.number,
    maxLength: 3,
    decoration: const InputDecoration(
      hintText: "CVV",
      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(20))
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(20)),
        borderSide: BorderSide(color: Color(0xFF582C0A)),
      ),
      counterText: "",
    ),
    validator: (v) {
      if (v == null || v.isEmpty) return "Required".tr(); // التحقق من الصحة
      if (v.length != 3) return "CVV must be 3 digits".tr();// تحقق من الطول
      return null;
    },
  );
}

// =================== Payment Button ===================
class PaymentButton extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameController, cardController, expiryController, cvvController;
  final String reservationId;
  final String userId;

  const PaymentButton({
    super.key,
    required this.formKey,
    required this.nameController,
    required this.cardController,
    required this.expiryController,
    required this.cvvController,
    required this.reservationId,
    required this.userId,
  });

  // ✅ تعديل الانتقال فقط
  Future<void> _completePayment(BuildContext context) async {
    try {
      await FirebaseFirestore.instance
          .collection('reservations')
          .doc(reservationId)
          .update({
        'status': 'Confirm',
        'paymentDate': Timestamp.now(),
      });

      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) {
            Future.delayed(const Duration(seconds: 2), () {
              Navigator.pop(ctx);

              // ✅ الانتقال إلى ViewReservationsPage مع حذف PaymentPage من الستاك
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (context) => ViewReservationsPage(userId: userId),
                ),
                    (route) => route.isFirst, // الاحتفاظ فقط بالصفحة الأصلية في البار السفلي
              );
            });
            return AlertDialog(
              backgroundColor: const Color(0xFFFCF7F2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, color: Color(0xFF895735), size: 80),
                  SizedBox(height: 15),
                  Text(
                    "Payment Successful".tr(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF582C0A),
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      }
    } catch (e) {
      if (context.mounted) {// عرض رسالة خطأ في حالة الفشل
        showDialog(//
          context: context,
          builder: (ctx) => AlertDialog(
            title:  Text("Error".tr()),
            content:Text("Payment Failed".tr(args: [e.toString()])),// عرض رسالة الخطأ
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("OK")),// زر إغلاق الرسالة
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => ElevatedButton(
    onPressed: () {
      if (formKey.currentState!.validate()) _completePayment(context);// إذا كان النموذج صالحًا، أكمل الدفع
    },
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF895735),
      foregroundColor: const Color(0xFFF4F0E7),
      minimumSize: const Size(double.infinity, 55),
    ),
    child:  Text(
      "Pay Now".tr(),
      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    ),
  );
}