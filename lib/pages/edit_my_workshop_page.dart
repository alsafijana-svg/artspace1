import 'dart:io'; // gives access to file I/O
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // for image selection ues for allow user to pick image from gallery or camera
import 'package:latlong2/latlong.dart'; // for handling latitude and longitude coordinates
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:supabase_flutter/supabase_flutter.dart';// for supabase integration
import 'map_picker_page.dart'; //allows user to pick location on map
import 'package:easy_localization/easy_localization.dart';

/// Page for editing an existing workshop
class EditMyWorkshopPage extends StatefulWidget {
  //Variables
  //final يعني ان القيمة لا تتغير بعد التهيئة
  final String workshopId; // ID of the workshop to edit

  final Map<String, dynamic> workshop; // Current workshop data

  const EditMyWorkshopPage({
     //Constructor
    super.key,
    required this.workshopId,
    required this.workshop,
  });

  @override
  State<EditMyWorkshopPage> createState() => _EditMyWorkshopPageState();
}

class _EditMyWorkshopPageState extends State<EditMyWorkshopPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  late TextEditingController name;
  late TextEditingController desc;
  late TextEditingController price;
  late TextEditingController hours;

  // Facilities
  List<TextEditingController> facilityControllers = [];

  // City
  String? selectedCity;

  // Location
  LatLng? pickedLocation;
  bool locationError = false;

  // Images
  List<String> savedImageUrls = [];
  List<File> newImages = [];
  bool imagesError = false;

  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
// Initialize controllers with existing workshop data
    name = TextEditingController(text: widget.workshop["title"]);
    desc = TextEditingController(text: widget.workshop["description"]);
    price = TextEditingController(text: widget.workshop["price"]);
    hours = TextEditingController(text: widget.workshop["openingHours"]);
    selectedCity = widget.workshop["city"];

    // Facilities
    List facilities = widget.workshop["facilities"] ?? [];
    // إنشاء متحكم نصي لكل مرفق
    for (var f in facilities) {
      facilityControllers.add(TextEditingController(text: f));
    }
    //f none — add one empty controller
    if (facilityControllers.isEmpty) {
      facilityControllers.add(TextEditingController());
    }

    // Location
    final loc = widget.workshop["location"];
    pickedLocation = LatLng(loc["lat"], loc["lng"]);

    // Images
    savedImageUrls = List<String>.from(widget.workshop["images"]);
  }

  InputDecoration input(String label) {
    return InputDecoration(
      //Styling for input fields
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
        borderSide:
        BorderSide(color: Colors.brown.withOpacity(0.4), width: 1.2),
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

  Future<void> updateWorkshop() async {
    print("==== Update pressed ====");
    // Validate form fields
    final formValid = _formKey.currentState!.validate();
     // Validate location and images
    final hasLocation = pickedLocation != null;
    final hasImages =
        savedImageUrls.isNotEmpty || newImages.isNotEmpty;

    setState(() {
      // Update error states
      locationError = !hasLocation;
      imagesError = !hasImages;
    });
    // Debug prints
    print("formValid: $formValid, hasLocation: $hasLocation, hasImages: $hasImages");
        // If any validation fails, do not proceed
    if (!formValid || !hasLocation || !hasImages) {
      // يوجد أخطاء، لا نكمّل التحديث
      //print("Validation failed, not updating.");
      return;
    }

    try {
      // رفع الصور الجديدة فقط
      //Upload only new images
      List<String> newUrls = [];

      for (int i = 0; i < newImages.length; i++) {
        //read each image as bytes
        //construct a unique filename
        final img = newImages[i];
        final bytes = await img.readAsBytes();
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
           // upload to supabase storage
        await supabase.storage.from('imagess').uploadBinary(
          fileName,
          bytes,
        );
     // get public URL
        final url = supabase.storage.from('imagess').getPublicUrl(fileName);
        newUrls.add(url);
        print("Uploaded new image $i: $url");
      }

      // الصور النهائية = القديمة (بعد الحذف إن وجد) + الجديدة
      List<String> finalImages = [...savedImageUrls, ...newUrls];

      // Facilities
      List<String> facilities = facilityControllers
      //Build a map updated containing updated workshop fields
          .map((c) => c.text.trim())
          .where((t) => t.isNotEmpty)
          .toList();

      Map<String, dynamic> updated = {
        "title": name.text.trim(),
        "description": desc.text.trim(),
        "city": selectedCity,
        "price": price.text.trim(),
        "openingHours": hours.text.trim(),
        "facilities": facilities,
        "images": finalImages,
        "location": {
          "lat": pickedLocation!.latitude,
          "lng": pickedLocation!.longitude,
        },
        "updatedAt": Timestamp.now(),
      };
      // Update Firestore document
      await FirebaseFirestore.instance
          .collection("user_workshops")
          .doc(widget.workshopId)
          .update(updated);

      // Popup نجاح
      showDialog(
        context: context,
        barrierDismissible: false,
        //Navigate to success popup
        builder: (_) => const UpdateSuccessPopup(),
      );

      Future.delayed(const Duration(seconds: 2), () {
        // Close popup and return to previous page
        Navigator.pop(context); // يغلق البوب أب
        Navigator.pop(context); // يرجع لصفحة قبله
      });
    } catch (e) {
      // Handle errors during update
      print("Update error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text( 'error_updating_workshop'.tr(args: [e.toString()]))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Build the edit workshop page UI
    return Scaffold(
      backgroundColor: const Color(0xFFFCF7F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFECDBC9),
        elevation: 2,
        centerTitle: true,
        title: Text(
          "Edit Workshop".tr(),
          style: TextStyle(
            color: Color(0xFF582C0A),
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
      ),
      //allow scrolling if the form is long
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(// widget with _formKey
          key: _formKey,// form key for validation
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Workshop name input field
              TextFormField(
                controller: name,
                decoration: input("Workshop Name".tr()),
                cursorColor: const Color(0xFF582C0A),
                //validation
                validator: (v) => v!.isEmpty ? "Required".tr(): null,
              ),
              const SizedBox(height: 16),

              // DESCRIPTION
              TextFormField(
                controller: desc,
                maxLines: 3,
                decoration: input("Description".tr()),
                cursorColor: const Color(0xFF582C0A),
                //validation
                validator: (v) => v!.isEmpty ? "Required".tr() : null,
              ),
              const SizedBox(height: 16),

              // CITY
              //Dropdown uses same input decoration style
              DropdownButtonFormField<String>(
                dropdownColor: const Color(0xFFFCF7F2),
                value: selectedCity,
                decoration: input("City".tr()),
                items: [
                  "Riyadh",
                  "Jeddah",
                  "Makkah",
                  "Madinah",
                  "Dammam",
                  "Taif",
                  "Abha",
                  "Tabuk",
                  "Najran",
                  "Hail",
                ]
                    .map((city) => DropdownMenuItem(
                  value: city,
                  child: Text(
                    city,
                    style: const TextStyle(
                      color: Color(0xFF582C0A),
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                ))
                    .toList(),
                onChanged: (v) => setState(() => selectedCity = v),
              ),
              const SizedBox(height: 16),

              // LOCATION
              ElevatedButton(
                onPressed: () async {
                  LatLng? result = await Navigator.push(
                    context,
                    //If user tries to submit without location, error message appears.
                    MaterialPageRoute(
                      builder: (_) => const MapPickerPage(),
                    ),
                  );
                  // If a location was picked, update state
                  if (result != null) {
                    setState(() {
                      pickedLocation = result;
                      locationError = false;
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF895735),
                ),
                child:  Text(
                  "Pick Workshop Location".tr(),
                  style: TextStyle(color: Colors.white),
                ),
              ),

              if (pickedLocation != null)//if not empty 
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    "Location selected ✔",
                    style: TextStyle(color: Color(0xFF582C0A)),
                  ),
                ),

              if (locationError)
                Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Text(
                    "Location is required".tr(),
                    style: TextStyle(
                      color: Color(0xFF8B0000),
                      fontSize: 14,
                    ),
                  ),
                ),

              const SizedBox(height: 16),

              // PRICE + HOURS
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: price,
                      keyboardType: TextInputType.number,
                      decoration: input("Price".tr()),
                      cursorColor: const Color(0xFF582C0A),
                      //validation
                      validator: (v) => v!.isEmpty ? "Required".tr() : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: hours,
                      readOnly: true,
                      decoration: input("Opening Hours".tr()),
                      cursorColor: const Color(0xFF582C0A),
                      onTap: () {
                        // لو حابة تضيفي TimePicker هنا مثل صفحة الإضافة
                      },
                      //validation
                      validator: (v) => v!.isEmpty ? "Required".tr() : null,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),//Spacing 

              // FACILITIES
              Column(
                // Generate input fields for each facility
                children: facilityControllers.asMap().entries.map((entry) {
                  int i = entry.key;
                  var controller = entry.value;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Expanded(// to take available width
                        // Facility input field
                          child: TextFormField(
                            controller: controller,
                            decoration: input("Facility".tr()),
                            cursorColor: const Color(0xFF582C0A),
                            //validation
                            validator: (v) =>
                            v!.isEmpty ? "Required".tr() : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (facilityControllers.length > 1)
                          IconButton(
                            icon: const Icon(
                              Icons.remove_circle,
                              color: Color(0xFF895735),
                            ),
                            onPressed: () {
                              setState(() {
                                // Remove this facility controller
                                facilityControllers.removeAt(i);
                              });
                            },
                          ),
                      ],
                    ),
                  );
                }).toList(),// end of map
              ),

              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () {
                    setState(() {
                      facilityControllers.add(TextEditingController());
                    });
                  },
                  icon: const Icon(Icons.add, color: Color(0xFF895735)),
                  label: Text(//new facility button
                    "Add More".tr(),
                    style: TextStyle(color: Color(0xFF895735)),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // IMAGES
               Text(
                "Images".tr(),
                style: TextStyle(
                  color: Color(0xFF582C0A),
                  fontSize: 17,
                ),
              ),
              const SizedBox(height: 10),

              Wrap(
                spacing: 10,// horizontal spacing between images
                runSpacing: 10,// vertical spacing between lines
                children: [
                  // الصور المحفوظة
                  ...savedImageUrls.map((url) {
                    return Stack(
                      children: [
                        Image.network(// display saved image from
                          url,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                        Positioned(
                          //position close button at top right
                          right: 0,
                          top: 0,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                // Remove image URL from saved list
                                savedImageUrls.remove(url);
                                imagesError =
                                    savedImageUrls.isEmpty &&
                                        newImages.isEmpty;
                              });
                            },
                            child: const CircleAvatar(// circular background for close icon
                              radius: 12,
                              backgroundColor: Colors.red,
                              child: Icon(
                                Icons.close,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),

                  // الصور الجديدة
                  ...newImages.map((img) {
                    return Image.file(
                      img,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    );
                  }).toList(),

                  // زر إضافة صورة
                  GestureDetector(
                    onTap: () async {
                      final picked =
                      await ImagePicker().pickMultiImage();// allow multiple image selection
                      if (picked == null) return;

                      setState(() {
                        newImages
                            .addAll(picked.map((e) => File(e.path)));// add selected images to newImages list
                        imagesError =
                        savedImageUrls.isEmpty &&
                            newImages.isEmpty
                            ? true
                            : false;
                      });
                    },
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: const Color(0xFF895735),
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.add_a_photo,
                        color: Color(0xFF895735),
                      ),
                    ),
                  ),
                ],
              ),

              if (imagesError)
                Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Text(
                    "At least one image is required".tr(),
                    style: TextStyle(
                      color: Color(0xFF8B0000),
                      fontSize: 14,
                    ),
                  ),
                ),

              const SizedBox(height: 30),

              // UPDATE BUTTON
              ElevatedButton(
                onPressed: updateWorkshop, // call update function
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF895735),
                  minimumSize: const Size(double.infinity, 55),
                ),
                child: Text(
                  "Update Workshop".tr(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
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

class UpdateSuccessPopup extends StatelessWidget {
  const UpdateSuccessPopup({super.key});

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
          children: [
            Icon(
              Icons.check_circle,
              size: 70,
              color: Color(0xFF8C5A3A),
            ),
            SizedBox(height: 15),
            Text(
              "Workshop Updated Successfully!".tr(),
              style: TextStyle(
                fontSize: 20,
                color: Color(0xFF5A2C0A),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}