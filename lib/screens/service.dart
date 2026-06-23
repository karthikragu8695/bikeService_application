import 'package:bikeservice/screens/ProfileScreen.dart';
import 'package:bikeservice/screens/TripsScreen.dart';
import 'package:bikeservice/screens/fuel.dart';
import 'package:bikeservice/screens/home.dart';
import 'package:bikeservice/widget/Addservice.dart';
import 'package:flutter/material.dart';

class ServiceScreen extends StatefulWidget {
  const ServiceScreen({super.key});

  @override
  State<ServiceScreen> createState() => _ServiceScreenState();
}

class _ServiceScreenState extends State<ServiceScreen> {
  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFFFF5A1F);
    int selectedIndex = 2;

    return Scaffold(
      backgroundColor: const Color(0xFF070B14),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        centerTitle: true,
        title: const Text(
          "Service Tracker",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        backgroundColor: const Color(0xFF0F172A),
        selectedItemColor: primary,
        unselectedItemColor: Colors.white54,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            selectedIndex = index;
          });
          if (index == 0) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HomeScreen()),
            );
          }
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FuelScreen()),
            );
          }
          if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ServiceScreen()),
            );
          }
          if (index == 3) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TripsScreen()),
            );
          }
          if (index == 4) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_gas_station),
            label: "Fuel",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.build), label: "Service"),
          BottomNavigationBarItem(icon: Icon(Icons.route), label: "Trips"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                children: [
                  serviceItem(
                    icon: Icons.check,
                    color: Colors.green,
                    title: "Oil Change",
                    date: "12 May 2024",
                    amount: "₹ 800",
                  ),

                  serviceItem(
                    icon: Icons.check,
                    color: Colors.green,
                    title: "Chain Service",
                    date: "10 Mar 2024",
                    amount: "₹ 300",
                  ),

                  serviceItem(
                    icon: Icons.check,
                    color: Colors.green,
                    title: "General Service",
                    date: "10 Jan 2024",
                    amount: "₹ 600",
                  ),

                  serviceItem(
                    icon: Icons.build,
                    color: Colors.orange,
                    title: "Next Service",
                    date: "1200 km remaining\nEstimated: 10 Aug 2024",
                    amount: "",
                    isLast: true,
                  ),

                  const SizedBox(height: 25),

                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        showAddServiceDialog(context);
                      },
                      icon: const Icon(Icons.add, color: Colors.white),
                      label: const Text(
                        "Add Service",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFF111827),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                "Total Service Cost",
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 14,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                "₹ 1,700",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 30,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                "This Year",
                                style: TextStyle(color: Colors.white54),
                              ),
                            ],
                          ),
                        ),

                        Icon(
                          Icons.miscellaneous_services,
                          size: 80,
                          color: Colors.white.withOpacity(.15),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget serviceItem({
    required IconData icon,
    required Color color,
    required String title,
    required String date,
    required String amount,
    bool isLast = false,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: color,
                child: Icon(icon, color: Colors.white, size: 20),
              ),

              if (!isLast)
                Expanded(
                  child: Container(
                    width: 3,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: Colors.green,
                  ),
                ),
            ],
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date,
                    style: const TextStyle(color: Colors.white54, height: 1.4),
                  ),
                  const SizedBox(height: 25),
                ],
              ),
            ),
          ),

          if (amount.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                amount,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
