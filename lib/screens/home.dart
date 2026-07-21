import 'package:bikeservice/screens/Notification.dart';
import 'package:bikeservice/screens/ProfileScreen.dart';
import 'package:bikeservice/screens/TripsScreen.dart';
import 'package:bikeservice/screens/fuel.dart';
import 'package:bikeservice/screens/service.dart';
import 'package:bikeservice/screens/shimmer/HomeShimmer.dart';
import 'package:bikeservice/widget/Addfuel.dart' show showAddFuelDialog;
import 'package:bikeservice/widget/Addservice.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final supabase = Supabase.instance.client;

  static const primary = Color(0xFFFF5A1F);

  int selectedIndex = 0;
  bool loading = true;

  String riderName = "Rider";
  Map<String, dynamic>? bikeData;

  double fuelLevelPercent = 0;
  double mileage = 0;
  double monthlyFuelCost = 0;
  double totalDistance = 0;

  int serviceDueKm = 0;
  int tripsCount = 0;

  List<dynamic> recentServices = [];
  double remainingFuelLitres = 0;
  static const double tankCapacity = 13.0;

  static const double defaultMileage = 45.0;

  @override
  void initState() {
    super.initState();
    loadHomeData();
  }

  Future<void> loadHomeData() async {
    try {
      if (mounted) {
        setState(() => loading = true);
      }

      await getUserData();
      await getBike();

      await getMileage();

      await getFuelSummary();

      await getServiceDue();
      await getTripsSummary();
      await getRecentServices();

      if (mounted) {
        setState(() => loading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => loading = false);
      }

      debugPrint("Home Load Error: $e");
    }
  }

  Future<Map<String, dynamic>?> getUserBike() async {
    final user = supabase.auth.currentUser;
    if (user == null) return null;

    return await supabase
        .from('bikes')
        .select()
        .eq('user_id', user.id)
        .maybeSingle();
  }

  Future<void> getUserData() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final data = await supabase
        .from('users')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    if (!mounted) return;

    setState(() {
      riderName = data?['name'] ?? "Rider";
    });
  }

  Future<void> getBike() async {
    final bike = await getUserBike();

    if (!mounted) return;

    setState(() {
      bikeData = bike;
    });
  }

  Future<void> getFuelSummary() async {
    try {
      final bike = bikeData ?? await getUserBike();

      if (bike == null) {
        if (!mounted) return;

        setState(() {
          fuelLevelPercent = 0;
          remainingFuelLitres = 0;
          monthlyFuelCost = 0;
        });

        return;
      }

      final fuelList = await supabase
          .from('fuel_entries')
          .select('liters, amount, fuel_date, odometer')
          .eq('bike_id', bike['id'])
          .order('fuel_date', ascending: false);

      if (fuelList.isEmpty) {
        if (!mounted) return;

        setState(() {
          fuelLevelPercent = 0;
          remainingFuelLitres = 0;
          monthlyFuelCost = 0;
        });

        return;
      }

      double monthCost = 0;
      final now = DateTime.now();

      // இந்த மாத fuel expense calculate செய்கிறது.
      for (final fuel in fuelList) {
        final fuelDate = DateTime.tryParse(fuel['fuel_date']?.toString() ?? '');

        final amount = (fuel['amount'] as num?)?.toDouble() ?? 0;

        if (fuelDate != null &&
            fuelDate.month == now.month &&
            fuelDate.year == now.year) {
          monthCost += amount;
        }
      }

      // Latest fuel entry.
      final latestFuel = fuelList.first;

      final addedLitres = (latestFuel['liters'] as num?)?.toDouble() ?? 0;

      final lastFuelOdometer =
          (latestFuel['odometer'] as num?)?.toDouble() ?? 0;

      // Bike current kilometre.
      final currentKm =
          (bike['current_km'] as num?)?.toDouble() ?? lastFuelOdometer;

      double travelledKm = currentKm - lastFuelOdometer;

      // Negative distance வரக்கூடாது.
      if (travelledKm < 0) {
        travelledKm = 0;
      }

      // getMileage() மூலம் mileage கிடைக்கவில்லை என்றால்
      // defaultMileage பயன்படுத்தப்படும்.
      final usableMileage = mileage > 0 ? mileage : defaultMileage;

      // எவ்வளவு fuel consume ஆகியிருக்கும்?
      final consumedFuel = usableMileage > 0 ? travelledKm / usableMileage : 0;

      // Remaining fuel.
      double calculatedRemainingFuel = addedLitres - consumedFuel;

      // 0 litres-க்கு கீழே போகக்கூடாது.
      calculatedRemainingFuel = calculatedRemainingFuel.clamp(
        0.0,
        tankCapacity,
      );

      // Percentage calculation.
      final calculatedPercentage =
          (calculatedRemainingFuel / tankCapacity) * 100;

      if (!mounted) return;

      setState(() {
        remainingFuelLitres = calculatedRemainingFuel;

        fuelLevelPercent = calculatedPercentage.clamp(0.0, 100.0).toDouble();

        monthlyFuelCost = monthCost;
      });

      debugPrint('Latest fuel added: $addedLitres L');
      debugPrint('Last fuel odometer: $lastFuelOdometer km');
      debugPrint('Current bike km: $currentKm km');
      debugPrint('Travelled distance: $travelledKm km');
      debugPrint('Used mileage: $usableMileage km/L');
      debugPrint('Consumed fuel: $consumedFuel L');
      debugPrint('Remaining fuel: $remainingFuelLitres L');
      debugPrint('Fuel percentage: $fuelLevelPercent%');
    } catch (e) {
      debugPrint('Fuel summary error: $e');

      if (!mounted) return;

      setState(() {
        fuelLevelPercent = 0;
        remainingFuelLitres = 0;
        monthlyFuelCost = 0;
      });
    }
  }

  Future<void> getMileage() async {
    final bike = bikeData ?? await getUserBike();
    if (bike == null) return;

    final fuelList = await supabase
        .from('fuel_entries')
        .select('odometer, liters')
        .eq('bike_id', bike['id'])
        .order('fuel_date', ascending: false)
        .limit(2);

    if (fuelList.length < 2) return;

    final latest = fuelList[0];
    final previous = fuelList[1];

    final latestOdo = (latest['odometer'] as num?)?.toDouble() ?? 0;
    final previousOdo = (previous['odometer'] as num?)?.toDouble() ?? 0;
    final liters = (latest['liters'] as num?)?.toDouble() ?? 0;

    final distance = latestOdo - previousOdo;

    if (distance <= 0 || liters <= 0) return;

    if (!mounted) return;

    setState(() {
      mileage = distance / liters;
    });
  }

  Future<void> getServiceDue() async {
    final bike = bikeData ?? await getUserBike();
    if (bike == null) return;

    final service = await supabase
        .from('services')
        .select('next_service_km')
        .eq('bike_id', bike['id'])
        .order('service_date', ascending: false)
        .limit(1)
        .maybeSingle();

    final currentKm = (bike['current_km'] as num?)?.toInt() ?? 0;
    final nextKm = (service?['next_service_km'] as num?)?.toInt() ?? 0;

    int dueKm = 0;

    if (nextKm > currentKm) {
      dueKm = nextKm - currentKm;
    }

    if (!mounted) return;

    setState(() {
      serviceDueKm = dueKm;
    });
  }

  Future<void> getTripsSummary() async {
    final bike = bikeData ?? await getUserBike();
    if (bike == null) return;

    final trips = await supabase
        .from('trips')
        .select('distance_km')
        .eq('bike_id', bike['id']);

    double distance = 0;

    for (final trip in trips) {
      distance += (trip['distance_km'] as num?)?.toDouble() ?? 0;
    }

    if (!mounted) return;

    setState(() {
      tripsCount = trips.length;
      totalDistance = distance;
    });
  }

  Future<void> getRecentServices() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final data = await supabase
        .from('services')
        .select()
        .eq('user_id', user.id)
        .order('service_date', ascending: false)
        .limit(3);

    if (!mounted) return;

    setState(() {
      recentServices = data;
    });
  }

 Future<void> refreshAfterFuelAdded() async {
  await getBike();
  await getMileage();
  await getFuelSummary();
  await getServiceDue();
}

  Future<void> refreshAfterServiceAdded() async {
    await getRecentServices();
    await getServiceDue();
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
      borderRadius: BorderRadius.circular(18),
      child: bikeImageUrl.isNotEmpty
          ? Image.network(
              bikeImageUrl,
              width: 105,
              height: 75,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => bikeAssetImage(),
            )
          : bikeAssetImage(),
    );
  }

  Widget bikeAssetImage() {
    return Container(
      width: 105,
      height: 75,
      color: Colors.black26,
      child: const Icon(Icons.motorcycle, color: Colors.white, size: 38),
    );
  }

  @override
  Widget build(BuildContext context) {
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
      body: loading
          ? const HomeShimmer()
          : SafeArea(
              child: RefreshIndicator(
                onRefresh: loadHomeData,
                color: primary,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    header(),
                    const SizedBox(height: 18),
                    bikeHeroCard(),
                    const SizedBox(height: 18),
                    analyticsGrid(),
                    const SizedBox(height: 18),
                    fuelGaugeCard(),
                    const SizedBox(height: 18),
                    quickActions(),
                    const SizedBox(height: 18),
                    bikeHealthCard(),
                    const SizedBox(height: 18),
                    recentActivity(),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
    );
  }

  Widget header() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Welcome Back,",
                style: TextStyle(color: Colors.white54),
              ),
              Text(
                "$riderName 👋",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 29,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        Stack(
          children: [
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NotificationScreen()),
                );
              },
              child: Container(
                height: 46,
                width: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFF111827),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white),
                ),
                child: const Icon(
                  Icons.notifications_none,
                  color: Colors.white,
                ),
              ),
            ),
            Positioned(
              right: 4,
              top: 4,
              child: Container(
                height: 18,
                width: 18,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Text(
                  '2',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget bikeHeroCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primary.withOpacity(.95), const Color(0xFF7C2D12)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Row(
        children: [
          bikeImageWidget(),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("My Bike", style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 5),
                Text(
                  bikeData?['bike_name'] ?? "No Bike Added",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  bikeData?['registration_no'] ?? "Add bike details",
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(.25),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text("Active", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget analyticsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.15,
      children: [
        dashboardTile(
          "Fuel Cost",
          "₹ ${monthlyFuelCost.toStringAsFixed(0)}",
          Icons.currency_rupee,
          Colors.green,
          "This Month",
        ),
        dashboardTile(
          "Mileage",
          "${mileage.toStringAsFixed(1)} km/L",
          Icons.speed,
          Colors.cyan,
          "Latest",
        ),
        dashboardTile(
          "Trips",
          "$tripsCount",
          Icons.route,
          Colors.lightBlue,
          "${totalDistance.toStringAsFixed(1)} km",
        ),
        dashboardTile(
          "Service Due",
          serviceDueKm == 0 ? "--" : "$serviceDueKm km",
          Icons.build,
          Colors.orange,
          "Remaining",
        ),
      ],
    );
  }

  Widget dashboardTile(
    String title,
    String value,
    IconData icon,
    Color color,
    String subtitle,
  ) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 3),
          Text(title, style: const TextStyle(color: Colors.white54)),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.white38, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget fuelGaugeCard() {
    final value = fuelLevelPercent / 100;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          SizedBox(
            height: 105,
            width: 105,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  height: 105,
                  width: 105,
                  child: CircularProgressIndicator(
                    value: value,
                    strokeWidth: 11,
                    backgroundColor: Colors.white12,
                    valueColor: const AlwaysStoppedAnimation(primary),
                  ),
                ),
                Text(
                  "${fuelLevelPercent.toStringAsFixed(0)}%",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Fuel Level",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "${remainingFuelLitres.toStringAsFixed(1)} L remaining",
                  style: const TextStyle(color: Colors.white54, fontSize: 14),
                ),
                const SizedBox(height: 10),
                LinearProgressIndicator(
                  value: value,
                  minHeight: 7,
                  backgroundColor: Colors.white12,
                  valueColor: const AlwaysStoppedAnimation(primary),
                  borderRadius: BorderRadius.circular(20),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget quickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Quick Actions",
          style: TextStyle(
            color: Colors.white,
            fontSize: 19,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: actionButton(
                "Add Fuel",
                Icons.local_gas_station,
                primary,
                () async {
                  final result = await showAddFuelDialog(context);
                  if (result == true) {
                    await refreshAfterFuelAdded();
                  }
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: actionButton(
                "Add Service",
                Icons.build,
                Colors.blue,
                () async {
                  final result = await showAddServiceDialog(context);
                  if (result == true) {
                    await refreshAfterServiceAdded();
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget actionButton(
    String title,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 58,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(17),
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

  Widget bikeHealthCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Bike Health",
            style: TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),
          healthItem("Engine", .92, Colors.green),
          healthItem("Battery", .85, Colors.cyan),
          healthItem("Brake Pad", .70, Colors.orange),
          healthItem("Tyre", .78, Colors.lightBlue),
        ],
      ),
    );
  }

  Widget healthItem(String title, double value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Row(
        children: [
          SizedBox(
            width: 75,
            child: Text(title, style: const TextStyle(color: Colors.white54)),
          ),
          Expanded(
            child: LinearProgressIndicator(
              value: value,
              minHeight: 7,
              backgroundColor: Colors.white12,
              valueColor: AlwaysStoppedAnimation(color),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            "${(value * 100).toStringAsFixed(0)}%",
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget recentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              "Recent Service",
              style: TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => changeScreen(2),
              child: const Text(
                "See All",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF111827),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white10),
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
    padding: const EdgeInsets.all(14),
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
