import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:easy_localization/easy_localization.dart';

class CancelReservationsPage extends StatelessWidget {
  final String userId;  // عشان اعرض حجوزاته الملغيه
  const CancelReservationsPage({super.key, required this.userId});

  String formatDate(Timestamp timestamp) {
    final date = timestamp.toDate(); // يحول ساعه فلاتر
    // فلاتر يرسل التاريخ تايم ستامب
    return DateFormat('yyyy-MM-dd').format(date);
  }

  @override // بناء الصفحه
  Widget build(BuildContext context) {
    final query = FirebaseFirestore.instance
        .collection('reservations') //نأخذ فقط الحجوزات اللي حالته
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: 'Canceled');

    return Scaffold(
      backgroundColor: const Color(0xFFFCF7F2),
      appBar: AppBar(
        title:  Text(
          "Cancel Reservation".tr(),
          style: TextStyle(
            color: Color(0xFF582C0A),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFFECDBC9),
        centerTitle: true,
        elevation: 2,
      ),

      body: StreamBuilder<QuerySnapshot>( //ويعيد بناء الواجهة تلقائيًا عند أي تغيير. ربط الواجهه مع الفاير
        stream: query.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF895735)),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return  Center(
              child: Text(
                "No canceled reservations yet".tr(),
                style: TextStyle(
                  color: Color(0xFF582C0A),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;

              final title = data['title'] ?? "Unnamed Workshop".tr();
              final people = data['people'] ?? 1; // القيمه الافتراضيه لعدد الاشخاص
              final dates = data['dates']as List<dynamic>?;
              //String formattedDate = date is Timestamp ? formatDate(date) : "";
              String formattedDates = '';
              if (dates != null && dates.isNotEmpty) {
                formattedDates = dates.map((d) {
                  if (d is Timestamp) {
                    return formatDate(d);
                  }
                  return d.toString();
                }).join(' - '); // عرض كل الأيام مفصولة بشرطة
              }


              return Card(
                color: const Color(0xFFF4ECE3),
                margin: const EdgeInsets.symmetric(vertical: 6),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: Color(0xFF582C0A),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Date
                      Text(
                        '${'Date'.tr()} $formattedDates',
                        style: const TextStyle(
                          color: Color(0xFF582C0A),
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 8),

                      // People

                      Text(
                        '${'People'.tr()} $people',  // عدد الناس
                        style: const TextStyle(
                          color: Color(0xFF582C0A),
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Status
                      Row(
                        children:  [
                          Text("Status: ".tr(), style: TextStyle(
                            color: Color(0xFF582C0A),
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          )),
                          Text(
                            "Canceled".tr(),
                            style: TextStyle(
                              color: Color(0xFFA87452),
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Canceled Icon + word (DON'T DELETE IT)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children:  [
                          Icon(Icons.block, color: Colors.grey, size: 24),
                          SizedBox(width: 6),
                          Text(
                            "Canceled".tr(),
                            style: TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
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

