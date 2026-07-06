import 'package:flutter/material.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  static const primary = Color(0xFFFF5A1F);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070B14),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "About Us",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  primary.withOpacity(.95),
                  const Color(0xFF7C2D12),
                ],
              ),
              borderRadius: BorderRadius.circular(26),
            ),
            child: const Column(
              children: [
                Icon(Icons.motorcycle, color: Colors.white, size: 60),
                SizedBox(height: 12),
                Text(
                  "RideSmart",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  "Smart bike service and ride tracking app",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          sectionCard(
            icon: Icons.info_outline,
            title: "Who We Are",
            text:
                "RideSmart helps bike users manage fuel records, service history, trips, expenses, and bike details in one simple app.",
          ),

          sectionCard(
            icon: Icons.flag_outlined,
            title: "Our Mission",
            text:
                "Our mission is to make bike maintenance simple, organized, and smart for every rider.",
          ),

          sectionCard(
            icon: Icons.star_outline,
            title: "Key Features",
            text:
                "Fuel tracker, mileage calculation, service records, trip history, bike profile, notifications, and smart dashboard.",
          ),

          sectionCard(
            icon: Icons.verified_outlined,
            title: "App Version",
            text: "Version 1.0.0",
          ),

          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: primary.withOpacity(.15),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: primary.withOpacity(.35)),
            ),
            child: const Column(
              children: [
                Icon(Icons.favorite, color: primary),
                SizedBox(height: 8),
                Text(
                  "Built with Flutter & Supabase",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  "Designed for riders who love smart maintenance.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white60),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget sectionCard({
    required IconData icon,
    required String title,
    required String text,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: primary),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  text,
                  style: const TextStyle(
                    color: Colors.white54,
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
}