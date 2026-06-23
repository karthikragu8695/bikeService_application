import 'package:flutter/material.dart';

void showAddServiceDialog(BuildContext context) {
  final dateController = TextEditingController();
  final serviceController = TextEditingController();
  final costController = TextEditingController();
  final nextServiceController = TextEditingController();
  final notesController = TextEditingController();

  const primary = Color(0xFFFF5A1F);

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF111827),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(25),
      ),
    ),
    builder: (context) {
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
              ),

              const SizedBox(height: 12),

              serviceField(
                controller: nextServiceController,
                label: "Next Service At (KM)",
                icon: Icons.speed,
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
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text(
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
}

Widget serviceField({
  required TextEditingController controller,
  required String label,
  required IconData icon,
}) {
  return TextField(
    controller: controller,
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