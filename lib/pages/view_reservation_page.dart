import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ViewReservationsPage extends StatelessWidget {
  final String userId;
  const ViewReservationsPage({super.key, required this.userId});

  String formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    return DateFormat('yyyy-MM-dd').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final stream = FirebaseFirestore.instance
        .collection('reservations')
        .where('userId', isEqualTo: userId)
        .snapshots(); // جلب كل حجوزات هذا المستخدم

    return Scaffold( //هيكل الصفحه
      backgroundColor: const Color(0xFFFCF7F2),
      appBar: AppBar(
        title: const Text(
          "View Reservation",
          style: TextStyle(
            color: Color(0xFF582C0A),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFFECDBC9),
        centerTitle: true,
        elevation: 2,
        shadowColor: Colors.grey.withOpacity(0.5),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF582C0A)),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text("Something went wrong"));// لو خطا يعرض خطأ
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator()); // لو انتظار يطلع دائره التحميل
          }

          // فلترة الحجوزات غير الملغاة
          final reservations = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['status'] != 'Canceled';
          }).toList();

          if (reservations.isEmpty) {
            return const Center(child: Text("No reservations yet",style: TextStyle(color: Color(0xFF582C0A),fontSize: 18,
              fontWeight: FontWeight.bold,),
            ));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: reservations.length,
            itemBuilder: (context, index) {
              final reservation = reservations[index];
              final data = reservation.data() as Map<String, dynamic>;
              final title = data['title'] ?? 'Unnamed Workshop';
              final people = data['people'] ?? 1;

              final dates = data['dates'] as List<dynamic>?; // array من الأيام
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
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: Color(0xFF582C0A),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Date: $formattedDates",
                        style: const TextStyle(
                          color: Color(0xFF582C0A),
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "People: $people",
                        style: const TextStyle(
                          color: Color(0xFF582C0A),
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: const [
                          Text(
                            "Status: ",
                            style: TextStyle(
                              color: Color(0xFF582C0A),
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            "Confirmed",
                            style: TextStyle(
                              color: Color(0xFFA87452),
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: IconButton(
                          icon: const Icon(
                            Icons.delete,
                            color: Color.fromARGB(255, 150, 69, 64),
                          ),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (_) => AlertDialog(
                                backgroundColor: const Color(0xFFFFF7F2),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.warning_amber_rounded,
                                      color: Color(0xFF895735),
                                      size: 80,
                                    ),
                                    const SizedBox(height: 15),
                                    const Text(
                                      "Are you sure you want to delete this reservation?",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF582C0A),
                                      ),
                                    ),
                                    const SizedBox(height: 20),

                                    // زر التأكيد
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                        const Color(0xFF895735),
                                        minimumSize: const Size(
                                            double.infinity, 45),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                          BorderRadius.circular(15),
                                        ),
                                      ),
                                      onPressed: () async {
                                      //  final navigator = Navigator.of(context);
                                        await FirebaseFirestore.instance
                                            .collection('reservations')
                                            .doc(reservation.id)
                                            .update(
                                            {'status': 'Canceled'});

                                        Navigator.pop(context); // إغلاق البوب-أب
                                      },
                                      child: const Text(
                                        "Confirm",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 10),

                                    // زر الإلغاء
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                      },
                                      child: const Text(
                                        "Cancel",
                                        style: TextStyle(
                                          color: Color(0xFF895735),
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
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