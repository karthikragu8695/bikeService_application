import 'package:bikeservice/screens/TripsScreen.dart';
import 'package:bikeservice/screens/fuel.dart';
import 'package:bikeservice/screens/home.dart';
import 'package:bikeservice/screens/login.dart';
import 'package:bikeservice/screens/service.dart';
import 'package:bikeservice/screens/userProfile.dart';
import 'package:bikeservice/widget/bikeDetail.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final supabase = Supabase.instance.client;

  static const primary = Color(0xFFFF5A1F);

  int selectedIndex = 4;
  bool loading = true;
  bool darkMode = true;

  String bikeName = '';
  String registrationNo = '';
  String bikeImage = '';

  String userName = '';
  String email = '';
  String profileImage = '';

  int totalTrips = 0;
  int totalServices = 0;
  double totalFuelCost = 0;

  @override
  void initState() {
    super.initState();
    loadProfileData();
  }

  Future<void> loadProfileData() async {
    try {
      if (mounted) setState(() => loading = true);

      await loadUser();
      await loadBike();
      await loadStats();

      if (mounted) setState(() => loading = false);
    } catch (e) {
      if (mounted) setState(() => loading = false);
      debugPrint("Profile Load Error: $e");
    }
  }

  Future<void> loadUser() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final data = await supabase
        .from('users')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    if (!mounted) return;

    setState(() {
      userName = data?['name'] ?? 'User';
      email = data?['email'] ?? user.email ?? '';
      profileImage = data?['IMAGE'] ?? '';
    });
  }

  Future<Map<String, dynamic>?> getBike() async {
    final user = supabase.auth.currentUser;
    if (user == null) return null;

    return await supabase
        .from('bikes')
        .select()
        .eq('user_id', user.id)
        .maybeSingle();
  }

  Future<void> loadBike() async {
    final data = await getBike();

    if (!mounted) return;

    setState(() {
      bikeName = data?['bike_name'] ?? '';
      registrationNo = data?['registration_no'] ?? '';
      bikeImage = data?['image_url'] ?? '';
    });
  }

  Future<void> loadStats() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final bike = await getBike();
    if (bike == null) return;

    final trips = await supabase
        .from('trips')
        .select('id')
        .eq('bike_id', bike['id']);

    final services = await supabase
        .from('services')
        .select('id')
        .eq('bike_id', bike['id']);

    final fuels = await supabase
        .from('fuel_entries')
        .select('amount')
        .eq('bike_id', bike['id']);

    double fuelCost = 0;

    for (final item in fuels) {
      fuelCost += (item['amount'] as num?)?.toDouble() ?? 0;
    }

    if (!mounted) return;

    setState(() {
      totalTrips = trips.length;
      totalServices = services.length;
      totalFuelCost = fuelCost;
    });
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

  Future<void> logout() async {
    await supabase.auth.signOut();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070B14),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "My Profile",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
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
          ? const Center(child: CircularProgressIndicator(color: primary))
          : RefreshIndicator(
              onRefresh: loadProfileData,
              color: primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    premiumUserHeader(),
                    const SizedBox(height: 16),
                    statsGrid(),
                    const SizedBox(height: 16),
                    premiumBikeCard(),
                    const SizedBox(height: 20),
                    profileTile(Icons.motorcycle, "Bike Details", () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AddBikeScreen(),
                        ),
                      );

                      if (result == true) {
                        await loadProfileData();
                      }
                    }),
                    profileTile(
                      Icons.notifications_none,
                      "Notifications",
                      () {},
                    ),
                    themeTile(),
                    profileTile(Icons.help_outline, "Help & Support", () {}),
                    profileTile(Icons.info_outline, "About Us", () {}),
                    const SizedBox(height: 20),
                    logoutButton(),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
    );
  }

  Widget premiumUserHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primary.withOpacity(.95),
            const Color(0xFF7C2D12),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 42,
            backgroundColor: Colors.white24,
            backgroundImage:
                profileImage.isNotEmpty ? NetworkImage(profileImage) : null,
            child: profileImage.isEmpty
                ? const Icon(Icons.person, color: Colors.white, size: 42)
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName.isEmpty ? "User" : userName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  email.isEmpty ? "No email" : email,
                  style: const TextStyle(color: Colors.white70),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditUserProfileScreen(name: userName),
                ),
              );

              if (result == true) {
                await loadProfileData();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget statsGrid() {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: .95,
      children: [
        statCard("Trips", "$totalTrips", Icons.route, Colors.cyan),
        statCard("Services", "$totalServices", Icons.build, Colors.green),
        statCard(
          "Fuel Cost",
          "₹${totalFuelCost.toStringAsFixed(0)}",
          Icons.local_gas_station,
          Colors.orange,
        ),
      ],
    );
  }

  Widget statCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white54, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget premiumBikeCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: bikeImage.isNotEmpty
                ? Image.network(
                    bikeImage,
                    width: 105,
                    height: 75,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => bikePlaceholder(),
                  )
                : bikePlaceholder(),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "My Bike",
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
                const SizedBox(height: 5),
                Text(
                  bikeName.isEmpty ? "No Bike Added" : bikeName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  registrationNo.isEmpty ? "Add bike details" : registrationNo,
                  style: const TextStyle(color: Colors.white54),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.white54),
        ],
      ),
    );
  }

  Widget bikePlaceholder() {
    return Container(
      width: 105,
      height: 75,
      color: Colors.grey.shade800,
      child: const Icon(Icons.motorcycle, color: Colors.white, size: 34),
    );
  }

  Widget themeTile() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          const Icon(Icons.palette_outlined, color: Colors.white),
          const SizedBox(width: 15),
          const Expanded(
            child: Text(
              "Dark Mode",
              style: TextStyle(color: Colors.white, fontSize: 15),
            ),
          ),
          Switch(
            activeThumbColor: primary,
            value: darkMode,
            onChanged: (value) {
              setState(() {
                darkMode = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget profileTile(IconData icon, String title, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          color: const Color(0xFF111827),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 15),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(color: Colors.white, fontSize: 15),
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white54),
          ],
        ),
      ),
    );
  }

  Widget logoutButton() {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: const Color(0xFF111827),
            title: const Text(
              "Logout",
              style: TextStyle(color: Colors.white),
            ),
            content: const Text(
              "Are you sure you want to logout?",
              style: TextStyle(color: Colors.white54),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: logout,
                child: const Text(
                  "Logout",
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        );
      },
      child: Container(
        width: double.infinity,
        height: 55,
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.withOpacity(.4)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout, color: Colors.red),
            SizedBox(width: 10),
            Text(
              "Logout",
              style: TextStyle(
                color: Colors.red,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}