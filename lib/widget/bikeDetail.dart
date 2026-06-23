import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddBikeScreen extends StatefulWidget {
  const AddBikeScreen({super.key});

  @override
  State<AddBikeScreen> createState() => _AddBikeScreenState();
}

class _AddBikeScreenState extends State<AddBikeScreen> {
  final supabase = Supabase.instance.client;
  final ImagePicker picker = ImagePicker();

  File? bikeImage;
  String? bikeImageUrl;

  final bikeNameController = TextEditingController();
  final brandController = TextEditingController();
  final modelController = TextEditingController();
  final regNoController = TextEditingController();
  final purchaseDateController = TextEditingController();
  final kmController = TextEditingController();

  bool isLoading = false;
  bool isEdit = false;

  static const String bucketName = 'image';

  @override
  void initState() {
    super.initState();
    loadBike();
  }

  @override
  void dispose() {
    bikeNameController.dispose();
    brandController.dispose();
    modelController.dispose();
    regNoController.dispose();
    purchaseDateController.dispose();
    kmController.dispose();
    super.dispose();
  }

  Future<void> loadBike() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final data = await supabase
          .from('bikes')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();

      if (data == null) return;

      final url = data['image_url']?.toString();

      setState(() {
        isEdit = true;
        bikeNameController.text = data['bike_name'] ?? '';
        brandController.text = data['brand'] ?? '';
        modelController.text = data['model'] ?? '';
        regNoController.text = data['registration_no'] ?? '';
        purchaseDateController.text = data['purchase_date'] ?? '';
        kmController.text = data['current_km']?.toString() ?? '';

        if (url != null &&
            url.isNotEmpty &&
            !url.contains('/public/images/')) {
          bikeImageUrl = url;
        } else {
          bikeImageUrl = null;
        }
      });
    } catch (e) {
      debugPrint("Load Bike Error: $e");
    }
  }

  Future<void> pickImage() async {
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (image != null) {
      setState(() {
        bikeImage = File(image.path);
      });
    }
  }

  Future<void> pickDate() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime(1990),
      lastDate: DateTime.now(),
      initialDate: DateTime.now(),
    );

    if (date != null) {
      purchaseDateController.text =
          "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    }
  }

  Future<String?> uploadBikeImage(String userId) async {
    if (bikeImage == null) return bikeImageUrl;

    final fileName =
        "bikes/$userId/${DateTime.now().millisecondsSinceEpoch}.jpg";

    await supabase.storage.from(bucketName).upload(
          fileName,
          bikeImage!,
          fileOptions: const FileOptions(
            cacheControl: '3600',
            upsert: true,
          ),
        );

    final imageUrl = supabase.storage.from(bucketName).getPublicUrl(fileName);

    debugPrint("IMAGE URL: $imageUrl");

    return imageUrl;
  }

  Future<void> saveBike() async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      showMsg("User not logged in");
      return;
    }

    if (bikeNameController.text.trim().isEmpty ||
        brandController.text.trim().isEmpty ||
        modelController.text.trim().isEmpty ||
        regNoController.text.trim().isEmpty ||
        purchaseDateController.text.trim().isEmpty ||
        kmController.text.trim().isEmpty) {
      showMsg("Please fill all fields");
      return;
    }

    try {
      setState(() => isLoading = true);

      final uploadedImageUrl = await uploadBikeImage(user.id);

      final bikeData = {
        'bike_name': bikeNameController.text.trim(),
        'brand': brandController.text.trim(),
        'model': modelController.text.trim(),
        'registration_no': regNoController.text.trim(),
        'purchase_date': purchaseDateController.text.trim(),
        'current_km': int.tryParse(kmController.text.trim()) ?? 0,
        'image_url': uploadedImageUrl,
      };

      if (isEdit) {
        await supabase.from('bikes').update(bikeData).eq('user_id', user.id);
      } else {
        await supabase.from('bikes').insert({
          'user_id': user.id,
          ...bikeData,
        });
      }

      if (!mounted) return;

      showMsg(isEdit ? "Bike Updated Successfully" : "Bike Added Successfully");

      Navigator.pop(context, true);
    } catch (e) {
      showMsg("Error: $e");
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void showMsg(String msg) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  Widget buildBikeImagePicker() {
    return GestureDetector(
      onTap: pickImage,
      child: Container(
        height: 190,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFF111827),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFFF5A1F), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: bikeImage != null
              ? Image.file(
                  bikeImage!,
                  width: double.infinity,
                  height: 190,
                  fit: BoxFit.cover,
                )
              : bikeImageUrl != null && bikeImageUrl!.isNotEmpty
                  ? Image.network(
                      bikeImageUrl!,
                      width: double.infinity,
                      height: 190,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFFFF5A1F),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return buildImagePlaceholder(
                          title: "Image load failed",
                          subtitle: "Tap to select new image",
                          icon: Icons.broken_image_rounded,
                        );
                      },
                    )
                  : buildImagePlaceholder(
                      title: "Select Bike Image",
                      subtitle: "Tap to upload from gallery",
                      icon: Icons.add_a_photo_rounded,
                    ),
        ),
      ),
    );
  }

  Widget buildImagePlaceholder({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: 48,
          color: const Color(0xFFFF5A1F),
        ),
        const SizedBox(height: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          subtitle,
          style: const TextStyle(color: Colors.white60),
        ),
      ],
    );
  }

  Widget buildField(
    String label,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
    VoidCallback? onTap,
    IconData? icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        readOnly: readOnly,
        onTap: onTap,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70),
          suffixIcon: icon != null ? Icon(icon, color: Colors.white70) : null,
          filled: true,
          fillColor: const Color(0xFF111827),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: Color(0xFFFF5A1F),
              width: 1.2,
            ),
          ),
        ),
      ),
    );
  }

  Widget buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: isLoading ? null : saveBike,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF5A1F),
          disabledBackgroundColor: Colors.grey,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Text(
                isEdit ? "Update Bike" : "Save Bike",
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070B14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF070B14),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(isEdit ? "Update Bike" : "Add Bike"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            buildBikeImagePicker(),
            const SizedBox(height: 22),
            buildField("Bike Name", bikeNameController),
            buildField("Brand", brandController),
            buildField("Model", modelController),
            buildField("Registration Number", regNoController),
            buildField(
              "Purchase Date",
              purchaseDateController,
              readOnly: true,
              onTap: pickDate,
              icon: Icons.calendar_month,
            ),
            buildField(
              "Current KM",
              kmController,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            buildSaveButton(),
          ],
        ),
      ),
    );
  }
}