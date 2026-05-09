import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:easy_localization/easy_localization.dart';

class ArtistReservationPage extends StatelessWidget {
  const ArtistReservationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final reservationsQuery = FirebaseFirestore.instance
        .collection('reservations')
        .orderBy('date', descending: false);

    return Scaffold(
      backgroundColor: const Color(0xFFFCF7F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFECDBC9),
        centerTitle: true,
        elevation: 2,
        shadowColor: Colors.grey.withOpacity(0.5),
        title:  Text(
          "Artist Reservations".tr(),
          style: TextStyle(
            color: Color(0xFF582C0A),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: reservationsQuery.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return  Center(
              child: Text(
                "No reservations yet".tr(),
                style: TextStyle(
                  color: Color(0xFF582C0A),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }

          final reservations = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: reservations.length,
            itemBuilder: (context, index) {
              final data = reservations[index].data() as Map<String, dynamic>;

              final dates = data['dates'] as List<dynamic>?; // array من الأيام
              String formattedDates = '';
              if (dates != null && dates.isNotEmpty) {
                formattedDates = dates.map((d) {
                  if (d is Timestamp) {
                    return DateFormat('yyyy-MM-dd').format(d.toDate());
                  }
                  return d.toString();
                }).join(' - '); // عرض كل الأيام مفصولة بشرطة
              }

              // Fetch user data using userId
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(data['userId'])
                    .get(),
                builder: (context, userSnap) {
                  if (!userSnap.hasData) {
                    return const SizedBox();
                  }

                  final userData =
                  userSnap.data!.data() as Map<String, dynamic>?;

                  if (userData == null) {
                    return const SizedBox();
                  }

                  return Container(
                    margin: const EdgeInsets.only(bottom: 15),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Workshop Title
                        Text(
                          data['title'] ?? "Workshop".tr(),//
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF582C0A),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // User info row
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundImage: NetworkImage(
                                userData['profileImage'] ??
                                    "https://via.placeholder.com/150",
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    userData['name'] ?? "",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF582C0A),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.phone,
                                          size: 16, color: Color(0xFF582C0A)),
                                      const SizedBox(width: 6),
                                      Text(
                                        userData['phone'] ?? "",
                                        style: const TextStyle(
                                          color: Color(0xFF582C0A),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      const Icon(Icons.email,
                                          size: 16, color: Color(0xFF582C0A)),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          userData['email'] ?? "",
                                          style: const TextStyle(
                                            color: Color(0xFF582C0A),
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Reservation details
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.calendar_today, size: 18, color: Color(0xFF582C0A)),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    "${'Date:'.tr()} $formattedDates",
                                    style: const TextStyle(color: Color(0xFF582C0A)),
                                    softWrap: true,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.group,
                                    size: 18, color: Color(0xFF582C0A)),
                                const SizedBox(width: 6),
                                Text(
                                  "${'People:'.tr()} ${data['people']}",
                                  style:
                                  const TextStyle(color: Color(0xFF582C0A)),
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        Row(
                          children: [
                            const Icon(Icons.info_outline,
                                size: 18, color: Color(0xFF582C0A)),
                            const SizedBox(width: 6),
                            Text(
                              "${'Status:'.tr()} ${data['status']}",
                              style: const TextStyle(
                                color: Color(0xFF582C0A),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
