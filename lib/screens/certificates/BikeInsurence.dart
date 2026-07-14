import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BikeInsurancePage extends StatefulWidget {
  const BikeInsurancePage({super.key});

  @override
  State<BikeInsurancePage> createState() => _BikeInsurancePageState();
}

class _BikeInsurancePageState extends State<BikeInsurancePage> {
  static const Color primaryColor = Color(0xFFFF5A1F);
  static const Color backgroundColor = Color(0xFFF7F8FA);
  static const String bucketName = 'bike-documents';

  final SupabaseClient supabase = Supabase.instance.client;
  final ImagePicker imagePicker = ImagePicker();

  final TextEditingController policyNumberController =
      TextEditingController();

  final TextEditingController companyController =
      TextEditingController();

  final TextEditingController policyTypeController =
      TextEditingController();

  final TextEditingController premiumController =
      TextEditingController();

  File? insuranceFrontImage;
  File? insuranceBackImage;

  DateTime? startDate;
  DateTime? expiryDate;

  String? bikeId;
  String? insuranceRecordId;

  String? frontImagePath;
  String? backImagePath;

  String? frontSignedUrl;
  String? backSignedUrl;

  bool loading = true;
  bool saving = false;
  bool deleting = false;

  bool get hasSavedInsurance => insuranceRecordId != null;

  bool get hasAnyData {
    return hasSavedInsurance ||
        insuranceFrontImage != null ||
        insuranceBackImage != null ||
        policyNumberController.text.trim().isNotEmpty;
  }

  @override
  void initState() {
    super.initState();
    initialisePage();
  }

  @override
  void dispose() {
    policyNumberController.dispose();
    companyController.dispose();
    policyTypeController.dispose();
    premiumController.dispose();
    super.dispose();
  }

  Future<void> initialisePage() async {
    try {
      setState(() => loading = true);

      final user = supabase.auth.currentUser;

      if (user == null) {
        throw Exception('Please login first.');
      }

      final bike = await getCurrentBike();

      if (bike == null) {
        throw Exception(
          'Bike details not found. Please add your bike first.',
        );
      }

      bikeId = bike['id'].toString();

      await loadInsurance();
    } catch (error) {
      if (!mounted) return;

      showMessage(
        cleanError(error),
        success: false,
      );
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  Future<Map<String, dynamic>?> getCurrentBike() async {
    final user = supabase.auth.currentUser;

    if (user == null) return null;

    final List<Map<String, dynamic>> bikes = await supabase
        .from('bikes')
        .select('id')
        .eq('user_id', user.id)
        .limit(1);

    if (bikes.isEmpty) return null;

    return bikes.first;
  }

  Future<void> loadInsurance() async {
    final user = supabase.auth.currentUser;

    if (user == null || bikeId == null) return;

    final Map<String, dynamic>? data = await supabase
        .from('bike_insurance')
        .select()
        .eq('user_id', user.id)
        .eq('bike_id', bikeId!)
        .maybeSingle();

    if (data == null) {
      clearLocalValues();

      if (mounted) {
        setState(() {});
      }
      return;
    }

    insuranceRecordId = data['id']?.toString();

    policyNumberController.text =
        data['policy_number']?.toString() ?? '';

    companyController.text =
        data['insurance_company']?.toString() ?? '';

    policyTypeController.text =
        data['policy_type']?.toString() ?? '';

    premiumController.text =
        data['premium_amount']?.toString() ?? '';

    startDate = parseDate(data['start_date']);
    expiryDate = parseDate(data['expiry_date']);

    frontImagePath = data['front_image_path']?.toString();
    backImagePath = data['back_image_path']?.toString();

    frontSignedUrl = await createSignedUrl(frontImagePath);
    backSignedUrl = await createSignedUrl(backImagePath);

    insuranceFrontImage = null;
    insuranceBackImage = null;

    if (mounted) {
      setState(() {});
    }
  }

  DateTime? parseDate(dynamic value) {
    if (value == null) return null;

    return DateTime.tryParse(value.toString());
  }

  Future<void> pickImage({
    required bool isFrontImage,
    required ImageSource source,
  }) async {
    try {
      final XFile? selectedImage = await imagePicker.pickImage(
        source: source,
        imageQuality: 82,
        maxWidth: 1800,
      );

      if (selectedImage == null || !mounted) return;

      setState(() {
        if (isFrontImage) {
          insuranceFrontImage = File(selectedImage.path);
        } else {
          insuranceBackImage = File(selectedImage.path);
        }
      });
    } catch (error) {
      if (!mounted) return;

      showMessage(
        'Unable to select image: $error',
        success: false,
      );
    }
  }

  void showImageSourceSheet({
    required bool isFrontImage,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isFrontImage
                    ? 'Upload Insurance Front Side'
                    : 'Upload Insurance Back Side',
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: sourceButton(
                      icon: Icons.camera_alt_outlined,
                      title: 'Camera',
                      onTap: () {
                        Navigator.pop(sheetContext);

                        pickImage(
                          isFrontImage: isFrontImage,
                          source: ImageSource.camera,
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: sourceButton(
                      icon: Icons.photo_library_outlined,
                      title: 'Gallery',
                      onTap: () {
                        Navigator.pop(sheetContext);

                        pickImage(
                          isFrontImage: isFrontImage,
                          source: ImageSource.gallery,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget sourceButton({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 22),
        decoration: BoxDecoration(
          color: primaryColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: primaryColor.withValues(alpha: 0.18),
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: primaryColor,
              size: 30,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String getFileExtension(File file) {
    final path = file.path.toLowerCase();

    if (path.endsWith('.png')) return 'png';
    if (path.endsWith('.webp')) return 'webp';

    return 'jpg';
  }

  String getContentType(String extension) {
    switch (extension) {
      case 'png':
        return 'image/png';

      case 'webp':
        return 'image/webp';

      default:
        return 'image/jpeg';
    }
  }

  Future<String> uploadInsuranceImage({
    required File image,
    required String side,
  }) async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      throw Exception('User is not logged in.');
    }

    if (bikeId == null) {
      throw Exception('Bike ID not found.');
    }

    final extension = getFileExtension(image);

    final storagePath =
        '${user.id}/$bikeId/insurance/$side.$extension';

    await supabase.storage.from(bucketName).upload(
          storagePath,
          image,
          fileOptions: FileOptions(
            upsert: true,
            cacheControl: '0',
            contentType: getContentType(extension),
          ),
        );

    return storagePath;
  }

  Future<String?> createSignedUrl(String? path) async {
    if (path == null || path.isEmpty) return null;

    try {
      return await supabase.storage
          .from(bucketName)
          .createSignedUrl(
            path,
            3600,
          );
    } catch (_) {
      return null;
    }
  }

  Future<void> saveInsurance() async {
    if (saving) return;

    final user = supabase.auth.currentUser;

    if (user == null) {
      showMessage(
        'Please login before saving.',
        success: false,
      );
      return;
    }

    if (bikeId == null) {
      showMessage(
        'Bike details not found.',
        success: false,
      );
      return;
    }

    final policyNumber =
        policyNumberController.text.trim().toUpperCase();

    if (policyNumber.isEmpty) {
      showMessage(
        'Please enter the policy number.',
        success: false,
      );
      return;
    }

    final hasFrontImage =
        insuranceFrontImage != null ||
        (frontImagePath?.isNotEmpty ?? false);

    if (!hasFrontImage) {
      showMessage(
        'Please upload the insurance front image.',
        success: false,
      );
      return;
    }

    try {
      setState(() => saving = true);

      String? uploadedFrontPath = frontImagePath;
      String? uploadedBackPath = backImagePath;

      if (insuranceFrontImage != null) {
        uploadedFrontPath = await uploadInsuranceImage(
          image: insuranceFrontImage!,
          side: 'front',
        );
      }

      if (insuranceBackImage != null) {
        uploadedBackPath = await uploadInsuranceImage(
          image: insuranceBackImage!,
          side: 'back',
        );
      }

      final values = <String, dynamic>{
        'user_id': user.id,
        'bike_id': bikeId,
        'policy_number': policyNumber,
        'insurance_company':
            emptyToNull(companyController.text),
        'policy_type':
            emptyToNull(policyTypeController.text),
        'premium_amount':
            double.tryParse(premiumController.text.trim()),
        'start_date': databaseDate(startDate),
        'expiry_date': databaseDate(expiryDate),
        'front_image_path': uploadedFrontPath,
        'back_image_path': uploadedBackPath,
        'updated_at': DateTime.now().toIso8601String(),
      };

      final savedData = await supabase
          .from('bike_insurance')
          .upsert(
            values,
            onConflict: 'user_id,bike_id',
          )
          .select()
          .single();

      insuranceRecordId = savedData['id']?.toString();

      await loadInsurance();

      if (!mounted) return;

      showMessage(
        'Bike insurance saved successfully.',
        success: true,
      );
    } on StorageException catch (error) {
      if (!mounted) return;

      showMessage(
        'Image upload failed: ${error.message}',
        success: false,
      );
    } on PostgrestException catch (error) {
      debugPrint('Insurance database error: ${error.message}');
      debugPrint('Code: ${error.code}');
      debugPrint('Details: ${error.details}');

      if (!mounted) return;

      showMessage(
        'Database error: ${error.message}',
        success: false,
      );
    } catch (error) {
      if (!mounted) return;

      showMessage(
        'Save failed: $error',
        success: false,
      );
    } finally {
      if (mounted) {
        setState(() => saving = false);
      }
    }
  }

  String? emptyToNull(String value) {
    final result = value.trim();

    return result.isEmpty ? null : result;
  }

  String? databaseDate(DateTime? date) {
    if (date == null) return null;

    final year = date.year.toString();
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  Future<void> selectDate({
    required bool isExpiry,
  }) async {
    final initialDate = isExpiry
        ? expiryDate ??
            DateTime.now().add(
              const Duration(days: 365),
            )
        : startDate ?? DateTime.now();

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1990),
      lastDate: DateTime(2050),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (selectedDate == null || !mounted) return;

    setState(() {
      if (isExpiry) {
        expiryDate = selectedDate;
      } else {
        startDate = selectedDate;
      }
    });
  }

  String formatDate(DateTime? date) {
    if (date == null) return 'Select date';

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  Future<void> deleteInsurance() async {
    if (deleting) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Insurance?'),
          content: const Text(
            'The insurance details and images will be permanently deleted.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      setState(() => deleting = true);

      if (insuranceRecordId != null) {
        await supabase
            .from('bike_insurance')
            .delete()
            .eq('id', insuranceRecordId!);
      }

      final paths = <String>[];

      if (frontImagePath?.isNotEmpty ?? false) {
        paths.add(frontImagePath!);
      }

      if (backImagePath?.isNotEmpty ?? false) {
        paths.add(backImagePath!);
      }

      if (paths.isNotEmpty) {
        await supabase.storage
            .from(bucketName)
            .remove(paths);
      }

      clearLocalValues();

      if (!mounted) return;

      setState(() {});

      showMessage(
        'Insurance deleted successfully.',
        success: true,
      );
    } catch (error) {
      if (!mounted) return;

      showMessage(
        'Delete failed: $error',
        success: false,
      );
    } finally {
      if (mounted) {
        setState(() => deleting = false);
      }
    }
  }

  void clearLocalValues() {
    insuranceRecordId = null;

    policyNumberController.clear();
    companyController.clear();
    policyTypeController.clear();
    premiumController.clear();

    startDate = null;
    expiryDate = null;

    insuranceFrontImage = null;
    insuranceBackImage = null;

    frontImagePath = null;
    backImagePath = null;

    frontSignedUrl = null;
    backSignedUrl = null;
  }

  void showMessage(
    String message, {
    required bool success,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            success ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String cleanError(Object error) {
    return error
        .toString()
        .replaceFirst('Exception: ', '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        foregroundColor: Colors.black,
        title: const Text(
          'Bike Insurance',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          if (hasAnyData)
            IconButton(
              onPressed: deleting ? null : deleteInsurance,
              icon: const Icon(
                Icons.delete_outline,
                color: Colors.red,
              ),
            ),
        ],
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(
                color: primaryColor,
              ),
            )
          : RefreshIndicator(
              onRefresh: loadInsurance,
              color: primaryColor,
              child: SingleChildScrollView(
                physics:
                    const AlwaysScrollableScrollPhysics(),
                padding:
                    const EdgeInsets.fromLTRB(18, 16, 18, 120),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    headerCard(),
                    const SizedBox(height: 22),
                    const Text(
                      'Insurance Images',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    imageCard(
                      title: 'Insurance Front Side',
                      subtitle: 'Upload insurance document',
                      localImage: insuranceFrontImage,
                      networkUrl: frontSignedUrl,
                      isFrontImage: true,
                    ),
                    const SizedBox(height: 14),
                    imageCard(
                      title: 'Insurance Back Side',
                      subtitle: 'Optional',
                      localImage: insuranceBackImage,
                      networkUrl: backSignedUrl,
                      isFrontImage: false,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Policy Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    detailsCard(),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: saveButton(),
    );
  }

  Widget headerCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFF5A1F),
            Color(0xFFFF8A3D),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.20),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.shield_outlined,
              color: Colors.white,
              size: 34,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  hasSavedInsurance
                      ? 'Your insurance is saved'
                      : 'Protect your bike',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Keep your bike insurance ready for quick access.',
                  style: TextStyle(
                    color: Colors.white,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget imageCard({
    required String title,
    required String subtitle,
    required File? localImage,
    required String? networkUrl,
    required bool isFrontImage,
  }) {
    final hasImage = localImage != null ||
        (networkUrl?.isNotEmpty ?? false);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFEDEFF3),
        ),
      ),
      child: hasImage
          ? Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: SizedBox(
                    width: double.infinity,
                    height: 190,
                    child: localImage != null
                        ? Image.file(
                            localImage,
                            fit: BoxFit.cover,
                          )
                        : Image.network(
                            networkUrl!,
                            fit: BoxFit.cover,
                          ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    showImageSourceSheet(
                      isFrontImage: isFrontImage,
                    );
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Replace'),
                ),
              ],
            )
          : InkWell(
              onTap: () {
                showImageSourceSheet(
                  isFrontImage: isFrontImage,
                );
              },
              child: SizedBox(
                height: 150,
                child: Column(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.add_photo_alternate_outlined,
                      color: primaryColor,
                      size: 40,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget detailsCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          textField(
            controller: policyNumberController,
            label: 'Policy Number',
            icon: Icons.numbers,
          ),
          const SizedBox(height: 16),
          textField(
            controller: companyController,
            label: 'Insurance Company',
            icon: Icons.business_outlined,
          ),
          const SizedBox(height: 16),
          textField(
            controller: policyTypeController,
            label: 'Policy Type',
            icon: Icons.shield_outlined,
          ),
          const SizedBox(height: 16),
          textField(
            controller: premiumController,
            label: 'Premium Amount',
            icon: Icons.currency_rupee,
            keyboardType:
                const TextInputType.numberWithOptions(
              decimal: true,
            ),
          ),
          const SizedBox(height: 16),
          dateField(
            title: 'Policy Start Date',
            date: startDate,
            onTap: () {
              selectDate(isExpiry: false);
            },
          ),
          const SizedBox(height: 16),
          dateField(
            title: 'Policy Expiry Date',
            date: expiryDate,
            onTap: () {
              selectDate(isExpiry: true);
            },
          ),
        ],
      ),
    );
  }

  Widget textField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(
          icon,
          color: primaryColor,
        ),
        filled: true,
        fillColor: const Color(0xFFF8F9FB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Widget dateField({
    required String title,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FB),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFE8EAF0),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_month_outlined,
              color: primaryColor,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '$title: ${formatDate(date)}',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget saveButton() {
    return Container(
      padding: const EdgeInsets.all(18),
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 56,
          child: ElevatedButton.icon(
            onPressed: saving ? null : saveInsurance,
            icon: saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(
                    Icons.cloud_upload_outlined,
                  ),
            label: Text(
              saving
                  ? 'Saving Insurance...'
                  : hasSavedInsurance
                      ? 'Update Insurance'
                      : 'Save Insurance',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
        ),
      ),
    );
  }
}