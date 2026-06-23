import 'package:bikeservice/screens/ProfileScreen.dart';
import 'package:bikeservice/screens/TripsScreen.dart';
import 'package:bikeservice/screens/fuel.dart';
import 'package:bikeservice/screens/service.dart';
import 'package:bikeservice/widget/Addfuel.dart' show showAddFuelDialog;
import 'package:bikeservice/widget/Addservice.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static Widget actionButton(
    String title,
    Color color,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 55,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final supabase = Supabase.instance.client;

  int selectedIndex = 0;

  String riderName = "Rider";
  Map<String, dynamic>? bikeData;

  double fuelLevelPercent = 0;

  @override
  void initState() {
    super.initState();
    getUserData();
    getBike();
  }

  Future<void> getUserData() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final data = await supabase
          .from('users')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (data != null && mounted) {
        setState(() {
          riderName = data['name'] ?? "Rider";
        });
      }
    } catch (e) {
      debugPrint("User Load Error: $e");
    }
  }

  Future<void> getBike() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final data = await supabase
          .from('bikes')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();

      if (data != null && mounted) {
        setState(() {
          bikeData = data;
        });

        await getFuelEntries();
      }
    } catch (e) {
      debugPrint("Bike Load Error: $e");
    }
  }

  Future<void> getFuelEntries() async {
    try {
      if (bikeData == null) {
        debugPrint("Bike data null");
        return;
      }

      final latestFuel = await supabase
          .from('fuel_entries')
          .select()
          .eq('bike_id', bikeData!['id'])
          .order('fuel_date', ascending: false)
          .limit(1)
          .maybeSingle();

      debugPrint("Latest Fuel: $latestFuel");

      final liters = (latestFuel?['liters'] as num?)?.toDouble() ?? 0.0;
      const tankCapacity = 13.0;

      final percent = ((liters / tankCapacity) * 100).clamp(0.0, 100.0);

      if (mounted) {
        setState(() {
          fuelLevelPercent = percent;
        });
      }
    } catch (e) {
      debugPrint("Fuel Entries Load Error: $e");
    }
  }

  void changeScreen(int index) {
    if (index == selectedIndex) return;

    Widget screen;

    switch (index) {
      case 0:
        screen = const HomeScreen();
        break;
      case 1:
        screen = const FuelScreen();
        break;
      case 2:
        screen = const ServiceScreen();
        break;
      case 3:
        screen = const TripsScreen();
        break;
      case 4:
        screen = const ProfileScreen();
        break;
      default:
        return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  Widget bikeImageWidget() {
    final String bikeImageUrl = bikeData?['image_url'] ?? '';

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: bikeImageUrl.isNotEmpty
          ? Image.network(
              bikeImageUrl,
              width: 100,
              height: 70,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) {
                return bikeAssetImage();
              },
            )
          : bikeAssetImage(),
    );
  }

  Widget bikeAssetImage() {
    return Image.asset(
      "assets/images/bike.png",
      width: 100,
      height: 100,
      fit: BoxFit.cover,
    );
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFFFF5A1F);

    return Scaffold(
      backgroundColor: const Color(0xFF070B14),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        backgroundColor: const Color(0xFF0F172A),
        selectedItemColor: primary,
        unselectedItemColor: Colors.white54,
        type: BottomNavigationBarType.fixed,
        onTap: changeScreen,
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
          child: ListView(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Good Morning,",
                        style: TextStyle(color: Colors.white70),
                      ),
                      Text(
                        "$riderName 👋",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Icon(Icons.notifications_none, color: Colors.white),
                ],
              ),

              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF111827),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    bikeImageWidget(),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            bikeData?['bike_name'] ?? "No Bike Added",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            bikeData?['registration_no'] ?? "Add bike details",
                            style: const TextStyle(color: Colors.white54),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        "Active",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.4,
                children: [
                  DashboardTile(
                    title: "Fuel Level",
                    value: "${fuelLevelPercent.toStringAsFixed(0)}%",
                    color: Colors.cyan,
                    icon: Icons.local_gas_station,
                  ),
                  const DashboardTile(
                    title: "Service Due",
                    value: "1200 km",
                    color: Colors.orange,
                    icon: Icons.access_time,
                  ),
                  const DashboardTile(
                    title: "Mileage",
                    value: "45.2",
                    color: Colors.deepOrange,
                    icon: Icons.speed,
                  ),
                  const DashboardTile(
                    title: "Trips",
                    value: "12",
                    color: Colors.lightBlue,
                    icon: Icons.route,
                  ),
                ],
              ),

              const SizedBox(height: 20),

              const Text(
                "Quick Actions",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: HomeScreen.actionButton(
                      "Add Fuel",
                      primary,
                      Icons.local_gas_station,
                      () async {
                        final result = await showAddFuelDialog(context);

                        if (result == true) {
                          await getBike();
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: HomeScreen.actionButton(
                      "Add Service",
                      Colors.blue,
                      Icons.build,
                      () {
                        showAddServiceDialog(context);
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              Row(
                children: [
                  const Text(
                    "Recent Activity",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {},
                    child: const Text(
                      "See All",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 15),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF111827),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    serviceTile(
                      Icons.oil_barrel,
                      Colors.green,
                      "Oil Change",
                      "12 May 2024",
                      "₹ 800",
                    ),
                    const SizedBox(height: 12),
                    serviceTile(
                      Icons.build,
                      Colors.green,
                      "Chain Service",
                      "10 Mar 2024",
                      "₹ 300",
                    ),
                    const SizedBox(height: 12),
                    serviceTile(
                      Icons.settings,
                      Colors.orange,
                      "Next Service",
                      "1200 km remaining",
                      "₹ 600",
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
}

class DashboardTile extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData icon;

  const DashboardTile({
    super.key,
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(title, style: const TextStyle(color: Colors.white54)),
        ],
      ),
    );
  }
}

Widget serviceTile(
  IconData icon,
  Color color,
  String title,
  String date,
  String amount,
) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFF0F172A),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: [
        CircleAvatar(
          backgroundColor: color,
          child: Icon(icon, color: Colors.white),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(date, style: const TextStyle(color: Colors.white54)),
            ],
          ),
        ),
        Text(
          amount,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );
}