import 'package:artspace1/pages/request_details_page.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';

class PartnershipRequestsPage extends StatefulWidget {
  const PartnershipRequestsPage({super.key});

  @override
  State<PartnershipRequestsPage> createState() =>
      _PartnershipRequestsPageState();
}

class _PartnershipRequestsPageState extends State<PartnershipRequestsPage> {
  final currentUser = FirebaseAuth.instance.currentUser;// المستخدم الحالي
  List<Map<String, dynamic>> _cachedRequests = [];// كاش محلي للطلبات

  @override
  Widget build(BuildContext context) {
    // تأكد أن المستخدم متوفر
    if (currentUser == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFFCF7F2),
        appBar: AppBar(
          backgroundColor: const Color(0xFFECDBC9),
          centerTitle: true,
          title: Text("Partnership Requests".tr(),
              style: const TextStyle(color: Color(0xFF582C0A))),
        ),
        body: Center(child: Text("Please log in".tr())),
      );
    }
    // تيار بيانات طلبات الشراكة للمستخدم الحالي

    final stream = FirebaseFirestore.instance 
        .collection("partnership_requests")
        .where("receiverId", isEqualTo: currentUser!.uid)
        .orderBy("timestamp", descending: true)
        .snapshots();
// واجهة المستخدم
    return Scaffold(
      backgroundColor: const Color(0xFFFCF7F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFECDBC9),
        elevation: 2,
        shadowColor: Colors.grey.withOpacity(0.5),
        centerTitle: true,
        title: Text(
          "Partnership Requests".tr(),
          style: const TextStyle(
            color: Color(0xFF582C0A),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: stream,
        builder: (context, snapshot) {
          // طباعة لأغراض التصحيح - ازلها لاحقًا لو أحببت
          print("StreamBuilder state: ${snapshot.connectionState}");
          if (snapshot.hasError) {
            print("Firestore stream error: ${snapshot.error}");
          }

          // إذا وصلت بيانات سليمة حدّث الكاش
          if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
            final docs = snapshot.data!.docs;
            final fresh = docs.map((doc) {
              final map = <String, dynamic>{};
              map.addAll(doc.data() as Map<String, dynamic>);
              map['id'] = doc.id;
              return map;
            }).toList();

            // حدّث الكاش مرة واحدة (وإذا مختلف)
            _cachedRequests = fresh;
          } else {
            // snapshot فارغ أو لا بيانات؛ لا تمسح الكاش — بدلاً من ذلك نحتفظ بما لدينا
            print("Snapshot empty or no data; keeping cached ${_cachedRequests.length} items.");
          }

          // أثناء التحميل، إذا الكاش خالي نعرض مؤشر تحميل
          if (snapshot.connectionState == ConnectionState.waiting && _cachedRequests.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final requests = _cachedRequests;

          if (requests.isEmpty) {
            return Center(
              child: Text(
                "No partnership requests yet".tr(),
                style: const TextStyle(color: Colors.brown, fontSize: 18),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final req = requests[index];
              final status = (req['status'] ?? 'pending') as String;

              return GestureDetector(
                onTap: () async {
                  // يمكنك تعطيل التنقل إذا لم ترغب بذلك بناءً على الحالة:
                  // if (status != 'pending') return;
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RequestDetailsPage(data: req),
                    ),
                  );
                  // بعد العودة، لا تحتاج لفعل شيء لأن الـ stream سيحدّث الكاش تلقائيًا
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAF2EE),
                    borderRadius: BorderRadius.circular(16),
                    border:
                    Border.all(color: const Color(0xFF987B73), width: 2.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        req["projectName"] ?? "Untitled Project".tr(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.brown,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "From: ${req['name'] ?? 'Unknown'}",
                        style: const TextStyle(
                          color: Colors.brown,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Specialty: ${req['specialty'] ?? '-'}",
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // حالة الطلب
                      Text(
                        "Status: ${status.tr()}",
                        style: TextStyle(
                          color: status == 'accepted'
                              ? Colors.green
                              : status == 'rejected'
                              ? Colors.red
                              : Colors.brown,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
