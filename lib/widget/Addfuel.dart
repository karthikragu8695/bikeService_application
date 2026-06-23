import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<bool?> showAddFuelDialog(BuildContext context) {
  final supabase = Supabase.instance.client;

  final dateController = TextEditingController();
  final odoController = TextEditingController();
  final quantityController = TextEditingController();
  final priceController = TextEditingController();
  final totalController = TextEditingController();
  final notesController = TextEditingController();

  bool isLoading = false;
  const primary = Color(0xFFFF5A1F);

  dateController.text = DateTime.now().toString().split(' ')[0];

  void calculateTotal() {
    final qty = double.tryParse(quantityController.text) ?? 0;
    final price = double.tryParse(priceController.text) ?? 0;
    final total = qty * price;
    totalController.text = total == 0 ? '' : total.toStringAsFixed(2);
  }

  Future<void> saveFuel(StateSetter setModalState) async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("User not logged in")));
      return;
    }

    if (odoController.text.isEmpty ||
        quantityController.text.isEmpty ||
        priceController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Fill required fields")));
      return;
    }

    try {
      setModalState(() => isLoading = true);

      final bike = await supabase
          .from('bikes')
          .select('id')
          .eq('user_id', user.id)
          .maybeSingle();

      await supabase.from('fuel_entries').insert({
        'bike_id': bike?['id'],
        'fuel_date': dateController.text.trim(),
        'liters': double.tryParse(quantityController.text.trim()) ?? 0,
        'amount': double.tryParse(totalController.text.trim()) ?? 0,
        'price_per_liter': double.tryParse(priceController.text.trim()) ?? 0,
        'odometer': int.tryParse(odoController.text.trim()) ?? 0,
        'mileage': 0,
        'notes': notesController.text.trim(),
      });

      if (context.mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Fuel saved successfully")),
        );
      }
    } catch (e) {
      debugPrint("Fuel Save Error: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setModalState(() => isLoading = false);
    }
  }

  return showModalBottomSheet<bool>(
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
                    "Add Fuel",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),

                  fuelField(
                    controller: dateController,
                    label: "Date",
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
                  fuelField(
                    controller: odoController,
                    label: "Odometer Reading",
                    icon: Icons.speed,
                    keyboardType: TextInputType.number,
                  ),

                  const SizedBox(height: 12),
                  fuelField(
                    controller: quantityController,
                    label: "Fuel Quantity (Liters)",
                    icon: Icons.local_gas_station,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => calculateTotal(),
                  ),

                  const SizedBox(height: 12),
                  fuelField(
                    controller: priceController,
                    label: "Price / Liter",
                    icon: Icons.currency_rupee,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => calculateTotal(),
                  ),

                  const SizedBox(height: 12),
                  fuelField(
                    controller: totalController,
                    label: "Total Amount",
                    icon: Icons.payments,
                    readOnly: true,
                  ),

                  const SizedBox(height: 12),
                  fuelField(
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
                              saveFuel(setModalState);
                            },
                      child: isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              "Save",
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

Widget fuelField({
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
