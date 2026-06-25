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
  int serviceDueKm = 0;
  int selectedIndex = 0;
  List<dynamic> recentServices = [];
  double mileage = 0;

  String riderName = "Rider";
  Map<String, dynamic>? bikeData;

  double fuelLevelPercent = 0;

  @override
  void initState() {
    super.initState();
    getRecentServices();
    getServiceDue();
    getUserData();
    getBike();
    getMileage();
  }

  Future<void> getMileage() async {
    try {
      final User = supabase.auth.currentUser;
      if (User == null) return;

      final bike = await supabase
          .from('bikes')
          .select('id')
          .eq('user_id', User.id)
          .maybeSingle();
      if (bike == null) return;
      final fuel = await supabase
          .from('fuel_entries')
          .select('odometer,liters')
          .eq('bike_id', bike['id'])
          .order('fuel_date', ascending: false)
          .limit(2);
      if (fuel.length < 2) return;
      final latest = fuel[0];
      final previous = fuel[1];
      final distance =
          (latest['odometer'] as num) - (previous['odometer'] as num);
      final liters = (latest['liters'] as num).toDouble();
      if (liters <= 0) {
        setState(() {
          mileage = distance / liters;
        });
      }
    } catch (e) {
      debugPrint('Mileage error: $e');
    }
  }

  Future<void> getServiceDue() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final bike = await supabase
        .from('bikes')
        .select('id, current_km')
        .eq('user_id', user.id)
        .maybeSingle();

    if (bike == null) return;

    final service = await supabase
        .from('services')
        .select('next_service_km')
        .eq('bike_id', bike['id'])
        .order('service_date', ascending: false)
        .limit(1)
        .maybeSingle();
    if (!mounted) return;
    if (service == null) return;

    final currentKm = bike['current_km'] ?? 0;
    final nextKm = service['next_service_km'] ?? 0;

    setState(() {
      serviceDueKm = nextKm - currentKm;
      if (serviceDueKm < 0) serviceDueKm = 0;
    });
  }

  Future<void> getRecentServices() async {
    try {
      final User = supabase.auth.currentUser;
      if (User == null) return;
      final data = await supabase
          .from('services')
          .select()
          .eq('user_id', User.id)
          .order('service_date', ascending: false)
          .limit(3);
      if (mounted) {
        setState(() {
          recentServices = data;
        });
      }
    } catch (e) {
      debugPrint("Recet service Load error:$e");
    }
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
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final bike = await supabase
          .from('bikes')
          .select('id')
          .eq('user_id', user.id)
          .maybeSingle();

      if (bike == null) return;

      final fuelData = await supabase
          .from('fuel_entries')
          .select('liters')
          .eq('bike_id', bike['id']);

      double totalLiters = 0;

      for (final item in fuelData) {
        totalLiters += (item['liters'] as num).toDouble();
      }

      const tankCapacity = 13.0;

      setState(() {
        fuelLevelPercent = ((totalLiters / tankCapacity) * 100)
            .clamp(0, 100)
            .toDouble();
      });
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
                        "Hello,",
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
                  DashboardTile(
                    title: "Service Due",
                    value: "$serviceDueKm km",
                    color: Colors.orange,
                    icon: Icons.access_time,
                  ),
                  DashboardTile(
                    title: "Mileage",
                    value: "${mileage.toStringAsFixed(1)} km/L",
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
                      () async {
                        final result = await showAddServiceDialog(context);

                        if (result == true) {
                          await getRecentServices();
                        }
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
                child: recentServices.isEmpty
                    ? const Text(
                        "No services added yet",
                        style: TextStyle(color: Colors.white54),
                      )
                    : Column(
                        children: recentServices.map((service) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: serviceTile(
                              Icons.build,
                              Colors.orange,
                              service['service_type'] ?? "Service",
                              service['service_date'] ?? "",
                              "₹ ${service['cost'] ?? 0}",
                            ),
                          );
                        }).toList(),
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
