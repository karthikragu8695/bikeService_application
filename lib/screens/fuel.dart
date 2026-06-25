import 'package:bikeservice/screens/ProfileScreen.dart';
import 'package:bikeservice/screens/TripsScreen.dart';
import 'package:bikeservice/screens/home.dart';
import 'package:bikeservice/screens/service.dart';
import 'package:bikeservice/widget/Addfuel.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FuelScreen extends StatefulWidget {
  const FuelScreen({super.key});

  @override
  State<FuelScreen> createState() => _FuelScreenState();
}

class _FuelScreenState extends State<FuelScreen> {
  final supabase = Supabase.instance.client;

  int selectedIndex = 1;
  bool loading = true;

  List<dynamic> fuelList = [];

  static const primary = Color(0xFFFF5A1F);

 double get fuelLevelPercent {
  if (fuelList.isEmpty) return 0.0;

  double totalLiters = 0;

  for (final fuel in fuelList) {
    totalLiters +=
        (fuel['liters'] as num?)?.toDouble() ?? 0;
  }

  const tankCapacity = 13.0;

  if (totalLiters > tankCapacity) {
    totalLiters = tankCapacity;
  }

  return totalLiters / tankCapacity;
}

  @override
  void initState() {
    super.initState();
    loadFuelHistory();
  }

  Future<void> loadFuelHistory() async {
  try {
    final user = supabase.auth.currentUser;

    if (user == null) {
      if (!mounted) return;
      setState(() => loading = false);
      return;
    }

    final data = await supabase
        .from('fuel_entries')
        .select()
        .eq('', user.id)
        .order('fuel_date', ascending: false);

    if (!mounted) return;

    setState(() {
      fuelList = data;
      loading = false;
    });
  } catch (e) {
    if (!mounted) return;

    setState(() => loading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Error: $e")),
    );
  }
}

  String formatDate(String date) {
    final d = DateTime.tryParse(date);
    if (d == null) return date;

    const months = [
      "JAN",
      "FEB",
      "MAR",
      "APR",
      "MAY",
      "JUN",
      "JUL",
      "AUG",
      "SEP",
      "OCT",
      "NOV",
      "DEC",
    ];

    return "${d.day}\n${months[d.month - 1]}";
  }

  String lastUpdatedText() {
    if (fuelList.isEmpty) return "Last Updated : No data";

    final date = fuelList.first['fuel_date']?.toString() ?? "";
    return "Last Updated : $date";
  }

  List<FlSpot> chartSpots() {
    if (fuelList.isEmpty) {
      return const [FlSpot(0, 0)];
    }

    final reversed = fuelList.reversed.toList();

    return reversed.asMap().entries.map((entry) {
      final index = entry.key.toDouble();
      final amount = (entry.value['amount'] as num?)?.toDouble() ?? 0;
      return FlSpot(index, amount);
    }).toList();
  }

  double chartMaxX() {
    if (fuelList.length <= 1) return 1;
    return fuelList.length - 1;
  }

  double chartMaxY() {
    if (fuelList.isEmpty) return 100;

    double max = 0;
    for (final item in fuelList) {
      final amount = (item['amount'] as num?)?.toDouble() ?? 0;
      if (amount > max) max = amount;
    }

    return max == 0 ? 100 : max + 100;
  }

  void changePage(int index) {
    if (index == selectedIndex) return;

    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else if (index == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const FuelScreen()),
      );
    } else if (index == 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ServiceScreen()),
      );
    } else if (index == 3) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const TripsScreen()),
      );
    } else if (index == 4) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ProfileScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final percentText = "${(fuelLevelPercent * 100).toStringAsFixed(0)}%";

    return Scaffold(
      backgroundColor: const Color(0xFF070B14),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Fuel Tracker",
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
        onTap: changePage,
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
          ? const Center(
              child: CircularProgressIndicator(color: primary),
            )
          : RefreshIndicator(
              onRefresh: loadFuelHistory,
              color: primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Container(
                      height: 280,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFF111827),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            height: 180,
                            width: 180,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  height: 180,
                                  width: 180,
                                  child: CircularProgressIndicator(
                                    value: fuelLevelPercent,
                                    strokeWidth: 12,
                                    backgroundColor: Colors.white12,
                                    valueColor:
                                        const AlwaysStoppedAnimation(primary),
                                  ),
                                ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.local_gas_station,
                                      color: Colors.orange,
                                      size: 35,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      percentText,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 36,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const Text(
                                      "Fuel Level",
                                      style: TextStyle(color: Colors.white54),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            lastUpdatedText(),
                            style: const TextStyle(color: Colors.white54),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () async {
                          final result = await showAddFuelDialog(context);

                          if (result == true) {
                            loadFuelHistory();
                          }
                        },
                        child: const Text(
                          "Add Fuel",
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                    ),

                    const SizedBox(height: 25),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text(
                          "Fuel History",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text("See All", style: TextStyle(color: Colors.blue)),
                      ],
                    ),

                    const SizedBox(height: 15),

                    if (fuelList.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF111827),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(
                          child: Text(
                            "No fuel records found",
                            style: TextStyle(color: Colors.white54),
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: fuelList.length > 5 ? 5 : fuelList.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final fuel = fuelList[index];

                          final date = formatDate(
                            fuel['fuel_date']?.toString() ?? "",
                          );

                          final liters =
                              "${((fuel['liters'] as num?)?.toDouble() ?? 0).toStringAsFixed(1)} L";

                          final amount =
                              "₹ ${((fuel['amount'] as num?)?.toDouble() ?? 0).toStringAsFixed(0)}";

                          final mileageValue =
                              (fuel['mileage'] as num?)?.toDouble();

                          final mileage = mileageValue == null ||
                                  mileageValue == 0
                              ? "--"
                              : "${mileageValue.toStringAsFixed(1)} km/l";

                          return fuelHistoryTile(
                            date,
                            liters,
                            amount,
                            mileage,
                          );
                        },
                      ),

                    const SizedBox(height: 25),

                    SizedBox(
                      height: 220,
                      child: LineChart(
                        LineChartData(
                          backgroundColor: Colors.transparent,
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            getDrawingHorizontalLine: (value) {
                              return FlLine(
                                color: Colors.white10,
                                strokeWidth: 1,
                              );
                            },
                          ),
                          borderData: FlBorderData(show: false),
                          titlesData: FlTitlesData(
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 35,
                                getTitlesWidget: (value, meta) {
                                  return Text(
                                    value.toInt().toString(),
                                    style: const TextStyle(
                                      color: Colors.white54,
                                      fontSize: 10,
                                    ),
                                  );
                                },
                              ),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  return Text(
                                    value.toInt().toString(),
                                    style: const TextStyle(
                                      color: Colors.white54,
                                      fontSize: 10,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          minX: 0,
                          maxX: chartMaxX(),
                          minY: 0,
                          maxY: chartMaxY(),
                          lineBarsData: [
                            LineChartBarData(
                              isCurved: true,
                              color: Colors.cyanAccent,
                              barWidth: 4,
                              dotData: const FlDotData(show: true),
                              belowBarData: BarAreaData(
                                show: true,
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.cyanAccent.withOpacity(.3),
                                    Colors.transparent,
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                              ),
                              spots: chartSpots(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget fuelHistoryTile(
    String date,
    String liters,
    String amount,
    String mileage,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 55,
            height: 55,
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                date,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              liters,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              amount,
              style: const TextStyle(color: Colors.white),
            ),
          ),
          Expanded(
            child: Text(
              mileage,
              textAlign: TextAlign.end,
              style: const TextStyle(color: Colors.white54),
            ),
          ),
        ],
      ),
    );
  }
}