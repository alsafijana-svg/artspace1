import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:artspace1/pages/edit_my_workshop_page.dart';
import 'package:easy_localization/easy_localization.dart';

class MyWorkshopPage extends StatelessWidget {
  const MyWorkshopPage({super.key});

  @override
  Widget build(BuildContext context) {
    // جلب معرف المستخدم الحالي
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFFCF7F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFECDBC9),
        elevation: 2,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF582C0A)),
        title: Text(
          "My Workshops".tr(),
          style: TextStyle(
            color: Color(0xFF582C0A),
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(// استماع لتحديثات ورش العمل الخاصة بالمستخدم
        stream: FirebaseFirestore.instance
            .collection("user_workshops")
            .where("userId", isEqualTo: userId)// تصفية حسب معرف المستخدم الحالي
            .snapshots(),// جلب البيانات كتيار
        builder: (context, snapshot) {// بناء واجهة المستخدم بناءً على حالة التيار
          if (!snapshot.hasData) {// إذا لم تتوفر البيانات بعد
            return const Center(// عرض مؤشر تحميل
              child: CircularProgressIndicator(color: Color(0xFF895735)),// لون المؤشر
            );
          }

          final docs = snapshot.data!.docs; // جلب المستندات من البيانات

          if (docs.isEmpty) {// إذا لم يكن هناك ورش عمل
            return Center(
              child: Text(
                "No workshops added yet".tr(),// رسالة تفيد بعدم وجود ورش عمل
                style: TextStyle(color: Color(0xFF582C0A), fontSize: 16),
              ),
            );
          }

          return ListView.builder(// بناء قائمة ورش العمل
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,// عدد العناصر في القائمة
            itemBuilder: (context, index) {// بناء كل عنصر في القائمة
              final workshop = docs[index].data() as Map<String, dynamic>;// جلب بيانات ورشة العمل كمخطط بيانات
              final id = docs[index].id; // جلب معرف ورشة العمل

              return WorkshopItemCard(// عرض بطاقة ورشة العمل
                workshop: workshop,// بيانات ورشة العمل
                id: id, // معرف ورشة العمل
              );
            },
          );
        },
      ),
    );
  }
}


// workshop item widget

class WorkshopItemCard extends StatelessWidget {
  //variables
  final Map<String, dynamic> workshop; // بيانات ورشة العمل
  final String id; 

  const WorkshopItemCard({
    //constructor
    super.key,
    required this.workshop,
    required this.id,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDFC),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Row(
        children: [
          // Thumbnail image
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              workshop['images'][0],// عرض أول صورة كصورة مصغرة
              width: 80,
              height: 80,
              fit: BoxFit.cover,
            ),
          ),

          const SizedBox(width: 12),

          // Title + city
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,// محاذاة النص إلى اليسار
              children: [
                Text(
                  workshop['title'] ?? '',
                  style: const TextStyle(
                    color: Color(0xFF582C0A),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  workshop['city'] ?? '',
                  style: const TextStyle(
                    color: Color(0xFF895735),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // Edit Icon
          IconButton(
            icon: const Icon(Icons.edit, color: Color(0xFF895735)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      EditMyWorkshopPage(workshop: workshop, workshopId: id),// الانتقال إلى صفحة تعديل ورشة العمل مع تمرير البيانات والمعرف
                ),
              );
            },
          ),

          // Delete Icon
          IconButton(
            icon: const Icon(
              Icons.delete,
              color: Color.fromARGB(255, 150, 69, 64),
            ),
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => DeleteWorkshopDialog(id: id),
              );
            },
          ),
        ],
      ),
    );
  }
}

//Delete workshop dialog widget


class DeleteWorkshopDialog extends StatelessWidget {
  final String id;

  const DeleteWorkshopDialog({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFECDBC9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,// لتقليل حجم العمود حسب المحتوى
          children: [ // محتويات مربع الحوار
            Text(
              "Delete Workshop".tr(),
              style: TextStyle(
                color: Color(0xFF895735),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Are you sure you want to delete this workshop?".tr(),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF582C0A),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,// توزيع الأزرار بشكل متساوي
              children: [
                // Cancel
                TextButton(
                  onPressed: () => Navigator.pop(context),// إغلاق مربع الحوار
                  child: Text(
                    "Cancel".tr(),
                    style: TextStyle(
                      color: Color(0xFF895735),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                // Delete
                TextButton(
                  onPressed: () async {// حذف ورشة العمل من قاعدة البيانات
                    await FirebaseFirestore.instance
                        .collection("user_workshops")
                        .doc(id)
                        .delete();

                    Navigator.pop(context);// إغلاق مربع الحوار بعد الحذف
                  },
                  child: Text(
                    "Delete".tr(),
                    style: TextStyle(
                      color: Color(0xFF895735),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
