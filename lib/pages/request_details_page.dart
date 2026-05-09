import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';

class RequestDetailsPage extends StatelessWidget {
  final Map<String, dynamic> data;

  const RequestDetailsPage({super.key, required this.data});

  // ───── دالة التعامل مع الرد Accept / Reject ─────
  Future<void> _handleResponse(
      BuildContext context, Map<String, dynamic> data, String status) async {
    // التحقق من وجود البيانات المطلوبة
    if (data['id'] == null ||
        data['senderId'] == null ||
        data['receiverId'] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: Missing required data".tr())),
      );
      return;
    }

    final requestId = data['id']!;
    final senderId = data['senderId']!;
    final receiverId = data['receiverId']!;

    try {
      // 1. التحقق من وجود الطلب أولاً
      final requestDoc = await FirebaseFirestore.instance
          .collection("partnership_requests")
          .doc(requestId)
          .get();

      if (!requestDoc.exists) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: Request not found".tr())),
        );
        return;
      }

      // 2. تحديث حالة الطلب
      await FirebaseFirestore.instance
          .collection("partnership_requests")
          .doc(requestId)
          .update({
        "status": status,
        "responseTime": FieldValue.serverTimestamp(),
      });

      // 3. إرسال إشعار للمرسل
      await FirebaseFirestore.instance
          .collection("users")
          .doc(senderId)
          .collection("notifications")
          .add({
        "type": "partnership_response",
        "status": status,
        "requestId": requestId,
        "receiverId": receiverId,
        "message": status == "accepted"
            ? "Your partnership request has been accepted".tr()
            : "Your partnership request has been rejected".tr(),
        "timestamp": FieldValue.serverTimestamp(),
      });

      // 4. عرض رسالة النجاح
      if (!context.mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: const Color(0xFFECDBC9),
          title:  Text(
            "Response Sent".tr(),
            style: TextStyle(
              color: Color(0xFF582C0A),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            status == "accepted"
                ? "Request accepted successfully!"
                : "Request rejected successfully",
            style: const TextStyle(color: Color(0xFF582C0A), fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // إغلاق الـ Dialog
                Navigator.pop(context,); // العودة لصفحة الطلبات
                Navigator.pop(context, status); // تحديث حالة الطلب
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
        ),
      );
    } catch (e) {
      // طباعة الخطأ للتصحيح
      print("Error details: $e");

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('error'.tr(args: [e.toString()])),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCF7F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFECDBC9),
        elevation: 2,
        shadowColor: Colors.grey.withOpacity(0.5),
        centerTitle: true,
        title:  Text(
          "Request Details".tr(),
          style: TextStyle(
            color: Color(0xFF582C0A),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionTitle(title: "Name:".tr()),
            Text(
              data['name'] ?? "Not provided".tr(),
              style: const TextStyle(fontSize: 18, color: Color(0xFF582C0A)),
            ),
            const SizedBox(height: 20),
            const DividerLine(),
            const SizedBox(height: 10),
            SectionTitle(title: "Email:".tr()),
            Text(
              data['email'] ?? "Not provided".tr(),
              style: const TextStyle(fontSize: 18, color: Color(0xFF582C0A)),
            ),
            const SizedBox(height: 20),
            const DividerLine(),
            const SizedBox(height: 10),
            SectionTitle(title: "Phone:".tr()),
            Text(
              data['phone'] ?? "Not provided".tr(),
              style: const TextStyle(fontSize: 18, color: Color(0xFF582C0A)),
            ),
            const SizedBox(height: 20),
            const DividerLine(),
            const SizedBox(height: 10),
            SectionTitle(title: "Specialty:".tr()),
            Text(
              data['specialty'] ?? "Not provided".tr(),
              style: const TextStyle(fontSize: 18, color: Color(0xFF582C0A)),
            ),
            const SizedBox(height: 20),
            const DividerLine(),
            const SizedBox(height: 10),
            SectionTitle(title: "Project:".tr()),
            Text(
              data['projectName'] ?? "Not provided".tr(),
              style: const TextStyle(fontSize: 18, color: Color(0xFF582C0A)),
            ),
            const SizedBox(height: 20),
            const DividerLine(),
            const SizedBox(height: 10),
            SectionTitle(title: "Description:".tr()),
            Text(
              data['description'] ?? "Not provided".tr(),
              style: const TextStyle(fontSize: 16, color: Color(0xFF582C0A)),
            ),
            const SizedBox(height: 40),
            const SizedBox(height: 40),

            (data['status'] == 'pending')

                ? Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () => _handleResponse(context, data, "rejected"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE85A4E),
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text(
                    "Reject".tr(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFF3F3F3),
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => _handleResponse(context, data, "accepted"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5B975C),
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text(
                    "Accept".tr(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFF3F3F3),
                    ),
                  ),
                ),
              ],
            )
                : Center(
              child: Text(
                data['status'] == 'accepted'
                    ? "Accepted".tr()
                    : "Rejected".tr(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF582C0A),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String title;
  const SectionTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Color(0xFF895735),
        ),
      ),
    );
  }
}

class DividerLine extends StatelessWidget {
  const DividerLine({super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: Container(
        width: double.infinity,
        height: 1.4,
        decoration: BoxDecoration(
          color: const Color(0xFFEDE5DD),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
      ),
    );
  }
}