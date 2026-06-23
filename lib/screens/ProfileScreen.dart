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
  int selectedIndex = 4;
  bool darkMode = true;

  String bikeName = '';
  String registrationNo = '';
  String bikeImage = '';

  String userName = '';
  String email = '';
  String profileImage = '';

  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    loadUser();
    loadBike();
  }

  Future<void> loadUser() async {
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
          userName = data['name'] ?? 'User';
          email = data['email'] ?? user.email ?? '';
          profileImage = data['IMAGE'] ?? '';
        });

        debugPrint("Profile Image URL: $profileImage");
      }
    } catch (e) {
      debugPrint("Load User Error: $e");
    }
  }

  Future<void> loadBike() async {
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
          bikeName = data['bike_name'] ?? '';
          registrationNo = data['registration_no'] ?? '';
          bikeImage = data['image_url'] ?? '';
        });
      }
    } catch (e) {
      debugPrint("Load Bike Error: $e");
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

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFFFF5A1F);

    return Scaffold(
      backgroundColor: const Color(0xFF070B14),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "My Profile",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
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
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_gas_station),
            label: "Fuel",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.build),
            label: "Service",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.route),
            label: "Trips",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Profile",
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            userCard(),
            const SizedBox(height: 15),
            bikeCard(),
            const SizedBox(height: 20),

            profileTile(Icons.motorcycle, "Bike Details", () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AddBikeScreen(),
                ),
              );

              if (result == true) {
                loadBike();
              }
            }),

            profileTile(Icons.notifications_none, "Notifications", () {}),

            themeTile(primary),

            profileTile(Icons.help_outline, "Help & Support", () {}),
            profileTile(Icons.info_outline, "About Us", () {}),

            const SizedBox(height: 20),
            logoutButton(),
          ],
        ),
      ),
    );
  }

  Widget userCard() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.grey.shade800,
            backgroundImage: profileImage.isNotEmpty
                ? NetworkImage(profileImage)
                : null,
            child: profileImage.isEmpty
                ? const Icon(
                    Icons.person,
                    color: Colors.white,
                  )
                : null,
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName.isEmpty ? "User" : userName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email.isEmpty ? "rider@gmail.com" : email,
                  style: const TextStyle(color: Colors.white54),
                ),
              ],
            ),
          ),

          IconButton(
            icon: const Icon(
              Icons.edit,
              color: Colors.white,
            ),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditUserProfileScreen(
                    name: userName,
                  ),
                ),
              );

              if (result == true) {
                loadUser();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget bikeCard() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: bikeImage.isNotEmpty
                ? Image.network(
                    bikeImage,
                    width: 90,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) {
                      return bikePlaceholder();
                    },
                  )
                : bikePlaceholder(),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bikeName.isEmpty ? "No Bike Added" : bikeName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  registrationNo.isEmpty ? "Add bike details" : registrationNo,
                  style: const TextStyle(color: Colors.white54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget bikePlaceholder() {
    return Container(
      width: 90,
      height: 60,
      color: Colors.grey.shade800,
      child: const Icon(
        Icons.motorcycle,
        color: Colors.white,
      ),
    );
  }

  Widget themeTile(Color primary) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.palette_outlined, color: Colors.white),
          const SizedBox(width: 15),
          const Expanded(
            child: Text(
              "Theme",
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF111827),
          borderRadius: BorderRadius.circular(16),
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
            title: const Text("Logout"),
            content: const Text("Are you sure you want to logout?"),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () async {
                  await supabase.auth.signOut();

                  if (!mounted) return;

                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LoginScreen(),
                    ),
                    (route) => false,
                  );
                },
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