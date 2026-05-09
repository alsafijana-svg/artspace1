import 'dart:io';
import 'package:artspace1/pages/home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'map_picker_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:easy_localization/easy_localization.dart';

Future<void> initSupabase() async {
  await Supabase.initialize(
    url: 'https://davzycbloedfcemymacp.supabase.co', // من Settings → API
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRhdnp5Y2Jsb2VkZmNlbXltYWNwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjM1NzA0OTUsImV4cCI6MjA3OTE0NjQ5NX0.zuIzEc8pxKwrWe-UsvKFVwiEgqDZ3ThJ7kh9fQe4r8', // من نفس المكان
  );
}

final supabase = Supabase.instance.client;

class PlusPage extends StatefulWidget {
  const PlusPage({Key? key}) : super(key: key);

  @override
  State<PlusPage> createState() => _PlusPageState();
}

class _PlusPageState extends State<PlusPage> {
  final _formKey = GlobalKey<FormState>();
  String? selectedCity;
  // Controllers
  final name = TextEditingController();
  final desc = TextEditingController();
  final price = TextEditingController();
  final hours = TextEditingController();
  List<TextEditingController> facilityControllers = [TextEditingController()];

  List<File> images = [];
  LatLng? pickedLocation;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    signInAnonymously();
  }

  Future<void> signInAnonymously() async {
    try {
      await _auth.signInAnonymously();
      print("Signed in with UID: ${_auth.currentUser?.uid}");
    } catch (e) {
      print("Error signing in anonymously: $e");
    }
  }

  void showSuccessPopup() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        Future.delayed(const Duration(seconds: 2), () {
          Navigator.of(context).pop();
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => HomePage()),
          );
        });

        return const SuccessPopupWidget();
      },
    );
  }

  Future<void> submit() async {
    print("Form valid: ${_formKey.currentState!.validate()}");
    print("Picked location: $pickedLocation");
    print("Images count: ${images.length}");

    if (!_formKey.currentState!.validate() ||
        pickedLocation == null ||
        images.isEmpty) {
      String msg = "";
      if (!_formKey.currentState!.validate()) msg += "Form not valid. ";
      if (pickedLocation == null) msg += "Location not picked. ";
      if (images.isEmpty) msg += "No images selected.";
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      return;
    }

    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("User not authenticated.".tr())),
        );
        return;
      }

      // ----------- رفع الصور إلى Supabase Storage -----------
      List<String> urls = [];

      for (int i = 0; i < images.length; i++) {
        try {
          final img = images[i];
          final bytes = await img.readAsBytes();
          final fileName = '${DateTime.now().millisecondsSinceEpoch}_$i.jpg';

          // رفع الصورة للستوريج
          await supabase.storage.from('imagess').uploadBinary(
                fileName,
                bytes,
              );

          // جلب رابط التنزيل العام
          final String publicUrl =
              supabase.storage.from('imagess').getPublicUrl(fileName);

          urls.add(publicUrl);

          print('Uploaded image $i: $publicUrl');
        } catch (e) {
          print('Upload error for image $i: $e');
        }
      }

      if (urls.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text("Failed to upload images".tr())),
        );
        return;
      }

      List<String> facilities = facilityControllers
          .map((e) => e.text.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      Map<String, dynamic> workshopData = {
        "title": name.text.trim(),
        "description": desc.text.trim(),
        "city": selectedCity,
        "price": price.text.trim(),
        "openingHours": hours.text.trim(),
        "facilities": facilities,
        "images": urls,
        "location": {
          "lat": pickedLocation!.latitude,
          "lng": pickedLocation!.longitude,
        },
        "createdAt": Timestamp.now(),
        "userId": uid,
      };

      await FirebaseFirestore.instance
          .collection("user_workshops")
          .add(workshopData);

      showSuccessPopup();
    } catch (e) {
      print("Error in submit: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error".tr(args: [e.toString()]))),
      );
    }
  }

  InputDecoration input(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Color(0xFF582C0A), fontSize: 16),
      errorStyle: const TextStyle(
        color: Color(0xFF8B0000),
        fontWeight: FontWeight.normal,
        fontSize: 14,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: Color(0xFF895735), width: 1.2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(
          color: Colors.brown.withOpacity(0.4),
          width: 1.2,
        ),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(20)),
        borderSide: BorderSide(
          color: Color(0xFF895735),
          width: 2,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCF7F2),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              NameWidget(controller: name, input: input),
              const SizedBox(height: 16),
              DescriptionWidget(controller: desc, input: input),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedCity,
                decoration: input("City".tr()),
                dropdownColor: Color(0xFFFCF7F2),
                items: [
                  "Riyadh".tr(),
                  "Jeddah".tr(),
                  "Makkah".tr(),
                  "Madinah".tr(),
                  "Dammam".tr(),
                  "Taif".tr(),
                  "Abha".tr(),
                  "Tabuk".tr(),
                  "Najran".tr(),
                  "Hail".tr(),
                ]
                    .map((city) => DropdownMenuItem(
                          value: city,
                          child: Text(
                            city,
                            style: const TextStyle(color: Color(0xFFF582C0A)),
                          ),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    selectedCity = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "City is required".tr();
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              LocationPickerWidget(
                pickedLocation: pickedLocation,
                onPressed: () async {
                  LatLng? result = await Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const MapPickerPage()));
                  if (result != null) {
                    setState(() {
                      pickedLocation = result;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              PriceHoursWidget(
                price: price,
                hours: hours,
                input: input,
              ),
              const SizedBox(height: 16),
              FacilityWidget(
                controllers: facilityControllers,
                input: input,
                onAdd: () {
                  setState(() {
                    facilityControllers.add(TextEditingController());
                  });
                },
                onRemove: (i) {
                  setState(() {
                    facilityControllers.removeAt(i);
                  });
                },
              ),
              const SizedBox(height: 16),
              ImagePickerWidget(
                images: images,
                onPick: () async {
                  final pick = await ImagePicker().pickMultiImage();
                  if (pick == null) return;
                  if (images.length + pick.length > 10) return;

                  setState(() {
                    images.addAll(pick.map((e) => File(e.path)));
                  });
                },
              ),
              const SizedBox(height: 25),
              ElevatedButton(
                onPressed: submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF895735),
                  minimumSize: const Size(double.infinity, 55),
                ),
                child:  Text(
                  "Add Workshop".tr(),
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------- NAME WIDGET ----------------
class NameWidget extends StatelessWidget {
  final TextEditingController controller;
  final InputDecoration Function(String) input;

  const NameWidget({required this.controller, required this.input, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      cursorColor: Color(0xFF582C0A),
      controller: controller,
      decoration: input("Workshop Name".tr()),
      inputFormatters: [
        FilteringTextInputFormatter.deny(RegExp(r"\s{2,}")),
        TextInputFormatter.withFunction((oldValue, newValue) {
          final words = newValue.text.trim().split(" ");
          if (words.length > 3) return oldValue;
          return newValue;
        }),
      ],
      validator: (v) {
        if (v == null || v.trim().isEmpty) return "Required".tr();
        if (v.trim().split(" ").length > 3) return "Max 3 words only".tr();
        if (!RegExp(r"^[a-zA-Z\s]+$").hasMatch(v)) return "Letters only".tr();
        return null;
      },
    );
  }
}

// ---------------- DESCRIPTION WIDGET ----------------
class DescriptionWidget extends StatelessWidget {
  final TextEditingController controller;
  final InputDecoration Function(String) input;

  const DescriptionWidget(
      {required this.controller, required this.input, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      cursorColor: Color(0xFF582C0A),
      controller: controller,
      maxLines: 3,
      decoration: input("Description (Max 200 words)".tr()),
      inputFormatters: [
        TextInputFormatter.withFunction((oldValue, newValue) {
          final words = newValue.text.trim().split(" ");
          if (words.length > 200) return oldValue;
          return newValue;
        }),
      ],
      validator: (v) {
        if (v == null || v.trim().isEmpty) return "Required".tr();
        if (v.trim().split(" ").length > 200) return "Max 200 words";
        return null;
      },
    );
  }
}

// ---------------- LOCATION WIDGET ----------------
class LocationPickerWidget extends StatelessWidget {
  final LatLng? pickedLocation;
  final VoidCallback onPressed;

  const LocationPickerWidget({
    required this.pickedLocation,
    required this.onPressed,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF895735),
          ),
          child:  Text("Pick Workshop Location".tr(),
              style: TextStyle(color: Colors.white)),
        ),
        if (pickedLocation != null)
           Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text("Location selected ✔".tr(),
                style: TextStyle(color: Color(0xFF582C0A))),
          ),
      ],
    );
  }
}

// ---------------- PRICE + HOURS WIDGET ----------------
class PriceHoursWidget extends StatelessWidget {
  final TextEditingController price;
  final TextEditingController hours;
  final InputDecoration Function(String) input;

  const PriceHoursWidget({
    required this.price,
    required this.hours,
    required this.input,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // PRICE
        Expanded(
          child: TextFormField(
            cursorColor: Color(0xFF582C0A),
            controller: price,
            decoration: input("Price".tr()),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
            validator: (v) {
              if (v == null || v.trim().isEmpty) return "Required".tr();
              if (!RegExp(r"^[0-9]+$").hasMatch(v)) return "Numbers only".tr();
              return null;
            },
          ),
        ),
        const SizedBox(width: 12),
        // OPENING HOURS (TIME PICKER)
        Expanded(
          child: TextFormField(
            cursorColor: const Color(0xFF582C0A),
            controller: hours,
            decoration: input("Opening Hours".tr()),
            readOnly: true,
            onTap: () async {
              // اختيار وقت البداية
              final start = await showTimePicker(
                context: context,
                initialTime: const TimeOfDay(hour: 9, minute: 0),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.light(
                        primary: Color(0xFF895735), // لون الساعة المختارة
                        onPrimary: Colors.white, // لون النص داخل الدائرة
                        onSurface: Color(0xFFA87A5C), // لون الأرقام والخطوط
                        secondary: Color(0xFFDDB396),
                      ),
                      textButtonTheme: TextButtonThemeData(
                        style: TextButton.styleFrom(
                          foregroundColor:
                              const Color(0xFF895735), // لون أزرار Cancel & OK
                        ),
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (start == null) return;

              // اختيار وقت النهاية
              final end = await showTimePicker(
                context: context,
                initialTime: const TimeOfDay(hour: 17, minute: 0),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.light(
                        primary: Color(0xFF895735),
                        onPrimary: Colors.white,
                        onSurface: Color(0xFF582C0A),
                        secondary: Color(0xFFDDB396),
                      ),
                      textButtonTheme: TextButtonThemeData(
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF895735),
                        ),
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (end == null) return;

              final localizations = MaterialLocalizations.of(context);
              final startStr = localizations.formatTimeOfDay(start);
              final endStr = localizations.formatTimeOfDay(end);

              hours.text = "$startStr - $endStr";
            },
            validator: (v) {
              if (v == null || v.trim().isEmpty) return "Required".tr();
              return null;
            },
          ),
        ),
      ],
    );
  }
}

// ---------------- FACILITY LIST WIDGET ----------------
class FacilityWidget extends StatelessWidget {
  final List<TextEditingController> controllers;
  final InputDecoration Function(String) input;
  final VoidCallback onAdd;
  final Function(int) onRemove;

  const FacilityWidget({
    required this.controllers,
    required this.input,
    required this.onAdd,
    required this.onRemove,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ...controllers.asMap().entries.map((entry) {
          int i = entry.key;
          var controller = entry.value;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    cursorColor: Color(0xFF582C0A),
                    controller: controller,
                    decoration: input("Facility".tr()),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return "Required".tr();
                      if (!RegExp(r"^[a-zA-Z0-9\s]+$").hasMatch(v))
                        return "Letters & numbers only".tr();
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 10),
                if (controllers.length > 1)
                  IconButton(
                    icon: const Icon(Icons.remove_circle,
                        color: Color(0xFF895735)),
                    onPressed: () => onRemove(i),
                  ),
              ],
            ),
          );
        }).toList(),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add, color: Color(0xFF895735)),
            label:  Text("Add More".tr(),
                style: TextStyle(color: Color(0xFF895735))),
          ),
        ),
      ],
    );
  }
}

// ---------------- IMAGE PICKER WIDGET ----------------
class ImagePickerWidget extends StatelessWidget {
  final List<File> images; // الصور المحلية المختارة
  final List<String>?
      savedImageUrls; // ⭐ إضافة جديدة: قائمة الـ URLs المحفوظة في Firestore (من Supabase)
  final VoidCallback onPick;

  const ImagePickerWidget({
    required this.images,
    this.savedImageUrls, // اختياري، لعرض الصور المحفوظة
    required this.onPick,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // دمج الصور المحلية والمحفوظة (إذا كانت موجودة)
    List<Widget> imageWidgets = [];

    // إضافة الصور المحفوظة (من URLs) أولاً
    if (savedImageUrls != null) {
      for (String url in savedImageUrls!) {
        imageWidgets.add(
          Image.network(
            url, // ⭐ استخدام URL من Supabase (محفوظ في Firestore)
            width: 80,
            height: 80,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.error), // للتعامل مع أخطاء التحميل
          ),
        );
      }
    }

    // إضافة الصور المحلية المختارة
    for (File img in images) {
      imageWidgets.add(
        Image.file(
          img,
          width: 80,
          height: 80,
          fit: BoxFit.cover,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
         Text(
          "Images (1-10)".tr(),
          style: TextStyle(
            color: Color(0xFF582C0A),
            fontSize: 17,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          children: [
            ...imageWidgets, // ⭐ عرض جميع الصور (محفوظة + محلية)
            GestureDetector(
              onTap: onPick,
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  border: Border.all(color: Color(0xFF895735), width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.add_a_photo, color: Color(0xFF895735)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ---------------- SUCCESS POPUP WIDGET ----------------
class SuccessPopupWidget extends StatelessWidget {
  const SuccessPopupWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: const Color(0xFFECDBC9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 70, color: Color(0xFF8C5A3A)),
            SizedBox(height: 15),
            Text(
              "Workshop Added Successfully!".tr(),
              style: TextStyle(
                fontSize: 20,
                color: Color(0xFF5A2C0A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
