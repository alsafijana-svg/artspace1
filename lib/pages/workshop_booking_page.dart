import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'payment_page.dart';

class WorkshopBookingPage extends StatefulWidget {
  final String title; // Workshop title
  const WorkshopBookingPage({super.key, required this.title});

  @override
  State<WorkshopBookingPage> createState() => _WorkshopBookingPageState();
}

class _WorkshopBookingPageState extends State<WorkshopBookingPage> {
  Set<DateTime> selectedDates = {};
  int guests = 1;
  bool showDateError = false;
  bool showGuestError = false;
  bool showConflictError = false;
  bool isChecking = false;
  bool isLoading = true;

  Set<DateTime> unavailableDates = {};
  final now = DateTime.now();

  // ===================== 1) تحميل الأيام المحجوزة لنفس الورشة فقط =====================
  Future<void> _loadBookedDates() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('reservations')
          .where('title', isEqualTo: widget.title) // <-- مهم: حسب اسم الورشة
          .get();

      Set<DateTime> booked = {};
      for (var doc in snapshot.docs) {
        final data = doc.data();

        // لو عندنا قائمة تواريخ 'dates'
        if (data['dates'] is List) {
          for (var d in (data['dates'] as List)) {
            DateTime? bookedDate;
            if (d is Timestamp) {
              bookedDate = d.toDate();
            } else if (d is String) {
              bookedDate = DateTime.tryParse(d);
            }
            if (bookedDate != null) {
              booked.add(DateTime(
                  bookedDate.year, bookedDate.month, bookedDate.day));
            }
          }
        } else {
          // لو الحقل القديم 'date' فقط
          DateTime? bookedDate;
          if (data['date'] is Timestamp) {
            bookedDate = (data['date'] as Timestamp).toDate();
          } else if (data['date'] is String) {
            bookedDate = DateTime.tryParse(data['date']);
          }
          if (bookedDate != null) {
            booked.add(DateTime(
                bookedDate.year, bookedDate.month, bookedDate.day));
          }
        }
      }

      setState(() {
        unavailableDates = booked;
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Error loading booked dates: $e");
      setState(() => isLoading = false);
    }
  }

  // ===================== 2) تأكيد الحجز مع أكثر من يوم =====================
  Future<void> _confirmBooking() async {
    setState(() {
      showDateError = selectedDates.isEmpty;
      showGuestError = guests <= 0;
      showConflictError = false;
    });

    if (selectedDates.isEmpty || guests <= 0) return;

    // نطبّع التواريخ المختارة (بدون وقت) ونرتبها
    final normalizedSelected = selectedDates
        .map((d) => DateTime(d.year, d.month, d.day))
        .toList()
      ..sort();

    // نتأكد أنه مافي تعارض مع الأيام المحجوزة لنفس الورشة
    bool conflict = normalizedSelected
        .any((d) => unavailableDates.contains(d));

    if (conflict) {
      setState(() {
        showConflictError = true;
      });
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please login first!")),
      );
      return;
    }

    setState(() => isChecking = true);

    try {
      // نحول كل الأيام إلى Timestamps
      final datesList = normalizedSelected
          .map((d) => Timestamp.fromDate(d))
          .toList();

      // نستخدم أول يوم في الحقل القديم 'date' عشان باقي الصفحات تشتغل
      final firstDateTs = datesList.first;

      final reservationRef =
      await FirebaseFirestore.instance.collection('reservations').add({
        'userId': user.uid,
        'title': widget.title,
        'date': firstDateTs,          // أول يوم (للصفحات القديمة)
        'dates': datesList,          // كل الأيام المحجوزة
        'people': guests,
        'status': 'Pending Payment',
        'createdAt': Timestamp.now(),
      });

      setState(() => isChecking = false);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentPage(
            userId: user.uid,
            reservationId: reservationRef.id,
          ),
        ),
      );
    } catch (e) {
      setState(() => isChecking = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Booking failed:".tr() + " $e")),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _loadBookedDates();
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime(now.year, now.month, now.day);

    return Scaffold(
      backgroundColor: const Color(0xFFFCF7F2),
      appBar: AppBar(
        title: Text(
          "Workshop Booking".tr(),
          style: const TextStyle(
            color: Color(0xFF582C0A),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFFECDBC9),
        centerTitle: true,
        elevation: 2,
        shadowColor: Colors.grey.withOpacity(0.5),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Choose date".tr(),
                style: const TextStyle(
                  color: Color(0xFF582C0A),
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFDFC),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: TableCalendar(
                  firstDay: today,
                  lastDay: DateTime(today.year + 2),
                  focusedDay: today,
                  availableCalendarFormats: const {
                    CalendarFormat.month: 'Month'
                  },
                  selectedDayPredicate: (day) {
                    return selectedDates.any((d) =>
                    d.year == day.year &&
                        d.month == day.month &&
                        d.day == day.day);
                  },
                  enabledDayPredicate: (day) {
                    final normalized =
                    DateTime(day.year, day.month, day.day);
                    return !unavailableDates.contains(normalized);
                  },
                  // ===================== 3) اختيار أكثر من يوم =====================
                  onDaySelected: (selected, focused) {
                    final normalized = DateTime(
                        selected.year, selected.month, selected.day);
                    if (normalized.isBefore(today)) return;

                    setState(() {
                      if (selectedDates.contains(normalized)) {
                        // لو اليوم مختار من قبل نحذفه
                        selectedDates.remove(normalized);
                      } else {
                        // نضيفه بدون مسح الأيام السابقة
                        selectedDates.add(normalized);
                      }
                      showDateError = false;
                      showConflictError = false;
                    });
                  },
                  headerStyle: const HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                    titleTextStyle: TextStyle(
                      color: Color(0xFF582C0A),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  calendarStyle: CalendarStyle(
                    todayDecoration: const BoxDecoration(
                      color: Color(0xFFECDBC9),
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: const BoxDecoration(
                      color: Color(0xFF895735),
                      shape: BoxShape.circle,
                    ),
                    selectedTextStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    defaultTextStyle:
                    const TextStyle(color: Color(0xFF582C0A)),
                    weekendTextStyle:
                    const TextStyle(color: Color(0xFF895735)),
                    disabledTextStyle: TextStyle(
                      color: Colors.grey.shade400,
                    ),
                  ),
                ),
              ),
              if (showDateError)
                 Padding(
                  padding: EdgeInsets.only(top: 6, left: 8),
                  child: Text(
                    "Please select at least one date".tr(),
                    style: TextStyle(color: Color(0xFFB3261E), fontSize: 14),
                  ),
                ),
              if (showConflictError)
                 Padding(
                  padding: EdgeInsets.only(top: 6, left: 8),
                  child: Text(
                    "One or more selected dates are already booked".tr(),
                    style: TextStyle(color: Color(0xFFB3261E), fontSize: 14),
                  ),
                ),
              const SizedBox(height: 20),
              const Divider(thickness: 1, color: Color(0xFFEDE5DD)),
              const SizedBox(height: 12),
              Text(
                "Number of guests".tr(),
                style: const TextStyle(
                  color: Color(0xFF582C0A),
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFDFC),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed:
                      guests > 1 ? () => setState(() => guests--) : null,
                      icon: const Icon(Icons.remove),
                      color: const Color(0xFF582C0A),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          guests.toString(),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF582C0A),
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => setState(() {
                        guests++;
                        showGuestError = false;
                      }),
                      icon: const Icon(Icons.add),
                      color: const Color(0xFF582C0A),
                    ),
                  ],
                ),
              ),
              if (showGuestError)
                 Padding(
                  padding: EdgeInsets.only(top: 6, left: 8),
                  child: Text(
                    "Please select number of guests".tr(),
                    style: TextStyle(color: Color(0xFFB3261E), fontSize: 14),
                  ),
                ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7EF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFECDBC9)),
                ),
                child: Text(
                  "Cancellation must be done before the booking date".tr(),
                  style: const TextStyle(
                    color: Color(0xFF895735),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF895735),
                    foregroundColor: const Color(0xFFF4F0E7),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 2,
                  ),
                  onPressed: isChecking ? null : _confirmBooking,
                  child: isChecking
                      ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      :  Text(
                    "Continue".tr(),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

