import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';

class PartnershipResponsesPage extends StatefulWidget {
  const PartnershipResponsesPage({super.key});

  @override
  State<PartnershipResponsesPage> createState() =>
      _PartnershipResponsesPageState();
}

class _PartnershipResponsesPageState extends State<PartnershipResponsesPage> {
  User? user;
  Stream<QuerySnapshot>? requestsStream; // تيار طلبات الشراكة

  @override
  void initState() {
    super.initState(); // جلب المستخدم الحالي
    user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      // جرب بدون orderBy أولًا للتأكد من البيانات
      requestsStream = FirebaseFirestore.instance
          .collection('partnership_requests')
          .where('senderId', isEqualTo: user!.uid)
          //.orderBy('timestamp', descending: true) // يمكن تفعيلها إذا جميع المستندات تحتوي timestamp
          .snapshots();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      // تحقق من تسجيل الدخول
      return Scaffold(
        backgroundColor: const Color(0xFFFCF7F2),
        body: Center(
          child: Text(
            "Please log in to view responses".tr(),
            style: TextStyle(color: Colors.brown, fontSize: 16),
          ),
        ),
      );
    }
    if (requestsStream == null) {
      // تحقق من تيار الطلبات
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.brown)),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFCF7F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFECDBC9),
        elevation: 2,
        shadowColor: Colors.grey.withOpacity(0.5),
        centerTitle: true,
        title: Text(
          "Partnership Responses".tr(),
          style: TextStyle(
            color: Color(0xFF582C0A),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(// بناء واجهة المستخدم بناءً على تيار البيانات
        stream: requestsStream,// استماع لتيار طلبات الشراكة
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {// انتظار البيانات
            return const Center(
                child: CircularProgressIndicator(color: Colors.brown));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                "No responses yet".tr(),
                style: TextStyle(color: Colors.brown, fontSize: 16),
              ),
            );
          }

          final requests = snapshot.data!.docs;// جلب المستندات من البيانات

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,// عدد العناصر في القائمة
            itemBuilder: (context, index) {// بناء كل عنصر في القائمة
              final data = requests[index].data() as Map<String, dynamic>;

              final receiverName = data["receiverName"] ?? "Unknown".tr();
              final projectName = data["projectName"] ?? "";
              final description = data["description"] ?? "";
              final status = data["status"] ?? "pending".tr();

              // تحديد اللون والايقونة حسب الحالة
              Color statusColor;
              IconData statusIcon;
              switch (status) {
                case "accepted":
                  statusColor = Colors.green;
                  statusIcon = Icons.check_circle;
                  break;
                case "rejected":
                  statusColor = Colors.red;
                  statusIcon = Icons.cancel;
                  break;
                default:
                  statusColor = Colors.orange;
                  statusIcon = Icons.hourglass_top;
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF2EE),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Color(0xFF987B73), width: 2.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          receiverName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.brown,
                          ),
                        ),
                        Row(
                          children: [
                            Icon(statusIcon, color: statusColor, size: 20),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                status.toUpperCase(),
                                style: TextStyle(
                                  color: statusColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Project".tr(args: [projectName]),
                      style: const TextStyle(
                        color: Colors.brown,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
