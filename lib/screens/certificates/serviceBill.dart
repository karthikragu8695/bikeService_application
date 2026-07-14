import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ServiceBillsPage extends StatefulWidget {
  const ServiceBillsPage({super.key});

  @override
  State<ServiceBillsPage> createState() => _ServiceBillsPageState();
}

class _ServiceBillsPageState extends State<ServiceBillsPage> {
  static const Color primaryColor = Color(0xFFFF5A1F);
  static const Color backgroundColor = Color(0xFFF7F8FA);
  static const String bucketName = 'bike-documents';

  final SupabaseClient supabase = Supabase.instance.client;
  final TextEditingController searchController = TextEditingController();

  List<Map<String, dynamic>> allBills = [];
  List<Map<String, dynamic>> filteredBills = [];

  String? bikeId;

  DateTime? selectedExactDate;
  DateTime? selectedMonth;

  bool loading = true;

  @override
  void initState() {
    super.initState();
    initialisePage();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> initialisePage() async {
    try {
      setState(() {
        loading = true;
      });

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

      await loadServiceBills();
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

  Future<void> loadServiceBills() async {
    if (bikeId == null) return;

    try {
      final List<Map<String, dynamic>> response =
          await supabase
              .from('service_bills')
              .select()
              .eq('bike_id', bikeId!)
              .order('service_date', ascending: false)
              .order('created_at', ascending: false);

      allBills = response;

      await createSignedUrlsForBills();

      applyFilters();

      if (mounted) {
        setState(() {});
      }
    } on PostgrestException catch (error) {
      if (!mounted) return;

      showMessage(
        'Load failed: ${error.message}',
        success: false,
      );
    }
  }

  Future<void> createSignedUrlsForBills() async {
    for (final bill in allBills) {
      final String path =
          bill['bill_image_path']?.toString() ?? '';

      if (path.isEmpty) {
        bill['signed_url'] = null;
        continue;
      }

      try {
        final signedUrl = await supabase.storage
            .from(bucketName)
            .createSignedUrl(
              path,
              3600,
            );

        bill['signed_url'] = signedUrl;
      } catch (_) {
        bill['signed_url'] = null;
      }
    }
  }

  void applyFilters() {
    final String search =
        searchController.text.trim().toLowerCase();

    filteredBills = allBills.where((bill) {
      final String serviceCenter =
          bill['service_center']?.toString().toLowerCase() ?? '';

      final String serviceType =
          bill['service_type']?.toString().toLowerCase() ?? '';

      final String notes =
          bill['notes']?.toString().toLowerCase() ?? '';

      final bool matchesSearch = search.isEmpty ||
          serviceCenter.contains(search) ||
          serviceType.contains(search) ||
          notes.contains(search);

      final DateTime? serviceDate = DateTime.tryParse(
        bill['service_date']?.toString() ?? '',
      );

      bool matchesExactDate = true;
      bool matchesMonth = true;

      if (selectedExactDate != null) {
        matchesExactDate = serviceDate != null &&
            serviceDate.year == selectedExactDate!.year &&
            serviceDate.month == selectedExactDate!.month &&
            serviceDate.day == selectedExactDate!.day;
      }

      if (selectedMonth != null) {
        matchesMonth = serviceDate != null &&
            serviceDate.year == selectedMonth!.year &&
            serviceDate.month == selectedMonth!.month;
      }

      return matchesSearch &&
          matchesExactDate &&
          matchesMonth;
    }).toList();

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> selectExactDate() async {
    final DateTime? result = await showDatePicker(
      context: context,
      initialDate: selectedExactDate ?? DateTime.now(),
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

    if (result == null) return;

    selectedExactDate = result;
    selectedMonth = null;

    applyFilters();
  }

  Future<void> selectMonth() async {
    int selectedYear =
        selectedMonth?.year ?? DateTime.now().year;

    int selectedMonthNumber =
        selectedMonth?.month ?? DateTime.now().month;

    final DateTime? result = await showDialog<DateTime>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text('Select Month'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int>(
                    initialValue: selectedMonthNumber,
                    decoration: InputDecoration(
                      labelText: 'Month',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    items: List.generate(12, (index) {
                      return DropdownMenuItem(
                        value: index + 1,
                        child: Text(
                          monthName(index + 1),
                        ),
                      );
                    }),
                    onChanged: (value) {
                      if (value == null) return;

                      setDialogState(() {
                        selectedMonthNumber = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    initialValue: selectedYear,
                    decoration: InputDecoration(
                      labelText: 'Year',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    items: List.generate(21, (index) {
                      final int year = DateTime.now().year - 10 + index;

                      return DropdownMenuItem(
                        value: year,
                        child: Text(year.toString()),
                      );
                    }),
                    onChanged: (value) {
                      if (value == null) return;

                      setDialogState(() {
                        selectedYear = value;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    Navigator.pop(
                      dialogContext,
                      DateTime(
                        selectedYear,
                        selectedMonthNumber,
                      ),
                    );
                  },
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null) return;

    selectedMonth = result;
    selectedExactDate = null;

    applyFilters();
  }

  void clearFilters() {
    searchController.clear();
    selectedExactDate = null;
    selectedMonth = null;

    applyFilters();
  }

  Future<void> openAddBillPage() async {
    if (bikeId == null) {
      showMessage(
        'Bike details not found.',
        success: false,
      );
      return;
    }

    final bool? result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) {
          return AddEditServiceBillPage(
            bikeId: bikeId!,
          );
        },
      ),
    );

    if (result == true) {
      await loadServiceBills();
    }
  }

  Future<void> openEditBillPage(
    Map<String, dynamic> bill,
  ) async {
    if (bikeId == null) return;

    final bool? result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) {
          return AddEditServiceBillPage(
            bikeId: bikeId!,
            existingBill: bill,
          );
        },
      ),
    );

    if (result == true) {
      await loadServiceBills();
    }
  }

  Future<void> deleteBill(
    Map<String, dynamic> bill,
  ) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Delete Service Bill?'),
          content: const Text(
            'The bill details and uploaded image will be permanently deleted.',
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
      final String id = bill['id'].toString();

      final String imagePath =
          bill['bill_image_path']?.toString() ?? '';

      await supabase
          .from('service_bills')
          .delete()
          .eq('id', id);

      if (imagePath.isNotEmpty) {
        await supabase.storage
            .from(bucketName)
            .remove([imagePath]);
      }

      await loadServiceBills();

      if (!mounted) return;

      showMessage(
        'Service bill deleted successfully.',
        success: true,
      );
    } on PostgrestException catch (error) {
      if (!mounted) return;

      showMessage(
        'Delete failed: ${error.message}',
        success: false,
      );
    } on StorageException catch (error) {
      if (!mounted) return;

      showMessage(
        'Image delete failed: ${error.message}',
        success: false,
      );
    }
  }

  void openBillImage(
    Map<String, dynamic> bill,
  ) {
    final String? signedUrl =
        bill['signed_url']?.toString();

    if (signedUrl == null || signedUrl.isEmpty) {
      showMessage(
        'Bill image is not available.',
        success: false,
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          return ServiceBillImageViewer(
            imageUrl: signedUrl,
            title: bill['service_type']?.toString() ??
                'Service Bill',
          );
        },
      ),
    );
  }

  double getDouble(dynamic value) {
    if (value == null) return 0;

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString()) ?? 0;
  }

  String formatDisplayDate(dynamic value) {
    final DateTime? date = DateTime.tryParse(
      value?.toString() ?? '',
    );

    if (date == null) return '--';

    final String day =
        date.day.toString().padLeft(2, '0');

    final String month =
        date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  String monthName(int month) {
    const List<String> months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return months[month - 1];
  }

  String cleanError(Object error) {
    return error
        .toString()
        .replaceFirst('Exception: ', '');
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
          'Service Bills',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: openAddBillPage,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text(
          'Add Bill',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(
                color: primaryColor,
              ),
            )
          : RefreshIndicator(
              onRefresh: loadServiceBills,
              color: primaryColor,
              child: SingleChildScrollView(
                physics:
                    const AlwaysScrollableScrollPhysics(),
                padding:
                    const EdgeInsets.fromLTRB(16, 16, 16, 100),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    headerCard(),
                    const SizedBox(height: 18),
                    searchField(),
                    const SizedBox(height: 12),
                    filterButtons(),
                    const SizedBox(height: 18),
                    resultsHeader(),
                    const SizedBox(height: 12),
                    billsList(),
                  ],
                ),
              ),
            ),
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
      child: const Row(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            color: Colors.white,
            size: 46,
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Keep every service bill',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Find old service records easily using date, month or service centre.',
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

  Widget searchField() {
    return TextField(
      controller: searchController,
      onChanged: (_) {
        applyFilters();
      },
      decoration: InputDecoration(
        hintText: 'Search service centre or type',
        prefixIcon: const Icon(
          Icons.search,
          color: primaryColor,
        ),
        suffixIcon: searchController.text.isNotEmpty
            ? IconButton(
                onPressed: () {
                  searchController.clear();
                  applyFilters();
                },
                icon: const Icon(Icons.close),
              )
            : null,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(
            color: Color(0xFFE8EAF0),
          ),
        ),
      ),
    );
  }

  Widget filterButtons() {
    final bool hasFilter =
        selectedExactDate != null ||
        selectedMonth != null ||
        searchController.text.isNotEmpty;

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        OutlinedButton.icon(
          onPressed: selectExactDate,
          icon: const Icon(
            Icons.calendar_today_outlined,
          ),
          label: Text(
            selectedExactDate == null
                ? 'Select Date'
                : formatDisplayDate(
                    selectedExactDate!
                        .toIso8601String(),
                  ),
          ),
        ),
        OutlinedButton.icon(
          onPressed: selectMonth,
          icon: const Icon(
            Icons.calendar_month_outlined,
          ),
          label: Text(
            selectedMonth == null
                ? 'Select Month'
                : '${monthName(selectedMonth!.month)} '
                    '${selectedMonth!.year}',
          ),
        ),
        if (hasFilter)
          TextButton.icon(
            onPressed: clearFilters,
            icon: const Icon(Icons.refresh),
            label: const Text('Clear'),
          ),
      ],
    );
  }

  Widget resultsHeader() {
    return Row(
      children: [
        const Text(
          'Saved Bills',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const Spacer(),
        Text(
          '${filteredBills.length} records',
          style: const TextStyle(
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget billsList() {
    if (filteredBills.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          vertical: 45,
          horizontal: 20,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Column(
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 50,
              color: Colors.grey,
            ),
            SizedBox(height: 12),
            Text(
              'No service bills found',
              style: TextStyle(
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Tap Add Bill to save your first service bill.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filteredBills.length,
      separatorBuilder: (_, _) {
        return const SizedBox(height: 12);
      },
      itemBuilder: (context, index) {
        final bill = filteredBills[index];

        final double amount =
            getDouble(bill['total_amount']);

        final double odometer =
            getDouble(bill['odometer']);

        return Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFEDEFF3),
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 55,
                    height: 55,
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(
                        alpha: 0.10,
                      ),
                      borderRadius:
                          BorderRadius.circular(15),
                    ),
                    child: const Icon(
                      Icons.receipt_long_outlined,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          bill['service_type']
                                      ?.toString()
                                      .trim()
                                      .isNotEmpty ==
                                  true
                              ? bill['service_type']
                                  .toString()
                              : 'Bike Service',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          bill['service_center']
                                      ?.toString()
                                      .trim()
                                      .isNotEmpty ==
                                  true
                              ? bill['service_center']
                                  .toString()
                              : 'Service centre not added',
                          style: const TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        openEditBillPage(bill);
                      } else if (value == 'delete') {
                        deleteBill(bill);
                      }
                    },
                    itemBuilder: (context) {
                      return const [
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_outlined),
                              SizedBox(width: 10),
                              Text('Edit'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                              ),
                              SizedBox(width: 10),
                              Text(
                                'Delete',
                                style: TextStyle(
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ];
                    },
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: informationItem(
                      'Service Date',
                      formatDisplayDate(
                        bill['service_date'],
                      ),
                    ),
                  ),
                  Expanded(
                    child: informationItem(
                      'Amount',
                      amount == 0
                          ? '--'
                          : '₹${amount.toStringAsFixed(0)}',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: informationItem(
                      'Odometer',
                      odometer == 0
                          ? '--'
                          : '${odometer.toStringAsFixed(0)} km',
                    ),
                  ),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          openBillImage(bill);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              primaryColor.withValues(
                            alpha: 0.10,
                          ),
                          foregroundColor: primaryColor,
                          elevation: 0,
                        ),
                        icon: const Icon(
                          Icons.visibility_outlined,
                        ),
                        label: const Text('View Bill'),
                      ),
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

  Widget informationItem(
    String label,
    String value,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

// ===========================================================
// ADD / EDIT SERVICE BILL PAGE
// ===========================================================

class AddEditServiceBillPage extends StatefulWidget {
  final String bikeId;
  final Map<String, dynamic>? existingBill;

  const AddEditServiceBillPage({
    super.key,
    required this.bikeId,
    this.existingBill,
  });

  @override
  State<AddEditServiceBillPage> createState() =>
      _AddEditServiceBillPageState();
}

class _AddEditServiceBillPageState
    extends State<AddEditServiceBillPage> {
  static const Color primaryColor = Color(0xFFFF5A1F);
  static const String bucketName = 'bike-documents';

  final SupabaseClient supabase = Supabase.instance.client;
  final ImagePicker imagePicker = ImagePicker();

  final TextEditingController serviceCenterController =
      TextEditingController();

  final TextEditingController serviceTypeController =
      TextEditingController();

  final TextEditingController odometerController =
      TextEditingController();

  final TextEditingController amountController =
      TextEditingController();

  final TextEditingController notesController =
      TextEditingController();

  DateTime? serviceDate;

  File? selectedBillImage;

  String? existingImagePath;
  String? existingSignedUrl;

  bool saving = false;

  bool get isEditing => widget.existingBill != null;

  @override
  void initState() {
    super.initState();
    loadExistingValues();
  }

  @override
  void dispose() {
    serviceCenterController.dispose();
    serviceTypeController.dispose();
    odometerController.dispose();
    amountController.dispose();
    notesController.dispose();
    super.dispose();
  }

  Future<void> loadExistingValues() async {
    final bill = widget.existingBill;

    if (bill == null) {
      serviceDate = DateTime.now();
      return;
    }

    serviceCenterController.text =
        bill['service_center']?.toString() ?? '';

    serviceTypeController.text =
        bill['service_type']?.toString() ?? '';

    odometerController.text =
        bill['odometer']?.toString() ?? '';

    amountController.text =
        bill['total_amount']?.toString() ?? '';

    notesController.text =
        bill['notes']?.toString() ?? '';

    serviceDate = DateTime.tryParse(
      bill['service_date']?.toString() ?? '',
    );

    existingImagePath =
        bill['bill_image_path']?.toString();

    existingSignedUrl =
        bill['signed_url']?.toString();

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> pickBillImage(
    ImageSource source,
  ) async {
    try {
      final XFile? result =
          await imagePicker.pickImage(
        source: source,
        imageQuality: 82,
        maxWidth: 1800,
      );

      if (result == null || !mounted) return;

      setState(() {
        selectedBillImage = File(result.path);
      });
    } catch (error) {
      if (!mounted) return;

      showMessage(
        'Unable to select image: $error',
        success: false,
      );
    }
  }

  void showImageSourceSheet() {
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
          padding: const EdgeInsets.fromLTRB(
            20,
            8,
            20,
            30,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Upload Service Bill',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
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

                        pickBillImage(
                          ImageSource.camera,
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

                        pickBillImage(
                          ImageSource.gallery,
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
        padding: const EdgeInsets.symmetric(
          vertical: 22,
        ),
        decoration: BoxDecoration(
          color: primaryColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(18),
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

  Future<void> selectServiceDate() async {
    final DateTime? result = await showDatePicker(
      context: context,
      initialDate: serviceDate ?? DateTime.now(),
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

    if (result == null || !mounted) return;

    setState(() {
      serviceDate = result;
    });
  }

  String getFileExtension(File file) {
    final String path = file.path.toLowerCase();

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

  Future<String> uploadBillImage(
    File image,
  ) async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      throw Exception('User is not logged in.');
    }

    final String extension =
        getFileExtension(image);

    final String datePart =
        databaseDate(serviceDate) ?? 'unknown-date';

    final String fileName =
        '${DateTime.now().millisecondsSinceEpoch}.$extension';

    final String storagePath =
        '${user.id}/${widget.bikeId}/service-bills/'
        '${datePart}_$fileName';

    await supabase.storage
        .from(bucketName)
        .upload(
          storagePath,
          image,
          fileOptions: FileOptions(
            upsert: false,
            contentType:
                getContentType(extension),
          ),
        );

    return storagePath;
  }

  Future<void> saveBill() async {
    if (saving) return;

    final user = supabase.auth.currentUser;

    if (user == null) {
      showMessage(
        'Please login first.',
        success: false,
      );
      return;
    }

    if (serviceDate == null) {
      showMessage(
        'Please select the service date.',
        success: false,
      );
      return;
    }

    final bool hasImage =
        selectedBillImage != null ||
        (existingImagePath?.isNotEmpty ?? false);

    if (!hasImage) {
      showMessage(
        'Please upload the service bill image.',
        success: false,
      );
      return;
    }

    try {
      setState(() {
        saving = true;
      });

      String? imagePath = existingImagePath;

      if (selectedBillImage != null) {
        final String newImagePath =
            await uploadBillImage(
          selectedBillImage!,
        );

        if (isEditing &&
            existingImagePath != null &&
            existingImagePath!.isNotEmpty) {
          await supabase.storage
              .from(bucketName)
              .remove([existingImagePath!]);
        }

        imagePath = newImagePath;
      }

      final Map<String, dynamic> values = {
        'user_id': user.id,
        'bike_id': widget.bikeId,
        'service_date':
            databaseDate(serviceDate),
        'service_center':
            emptyToNull(
          serviceCenterController.text,
        ),
        'service_type':
            emptyToNull(
          serviceTypeController.text,
        ),
        'odometer': double.tryParse(
          odometerController.text.trim(),
        ),
        'total_amount': double.tryParse(
          amountController.text.trim(),
        ),
        'notes':
            emptyToNull(notesController.text),
        'bill_image_path': imagePath,
        'updated_at':
            DateTime.now().toIso8601String(),
      };

      if (isEditing) {
        await supabase
            .from('service_bills')
            .update(values)
            .eq(
              'id',
              widget.existingBill!['id'],
            );
      } else {
        await supabase
            .from('service_bills')
            .insert(values);
      }

      if (!mounted) return;

      showMessage(
        isEditing
            ? 'Service bill updated successfully.'
            : 'Service bill saved successfully.',
        success: true,
      );

      Navigator.pop(context, true);
    } on StorageException catch (error) {
      if (!mounted) return;

      showMessage(
        'Image upload failed: ${error.message}',
        success: false,
      );
    } on PostgrestException catch (error) {
      debugPrint(
        'Service bill database error: '
        '${error.message}',
      );

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
        setState(() {
          saving = false;
        });
      }
    }
  }

  String? emptyToNull(String value) {
    final String result = value.trim();

    return result.isEmpty ? null : result;
  }

  String? databaseDate(DateTime? date) {
    if (date == null) return null;

    final String year = date.year.toString();

    final String month =
        date.month.toString().padLeft(2, '0');

    final String day =
        date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  String formatDisplayDate(DateTime? date) {
    if (date == null) return 'Select date';

    final String day =
        date.day.toString().padLeft(2, '0');

    final String month =
        date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
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

  @override
  Widget build(BuildContext context) {
    final bool hasImage =
        selectedBillImage != null ||
        (existingSignedUrl?.isNotEmpty ?? false);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        foregroundColor: Colors.black,
        title: Text(
          isEditing
              ? 'Edit Service Bill'
              : 'Add Service Bill',
          style: const TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding:
            const EdgeInsets.fromLTRB(18, 16, 18, 120),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            billImageCard(hasImage),
            const SizedBox(height: 22),
            const Text(
              'Service Details',
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
      bottomNavigationBar: saveButton(),
    );
  }

  Widget billImageCard(bool hasImage) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: hasImage
          ? Column(
              children: [
                ClipRRect(
                  borderRadius:
                      BorderRadius.circular(18),
                  child: SizedBox(
                    width: double.infinity,
                    height: 220,
                    child: selectedBillImage != null
                        ? Image.file(
                            selectedBillImage!,
                            fit: BoxFit.cover,
                          )
                        : Image.network(
                            existingSignedUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (
                              context,
                              error,
                              stackTrace,
                            ) {
                              return const Center(
                                child: Text(
                                  'Unable to load bill image',
                                ),
                              );
                            },
                          ),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed:
                      saving ? null : showImageSourceSheet,
                  icon: const Icon(
                    Icons.refresh,
                  ),
                  label: const Text(
                    'Replace Bill Image',
                  ),
                ),
              ],
            )
          : InkWell(
              onTap:
                  saving ? null : showImageSourceSheet,
              borderRadius:
                  BorderRadius.circular(18),
              child: Container(
                height: 190,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FB),
                  borderRadius:
                      BorderRadius.circular(18),
                  border: Border.all(
                    color:
                        const Color(0xFFE2E5EA),
                  ),
                ),
                child: const Column(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons
                          .add_photo_alternate_outlined,
                      color: primaryColor,
                      size: 42,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Upload Service Bill',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Take a photo or select from gallery',
                      style: TextStyle(
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
          dateField(),
          const SizedBox(height: 16),
          inputField(
            controller: serviceCenterController,
            label: 'Service Centre',
            hint: 'Example: ABC Motors',
            icon: Icons.store_outlined,
          ),
          const SizedBox(height: 16),
          inputField(
            controller: serviceTypeController,
            label: 'Service Type',
            hint: 'Example: General Service',
            icon: Icons.build_outlined,
          ),
          const SizedBox(height: 16),
          inputField(
            controller: odometerController,
            label: 'Odometer',
            hint: 'Example: 12500',
            icon: Icons.speed_outlined,
            keyboardType:
                const TextInputType.numberWithOptions(
              decimal: true,
            ),
          ),
          const SizedBox(height: 16),
          inputField(
            controller: amountController,
            label: 'Total Amount',
            hint: 'Example: 1850',
            icon: Icons.currency_rupee,
            keyboardType:
                const TextInputType.numberWithOptions(
              decimal: true,
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: notesController,
            enabled: !saving,
            minLines: 3,
            maxLines: 5,
            decoration: InputDecoration(
              labelText: 'Notes',
              hintText:
                  'Oil changed, brake checked...',
              alignLabelWithHint: true,
              prefixIcon: const Padding(
                padding: EdgeInsets.only(
                  bottom: 55,
                ),
                child: Icon(
                  Icons.notes,
                  color: primaryColor,
                ),
              ),
              filled: true,
              fillColor:
                  const Color(0xFFF8F9FB),
              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget inputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      enabled: !saving,
      keyboardType: keyboardType,
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
        ),
      ),
    );
  }

  Widget dateField() {
    return InkWell(
      onTap: saving ? null : selectServiceDate,
      borderRadius: BorderRadius.circular(16),
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
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Service Date',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatDisplayDate(serviceDate),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down,
              color: Colors.grey,
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
            onPressed: saving ? null : saveBill,
            icon: saving
                ? const SizedBox(
                    width: 21,
                    height: 21,
                    child:
                        CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.4,
                    ),
                  )
                : const Icon(
                    Icons.save_outlined,
                  ),
            label: Text(
              saving
                  ? 'Saving Bill...'
                  : isEditing
                      ? 'Update Service Bill'
                      : 'Save Service Bill',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
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

// ===========================================================
// FULL-SCREEN BILL IMAGE VIEWER
// ===========================================================

class ServiceBillImageViewer extends StatelessWidget {
  final String imageUrl;
  final String title;

  const ServiceBillImageViewer({
    super.key,
    required this.imageUrl,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(title),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.8,
          maxScale: 5,
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
            loadingBuilder: (
              context,
              child,
              progress,
            ) {
              if (progress == null) {
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
              return const Text(
                'Unable to load service bill',
                style: TextStyle(
                  color: Colors.white,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}