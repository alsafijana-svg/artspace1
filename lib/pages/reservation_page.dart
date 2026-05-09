import 'package:artspace1/pages/cancel_reservation_page.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:artspace1/pages/view_reservation_page.dart';
import 'package:firebase_auth/firebase_auth.dart';


class ReservationPage extends StatelessWidget {
  const ReservationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCF7F2),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Center(
              child: Column(
                children: [
                  // ─── View Reservation Card ──────────────────────
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.15),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        leading: const Icon(Icons.menu_rounded,
                            color: Color(0xFF582C0A), size: 28),
                        title: Text(
                          "View Reservation".tr(),
                          style: const TextStyle(
                            color: Color(0xFF582C0A),
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios,
                            color: Color(0xFF895735), size: 26),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => ViewReservationsPage(
                                    userId: FirebaseAuth
                                        .instance.currentUser?.uid ??
                                        '')),
                          );
                        }),
                  ),

                  const SizedBox(height: 20),

                  // ─── Cancel Reservation Card ─────────────────────
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.15),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        leading: const Icon(Icons.cancel_outlined,
                            color: Color(0xFF582C0A), size: 28),
                        title: Text(
                          "Cancel Reservation".tr(),
                          style: const TextStyle(
                            color: Color(0xFF582C0A),
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        trailing: const Icon(Icons.chevron_right,
                            color: Color(0xFF895735), size: 26),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => CancelReservationsPage(
                                    userId: FirebaseAuth
                                        .instance.currentUser?.uid ??
                                        '')),
                          );
                        }),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
