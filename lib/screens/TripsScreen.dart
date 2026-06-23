import 'package:bikeservice/screens/ProfileScreen.dart';
import 'package:bikeservice/screens/fuel.dart';
import 'package:bikeservice/screens/home.dart';
import 'package:bikeservice/screens/service.dart';
import 'package:flutter/material.dart';

class TripsScreen extends StatefulWidget {
  const TripsScreen({super.key});

  @override
  State<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends State<TripsScreen> {
  int selectedIndex = 3;
  int selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFFFF5A1F);

    return Scaffold(
      backgroundColor: const Color(0xFF070B14),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Trip History",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: const BackButton(color: Colors.white),
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
          }if (index == 2) {
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
          }if (index == 4) {
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
      body: SafeArea(
        
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  buildTab("All", 0),
                  const SizedBox(width: 10),
                  buildTab("This Month", 1),
                  const SizedBox(width: 10),
                  buildTab("This Year", 2),
                ],
              ),

              const SizedBox(height: 20),

              Container(
                height: 220,
                decoration: BoxDecoration(
                  color: const Color(0xFF111827),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.network(
                          "https://images.unsplash.com/photo-1524661135-423995f22d0b?w=1200",
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),

                    Positioned(
                      left: 40,
                      bottom: 70,
                      child: mapMarker(Colors.green),
                    ),

                    Positioned(
                      left: 140,
                      bottom: 90,
                      child: mapMarker(Colors.blue),
                    ),

                    Positioned(
                      right: 50,
                      top: 50,
                      child: mapMarker(Colors.red),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Expanded(
                child: ListView(
                  children: [
                    tripCard(
                      date: "12 May 2024",
                      title: "Morning Ride",
                      distance: "12.4 km",
                      duration: "25 min",
                      fuel: "0.6 L",
                    ),

                    const SizedBox(height: 15),

                    tripCard(
                      date: "11 May 2024",
                      title: "City Ride",
                      distance: "8.7 km",
                      duration: "20 min",
                      fuel: "0.4 L",
                    ),

                    const SizedBox(height: 15),

                    tripCard(
                      date: "08 May 2024",
                      title: "Office Ride",
                      distance: "16.8 km",
                      duration: "32 min",
                      fuel: "0.8 L",
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildTab(String title, int index) {
    bool isSelected = selectedTab == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedTab = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFF5A1F) : const Color(0xFF111827),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(title, style: const TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget mapMarker(Color color) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
    );
  }

  Widget tripCard({
    required String date,
    required String title,
    required String distance,
    required String duration,
    required String fuel,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(date, style: const TextStyle(color: Colors.white54)),

          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: Colors.white54,
                size: 16,
              ),
            ],
          ),

          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(child: statItem(distance, "Distance")),
              Expanded(child: statItem(duration, "Duration")),
              Expanded(child: statItem(fuel, "Fuel Used")),
            ],
          ),
        ],
      ),
    );
  }

  Widget statItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
      ],
    );
  }
}
