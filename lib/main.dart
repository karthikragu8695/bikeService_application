import 'package:bikeservice/screens/home.dart';
import 'package:bikeservice/screens/login.dart';
import 'package:bikeservice/screens/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  await Supabase.initialize(
    url: 'https://jjwszsjaikwypeqeaksf.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Impqd3N6c2phaWt3eXBlcWVha3NmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzcwNzM5MjksImV4cCI6MjA5MjY0OTkyOX0.ocFejm3r0D2jJFvIQ22S6hstCBcMqLo29Hiv3eeoYbE',
  );
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider()..loadTheme(),
      child: const RideSmartApp(),
    ),
  );
}

final supabase = Supabase.instance.client;

class RideSmartApp extends StatelessWidget {
  const RideSmartApp({super.key});

  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;
    final themeProvider = Provider.of<ThemeProvider>(context);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.themeMode,
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: const Color(0xFFFF5A1F),
        scaffoldBackgroundColor: Colors.white,
      ),

      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFFFF5A1F),
        scaffoldBackgroundColor: const Color(0xFF070B14),
      ),

      home: session != null ? const HomeScreen() : const LoginScreen(),
    );
  }
}
