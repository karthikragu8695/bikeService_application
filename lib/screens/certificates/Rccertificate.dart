import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RegistrationCertificatePage extends StatefulWidget {
  const RegistrationCertificatePage({super.key});

  @override
  State<RegistrationCertificatePage> createState() =>
      _RegistrationCertificatePageState();
}

class _RegistrationCertificatePageState
    extends State<RegistrationCertificatePage> {
  static const Color primaryColor = Color(0xFFFF5A1F);
  static const Color backgroundColor = Color(0xFFF7F8FA);
  static const String bucketName = 'bike-documents';

  final SupabaseClient supabase = Supabase.instance.client;
  final ImagePicker imagePicker = ImagePicker();

  final TextEditingController registrationController =
      TextEditingController();

  final TextEditingController ownerNameController =
      TextEditingController();

  File? rcFrontImage;
  File? rcBackImage;

  DateTime? registrationDate;
  DateTime? expiryDate;

  String? bikeId;
  String? rcRecordId;

  String? frontImagePath;
  String? backImagePath;

  String? frontSignedUrl;
  String? backSignedUrl;

  bool loading = true;
  bool saving = false;
  bool deleting = false;

  bool get hasSavedDocument => rcRecordId != null;

  bool get hasAnyDocumentData {
    return hasSavedDocument ||
        rcFrontImage != null ||
        rcBackImage != null ||
        registrationController.text.trim().isNotEmpty;
  }

  @override
  void initState() {
    super.initState();
    initialisePage();
  }

  @override
  void dispose() {
    registrationController.dispose();
    ownerNameController.dispose();
    super.dispose();
  }

  // =========================================================
  // INITIAL LOAD
  // =========================================================

  Future<void> initialisePage() async {
    try {
      setState(() {
        loading = true;
      });

      final User? user = supabase.auth.currentUser;

      if (user == null) {
        throw Exception('Please login before opening RC documents.');
      }

      final Map<String, dynamic>? bike = await getCurrentBike();

      if (bike == null) {
        throw Exception(
          'Bike details not found. Please add your bike first.',
        );
      }

      bikeId = bike['id'].toString();

      await loadRegistrationCertificate();
    } catch (error) {
      if (!mounted) return;

      showMessage(
        cleanError(error),
        success: false,
      );
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  Future<Map<String, dynamic>?> getCurrentBike() async {
    final User? user = supabase.auth.currentUser;

    if (user == null) {
      return null;
    }

    final Map<String, dynamic>? bike = await supabase
        .from('bikes')
        .select('id')
        .eq('user_id', user.id)
        .limit(1)
        .maybeSingle();

    return bike;
  }

  Future<void> loadRegistrationCertificate() async {
    final User? user = supabase.auth.currentUser;

    if (user == null || bikeId == null) {
      return;
    }

    final Map<String, dynamic>? data = await supabase
        .from('registration_certificates')
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

    rcRecordId = data['id']?.toString();

    registrationController.text =
        data['registration_number']?.toString() ?? '';

    ownerNameController.text =
        data['owner_name']?.toString() ?? '';

    registrationDate = parseDate(data['registration_date']);
    expiryDate = parseDate(data['valid_until']);

    frontImagePath = data['front_image_path']?.toString();
    backImagePath = data['back_image_path']?.toString();

    frontSignedUrl = await createSignedUrl(frontImagePath);
    backSignedUrl = await createSignedUrl(backImagePath);

    rcFrontImage = null;
    rcBackImage = null;

    if (mounted) {
      setState(() {});
    }
  }

  DateTime? parseDate(dynamic value) {
    if (value == null) {
      return null;
    }

    return DateTime.tryParse(value.toString());
  }

  // =========================================================
  // IMAGE PICKING
  // =========================================================

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

      if (selectedImage == null || !mounted) {
        return;
      }

      setState(() {
        if (isFrontImage) {
          rcFrontImage = File(selectedImage.path);
        } else {
          rcBackImage = File(selectedImage.path);
        }
      });
    } catch (error) {
      if (!mounted) return;

      showMessage(
        'Unable to select image: ${cleanError(error)}',
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
                    ? 'Upload RC Front Side'
                    : 'Upload RC Back Side',
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

  // =========================================================
  // STORAGE FUNCTIONS
  // =========================================================

  String getFileExtension(File file) {
    final String path = file.path.toLowerCase();

    if (path.endsWith('.png')) {
      return 'png';
    }

    if (path.endsWith('.webp')) {
      return 'webp';
    }

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

  Future<String> uploadRcImage({
    required File image,
    required String side,
  }) async {
    final User? user = supabase.auth.currentUser;

    if (user == null) {
      throw Exception('User is not logged in.');
    }

    if (bikeId == null) {
      throw Exception('Bike ID not found.');
    }

    final String extension = getFileExtension(image);

    final String storagePath =
        '${user.id}/$bikeId/rc/$side.$extension';

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
    if (path == null || path.trim().isEmpty) {
      return null;
    }

    try {
      final String url = await supabase.storage
          .from(bucketName)
          .createSignedUrl(
            path,
            60 * 60,
          );

      return url;
    } catch (_) {
      return null;
    }
  }

  Future<void> removeStorageFiles(
    List<String> paths,
  ) async {
    final List<String> validPaths = paths
        .where((path) => path.trim().isNotEmpty)
        .toSet()
        .toList();

    if (validPaths.isEmpty) {
      return;
    }

    await supabase.storage
        .from(bucketName)
        .remove(validPaths);
  }

  // =========================================================
  // SAVE DOCUMENT
  // =========================================================

  Future<void> saveDocument() async {
    if (saving) {
      return;
    }

    final User? user = supabase.auth.currentUser;

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

    final String registrationNumber =
        registrationController.text.trim().toUpperCase();

    final String ownerName =
        ownerNameController.text.trim();

    if (registrationNumber.isEmpty) {
      showMessage(
        'Please enter the registration number.',
        success: false,
      );
      return;
    }

    final bool hasFrontImage =
        rcFrontImage != null ||
        (frontImagePath != null && frontImagePath!.isNotEmpty);

    if (!hasFrontImage) {
      showMessage(
        'Please upload the RC front image.',
        success: false,
      );
      return;
    }

    FocusScope.of(context).unfocus();

    try {
      setState(() {
        saving = true;
      });

      String? uploadedFrontPath = frontImagePath;
      String? uploadedBackPath = backImagePath;

      if (rcFrontImage != null) {
        uploadedFrontPath = await uploadRcImage(
          image: rcFrontImage!,
          side: 'front',
        );
      }

      if (rcBackImage != null) {
        uploadedBackPath = await uploadRcImage(
          image: rcBackImage!,
          side: 'back',
        );
      }

      final Map<String, dynamic> values = {
  'user_id': user.id,
  'bike_id': bikeId,
  'registration_number': registrationNumber,
  'owner_name': ownerName.isEmpty ? null : ownerName,
  'vehicle_model': null,
  'chassis_number': null,
  'engine_number': null,
  'registration_date': databaseDate(registrationDate),
  'valid_until': databaseDate(expiryDate),
  'front_image_path': uploadedFrontPath,
  'back_image_path': uploadedBackPath,
  'updated_at': DateTime.now().toIso8601String(),
};

final Map<String, dynamic> savedData = await supabase
    .from('registration_certificates')
    .upsert(
      values,
      onConflict: 'user_id,bike_id',
    )
    .select()
    .single();

      if (savedData.isEmpty) {
        throw Exception('RC details could not be saved.');
      }

      await loadRegistrationCertificate();

      if (!mounted) return;

      showMessage(
        'Registration Certificate saved successfully.',
        success: true,
      );
    } on StorageException catch (error) {
      if (!mounted) return;

      showMessage(
        'Image upload failed: ${error.message}',
        success: false,
      );
    } on PostgrestException catch (error) {
      if (!mounted) return;

      showMessage(
        'Database save failed: ${error.message}',
        success: false,
      );
    } catch (error) {
      if (!mounted) return;

      showMessage(
        cleanError(error),
        success: false,
      );
    } finally {
      if (mounted) {
        setState(() {
          saving = false;
        });
      }
    }
  }

  String? databaseDate(DateTime? date) {
    if (date == null) {
      return null;
    }

    final String year = date.year.toString();

    final String month =
        date.month.toString().padLeft(2, '0');

    final String day =
        date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  // =========================================================
  // DELETE DOCUMENT
  // =========================================================

  Future<void> showDeleteConfirmation() async {
    if (!hasSavedDocument && !hasAnyDocumentData) {
      return;
    }

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Delete RC Document?'),
          content: const Text(
            'The RC details and uploaded images will be permanently removed.',
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

    if (confirmed == true) {
      await deleteDocument();
    }
  }

  Future<void> deleteDocument() async {
    if (deleting) {
      return;
    }

    try {
      setState(() {
        deleting = true;
      });

      final List<String> storagePaths = [];

      if (frontImagePath != null &&
          frontImagePath!.isNotEmpty) {
        storagePaths.add(frontImagePath!);
      }

      if (backImagePath != null &&
          backImagePath!.isNotEmpty) {
        storagePaths.add(backImagePath!);
      }

      if (rcRecordId != null) {
        await supabase
            .from('registration_certificates')
            .delete()
            .eq('id', rcRecordId!);
      }

      await removeStorageFiles(storagePaths);

      clearLocalValues();

      if (!mounted) return;

      setState(() {});

      showMessage(
        'Registration Certificate deleted successfully.',
        success: true,
      );
    } on StorageException catch (error) {
      if (!mounted) return;

      showMessage(
        'Storage delete failed: ${error.message}',
        success: false,
      );
    } on PostgrestException catch (error) {
      if (!mounted) return;

      showMessage(
        'Database delete failed: ${error.message}',
        success: false,
      );
    } catch (error) {
      if (!mounted) return;

      showMessage(
        cleanError(error),
        success: false,
      );
    } finally {
      if (mounted) {
        setState(() {
          deleting = false;
        });
      }
    }
  }

  void clearLocalValues() {
    rcRecordId = null;

    registrationController.clear();
    ownerNameController.clear();

    registrationDate = null;
    expiryDate = null;

    rcFrontImage = null;
    rcBackImage = null;

    frontImagePath = null;
    backImagePath = null;

    frontSignedUrl = null;
    backSignedUrl = null;
  }

  // =========================================================
  // DATE PICKER
  // =========================================================

  Future<void> selectDate({
    required bool isExpiryDate,
  }) async {
    final DateTime initialDate = isExpiryDate
        ? expiryDate ??
            DateTime.now().add(
              const Duration(days: 365),
            )
        : registrationDate ?? DateTime.now();

    final DateTime? selectedDate = await showDatePicker(
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

    if (selectedDate == null || !mounted) {
      return;
    }

    setState(() {
      if (isExpiryDate) {
        expiryDate = selectedDate;
      } else {
        registrationDate = selectedDate;
      }
    });
  }

  String formatDate(DateTime? date) {
    if (date == null) {
      return 'Select date';
    }

    final String day =
        date.day.toString().padLeft(2, '0');

    final String month =
        date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  // =========================================================
  // FULL-SCREEN VIEWER
  // =========================================================

  void openDocumentImage({
    required String title,
    File? localFile,
    String? networkUrl,
  }) {
    if (localFile == null &&
        (networkUrl == null || networkUrl.isEmpty)) {
      showMessage(
        'Document image is not available.',
        success: false,
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          return FullScreenDocumentViewer(
            title: title,
            localFile: localFile,
            networkUrl: networkUrl,
          );
        },
      ),
    );
  }

  // =========================================================
  // MESSAGE
  // =========================================================

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

  // =========================================================
  // UI
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'Registration Certificate',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        actions: [
          if (hasAnyDocumentData)
            IconButton(
              tooltip: 'Delete RC',
              onPressed: deleting
                  ? null
                  : showDeleteConfirmation,
              icon: deleting
                  ? const SizedBox(
                      width: 21,
                      height: 21,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.red,
                    ),
            ),
          const SizedBox(width: 6),
        ],
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(
                color: primaryColor,
              ),
            )
          : RefreshIndicator(
              color: primaryColor,
              onRefresh: loadRegistrationCertificate,
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
                      'Document Images',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    documentImageCard(
                      title: 'RC Front Side',
                      subtitle:
                          'Upload a clear front-side image',
                      localImage: rcFrontImage,
                      networkUrl: frontSignedUrl,
                      isFrontImage: true,
                    ),
                    const SizedBox(height: 14),
                    documentImageCard(
                      title: 'RC Back Side',
                      subtitle: 'Optional',
                      localImage: rcBackImage,
                      networkUrl: backSignedUrl,
                      isFrontImage: false,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Vehicle Details',
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
      bottomNavigationBar: bottomSaveButton(),
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
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.24),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 62,
            width: 62,
            decoration: BoxDecoration(
              color:
                  Colors.white.withValues(alpha: 0.20),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.description_outlined,
              color: Colors.white,
              size: 33,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  hasSavedDocument
                      ? 'Your RC is saved'
                      : 'Keep your RC ready',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  hasSavedDocument
                      ? 'You can view or update your registration certificate.'
                      : 'Store your registration certificate for quick access.',
                  style: const TextStyle(
                    color: Colors.white,
                    height: 1.4,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget documentImageCard({
    required String title,
    required String subtitle,
    required File? localImage,
    required String? networkUrl,
    required bool isFrontImage,
  }) {
    final bool hasImage = localImage != null ||
        (networkUrl != null && networkUrl.isNotEmpty);

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
      child: !hasImage
          ? InkWell(
              onTap: saving
                  ? null
                  : () {
                      showImageSourceSheet(
                        isFrontImage: isFrontImage,
                      );
                    },
              borderRadius: BorderRadius.circular(18),
              child: Container(
                height: 155,
                decoration: BoxDecoration(
                  color: const Color(0xFFFAFAFB),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: const Color(0xFFDADDE3),
                  ),
                ),
                child: Column(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    Container(
                      height: 52,
                      width: 52,
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(
                          alpha: 0.10,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.add_photo_alternate_outlined,
                        color: primaryColor,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Stack(
                    children: [
                      SizedBox(
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
                                loadingBuilder: (
                                  context,
                                  child,
                                  loadingProgress,
                                ) {
                                  if (loadingProgress == null) {
                                    return child;
                                  }

                                  return const Center(
                                    child:
                                        CircularProgressIndicator(
                                      color: primaryColor,
                                    ),
                                  );
                                },
                                errorBuilder: (
                                  context,
                                  error,
                                  stackTrace,
                                ) {
                                  return const Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons
                                              .broken_image_outlined,
                                          color: Colors.grey,
                                          size: 36,
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          'Unable to load image',
                                          style: TextStyle(
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),
                      Positioned.fill(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              openDocumentImage(
                                title: title,
                                localFile: localImage,
                                networkUrl: networkUrl,
                              );
                            },
                          ),
                        ),
                      ),
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(
                              alpha: 0.55,
                            ),
                            borderRadius:
                                BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            tooltip: 'View image',
                            onPressed: () {
                              openDocumentImage(
                                title: title,
                                localFile: localImage,
                                networkUrl: networkUrl,
                              );
                            },
                            icon: const Icon(
                              Icons.fullscreen_rounded,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: saving
                          ? null
                          : () {
                              showImageSourceSheet(
                                isFrontImage:
                                    isFrontImage,
                              );
                            },
                      icon: const Icon(
                        Icons.refresh_rounded,
                        size: 19,
                      ),
                      label: const Text('Replace'),
                      style: TextButton.styleFrom(
                        foregroundColor: primaryColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  Widget detailsCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFEDEFF3),
        ),
      ),
      child: Column(
        children: [
          textField(
            controller: registrationController,
            label: 'Registration Number',
            hint: 'Example: TN 45 AB 1234',
            icon: Icons.two_wheeler_outlined,
            textCapitalization:
                TextCapitalization.characters,
          ),
          const SizedBox(height: 16),
          textField(
            controller: ownerNameController,
            label: 'Owner Name',
            hint: 'Enter owner name',
            icon: Icons.person_outline_rounded,
            textCapitalization:
                TextCapitalization.words,
          ),
          const SizedBox(height: 16),
          dateField(
            title: 'Registration Date',
            date: registrationDate,
            onTap: () {
              selectDate(isExpiryDate: false);
            },
          ),
          const SizedBox(height: 16),
          dateField(
            title: 'Valid Until',
            date: expiryDate,
            onTap: () {
              selectDate(isExpiryDate: true);
            },
          ),
        ],
      ),
    );
  }

  Widget textField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required TextCapitalization textCapitalization,
  }) {
    return TextFormField(
      controller: controller,
      enabled: !saving,
      textCapitalization: textCapitalization,
      onChanged: (_) {
        setState(() {});
      },
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(
          icon,
          color: primaryColor,
        ),
        filled: true,
        fillColor: const Color(0xFFF8F9FB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Color(0xFFE8EAF0),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: primaryColor,
            width: 1.5,
          ),
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
      onTap: saving ? null : onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 15,
        ),
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
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatDate(date),
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: date == null
                          ? Colors.grey.shade600
                          : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Widget bottomSaveButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        18,
        12,
        18,
        18,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withValues(alpha: 0.07),
            blurRadius: 18,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 56,
          child: ElevatedButton.icon(
            onPressed:
                loading || saving ? null : saveDocument,
            icon: saving
                ? const SizedBox(
                    width: 21,
                    height: 21,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: Colors.white,
                    ),
                  )
                : Icon(
                    hasSavedDocument
                        ? Icons.save_outlined
                        : Icons.cloud_upload_outlined,
                  ),
            label: Text(
              saving
                  ? 'Saving RC...'
                  : hasSavedDocument
                      ? 'Update RC Document'
                      : 'Save RC Document',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              disabledBackgroundColor:
                  primaryColor.withValues(alpha: 0.55),
              disabledForegroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(18),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// =========================================================
// FULL-SCREEN DOCUMENT VIEWER
// =========================================================

class FullScreenDocumentViewer extends StatelessWidget {
  final String title;
  final File? localFile;
  final String? networkUrl;

  const FullScreenDocumentViewer({
    super.key,
    required this.title,
    this.localFile,
    this.networkUrl,
  });

  @override
  Widget build(BuildContext context) {
    final Widget imageWidget;

    if (localFile != null) {
      imageWidget = Image.file(
        localFile!,
        fit: BoxFit.contain,
      );
    } else {
      imageWidget = Image.network(
        networkUrl!,
        fit: BoxFit.contain,
        loadingBuilder: (
          context,
          child,
          loadingProgress,
        ) {
          if (loadingProgress == null) {
            return child;
          }

          return const Center(
            child: CircularProgressIndicator(
              color: Colors.white,
            ),
          );
        },
        errorBuilder: (
          context,
          error,
          stackTrace,
        ) {
          return const Center(
            child: Text(
              'Unable to load document image',
              style: TextStyle(
                color: Colors.white,
              ),
            ),
          );
        },
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.8,
          maxScale: 5,
          child: imageWidget,
        ),
      ),
    );
  }
}