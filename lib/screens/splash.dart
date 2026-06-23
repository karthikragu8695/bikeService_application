import 'dart:async';
import 'package:bikeservice/screens/login.dart';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  double progress = 0.0;

  @override
  void initState() {
    super.initState();

    Timer.periodic(const Duration(milliseconds: 40), (timer) {
      setState(() {
        progress += 0.01;
      });

      if (progress >= 1) {
        timer.cancel();

     //   Navigate to Login Screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFFF4D1F);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black, Color(0xFF050505), Color(0xFF0A0A0A)],
            ),
          ),
          child: Column(
            children: [
              const Spacer(),

              // Logo
              Column(
                children: [
                  Icon(Icons.speed, size: 70, color: primaryColor),

                  const SizedBox(height: 10),

                  RichText(
                    text: const TextSpan(
                      children: [
                        TextSpan(
                          text: "RIDE ",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        TextSpan(
                          text: "SMART",
                          style: TextStyle(
                            color: primaryColor,
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    "Your Ride, Our Care",
                    style: TextStyle(color: Colors.white70, fontSize: 15),
                  ),
                ],
              ),

              const SizedBox(height: 60),

              // Bike Glow
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withOpacity(.8),
                          blurRadius: 100,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                  ),

                  Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: primaryColor, width: 3),
                    ),
                  ),

                  Image.asset(
                    "assets/images/bike.png",
                    height: 180,
                    fit: BoxFit.contain,
                   
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.motorcycle,
                        color: Colors.white,
                        size: 100,
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 40),

              const Text(
                "Loading...",
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),

              const Spacer(),

              // Progress Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 6,
                        backgroundColor: Colors.white10,
                        valueColor: const AlwaysStoppedAnimation(primaryColor),
                      ),
                    ),

                    const SizedBox(height: 10),

                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        "${(progress * 100).toInt()}%",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
