import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditUserProfileScreen extends StatefulWidget {
  String name ;
   EditUserProfileScreen({super.key,required this.name});

  @override
  State<EditUserProfileScreen> createState() => _EditUserProfileScreenState();
}

class _EditUserProfileScreenState extends State<EditUserProfileScreen> {
  final supabase = Supabase.instance.client;
  final ImagePicker picker = ImagePicker();

  final nameController = TextEditingController();
  final emailController = TextEditingController();

  File? profileImage;
  String profileImageUrl = '';

  bool isLoading = false;

  static const String bucketName = 'image';

  @override
  void initState() {
    super.initState();
    loadUser();
  }

  Future<void> loadUser() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    emailController.text = user.email ?? '';

    try {
      final data = await supabase
          .from('users') // table name
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (data != null) {
        setState(() {
          nameController.text = data['name'] ?? '';
          profileImageUrl = data['IMAGE'] ?? '';
        });
      }
    } catch (e) {
      debugPrint("Load User Error: $e");
    }
  }

  Future<void> pickImage() async {
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (image != null) {
      setState(() {
        profileImage = File(image.path);
      });
    }
  }

  Future<String?> uploadProfileImage(String userId) async {
    if (profileImage == null) return profileImageUrl;

    final fileName =
        "profile/$userId/${DateTime.now().millisecondsSinceEpoch}.jpg";

    await supabase.storage.from(bucketName).upload(
          fileName,
          profileImage!,
          fileOptions: const FileOptions(upsert: true),
        );

    return supabase.storage.from(bucketName).getPublicUrl(fileName);
  }

  Future<void> updateProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    if (nameController.text.trim().isEmpty) {
      showMsg("Enter name");
      return;
    }

    try {
      setState(() => isLoading = true);

      final uploadedUrl = await uploadProfileImage(user.id);

      await supabase.from('users').upsert({
        'id': user.id,
        'name': nameController.text.trim(),
        'email': emailController.text.trim(),
        'IMAGE': uploadedUrl,
      });

      if (!mounted) return;

      showMsg("Profile updated successfully");
      Navigator.pop(context, true);
    } catch (e) {
      showMsg("Error: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void showMsg(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  Widget profileImagePicker() {
    return Center(
      child: GestureDetector(
        onTap: pickImage,
        child: Stack(
          children: [
            CircleAvatar(
              radius: 58,
              backgroundColor: const Color(0xFF111827),
              backgroundImage: profileImage != null
                  ? FileImage(profileImage!)
                  : profileImageUrl.isNotEmpty
                      ? NetworkImage(profileImageUrl)
                      : null,
              child: profileImage == null && profileImageUrl.isEmpty
                  ? const Icon(
                      Icons.person,
                      size: 55,
                      color: Colors.white70,
                    )
                  : null,
            ),
            Positioned(
              bottom: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFFFF5A1F),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    bool readOnly = false,
  }) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.white70),
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: const Color(0xFF111827),
        border: OutlineInputBorder(
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
        title: const Text("Edit Profile"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            profileImagePicker(),
            const SizedBox(height: 30),
            buildField(
              label: "Name",
              controller: nameController,
              icon: Icons.person_outline,
            ),
            const SizedBox(height: 16),
            buildField(
              label: "Email",
              controller: emailController,
              icon: Icons.email_outlined,
              readOnly: true,
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: isLoading ? null : updateProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF5A1F),
                  disabledBackgroundColor: Colors.grey,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Update Profile",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}