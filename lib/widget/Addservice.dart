import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<bool?> showAddServiceDialog(BuildContext context) async {
  final dateController = TextEditingController();
  final serviceController = TextEditingController();
  final costController = TextEditingController();
  final nextServiceController = TextEditingController();
  final notesController = TextEditingController();

  const primary = Color(0xFFFF5A1F);
  final supabase = Supabase.instance.client;

  bool isLoading = false;

  dateController.text = DateTime.now().toIso8601String().split('T')[0];

  Future<void> saveService(StateSetter setModalState) async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("User not logged in")));
      return;
    }

    if (serviceController.text.trim().isEmpty ||
        costController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Service Type and Cost required")),
      );
      return;
    }

    try {
      setModalState(() => isLoading = true);

      final bikes = await supabase
          .from('bikes')
          .select('id')
          .eq('user_id', user.id)
          .limit(1);

      if (bikes.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Bike not found")));
        return;
      }

      final bikeId = bikes[0]['id'];

      await supabase.from('services').insert({
        'user_id': user.id,
        'bike_id': bikeId,
        'service_date': dateController.text.trim(),
        'service_type': serviceController.text.trim(),
        'cost': double.tryParse(costController.text.trim()) ?? 0,
        'next_service_km': int.tryParse(nextServiceController.text.trim()) ?? 0,
        'notes': notesController.text.trim(),
      });

      if (context.mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Service saved successfully")),
        );
      }
    } catch (e) {
      debugPrint("SERVICE SAVE ERROR: $e");

      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }

    if (context.mounted) {
      setModalState(() => isLoading = false);
    }
  }

  return await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF111827),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
    ),
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 60,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    "Add Service",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 20),

                  serviceField(
                    controller: dateController,
                    label: "Service Date",
                    icon: Icons.calendar_month,
                    readOnly: true,
                    onTap: () async {
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );

                      if (pickedDate != null) {
                        dateController.text = pickedDate.toString().split(
                          ' ',
                        )[0];
                      }
                    },
                  ),

                  const SizedBox(height: 12),

                  serviceField(
                    controller: serviceController,
                    label: "Service Type",
                    icon: Icons.build,
                  ),

                  const SizedBox(height: 12),

                  serviceField(
                    controller: costController,
                    label: "Service Cost",
                    icon: Icons.currency_rupee,
                    keyboardType: TextInputType.number,
                  ),

                  const SizedBox(height: 12),

                  serviceField(
                    controller: nextServiceController,
                    label: "Next Service At (KM)",
                    icon: Icons.speed,
                    keyboardType: TextInputType.number,
                  ),

                  const SizedBox(height: 12),

                  serviceField(
                    controller: notesController,
                    label: "Notes",
                    icon: Icons.note_alt_outlined,
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: isLoading
                          ? null
                          : () {
                              saveService(setModalState);
                            },
                      child: isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              "Save Service",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

Widget serviceField({
  required TextEditingController controller,
  required String label,
  required IconData icon,
  TextInputType keyboardType = TextInputType.text,
  bool readOnly = false,
  VoidCallback? onTap,
  Function(String)? onChanged,
}) {
  return TextField(
    controller: controller,
    readOnly: readOnly,
    onTap: onTap,
    onChanged: onChanged,
    keyboardType: keyboardType,
    style: const TextStyle(color: Colors.white),
    decoration: InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white54),
      prefixIcon: Icon(icon, color: Colors.white54),
      filled: true,
      fillColor: const Color(0xFF1A2234),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    ),
  );
}
