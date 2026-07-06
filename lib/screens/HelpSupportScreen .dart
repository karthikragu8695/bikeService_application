import 'package:flutter/material.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  static const primary = Color(0xFFFF5A1F);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070B14),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Help & Support",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF111827),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              children: const [
                Icon(Icons.support_agent, color: primary, size: 55),
                SizedBox(height: 12),
                Text(
                  "How can we help you?",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "Get support for account, bike details, fuel, service, and trips.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white54),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          helpTile(Icons.person_outline, "Account Help",
              "Login, signup, and profile issues"),
          helpTile(Icons.motorcycle, "Bike Details",
              "Add or update your bike information"),
          helpTile(Icons.local_gas_station, "Fuel Tracker",
              "Fuel entries, mileage, and expenses"),
          helpTile(Icons.build, "Service History",
              "Manage service records and reminders"),
          helpTile(Icons.route, "Trips",
              "Track trips, distance, and ride details"),
          const SizedBox(height: 20),
          contactCard(),
        ],
      ),
    );
  }

  static Widget helpTile(IconData icon, String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Icon(icon, color: primary),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: const TextStyle(color: Colors.white54, fontSize: 13)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.white54),
        ],
      ),
    );
  }

  static Widget contactCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: primary.withOpacity(.15),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: primary.withOpacity(.35)),
      ),
      child: Column(
        children: const [
          Icon(Icons.email_outlined, color: primary, size: 34),
          SizedBox(height: 10),
          Text(
            "Contact Support",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 6),
          Text(
            "support@ridesmart.com",
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}