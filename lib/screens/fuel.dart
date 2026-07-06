import 'package:bikeservice/screens/ProfileScreen.dart';
import 'package:bikeservice/screens/TripsScreen.dart';
import 'package:bikeservice/screens/home.dart';
import 'package:bikeservice/screens/service.dart';
import 'package:bikeservice/screens/shimmer/FuelShimmer.dart';
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

  double fuelPercent = 0;
  double currentLiters = 0;
  double averageMileage = 0;
  double monthlyExpense = 0;

  static const primary = Color(0xFFFF5A1F);
  static const tankCapacity = 13.0;
  

  @override
  void initState() {
    super.initState();
    loadFuelHistory();
  }

  Future<Map<String, dynamic>?> getBike() async {
    final user = supabase.auth.currentUser;
    if (user == null) return null;

    final bike = await supabase
        .from('bikes')
        .select('id')
        .eq('user_id', user.id)
        .maybeSingle();

    return bike;
  }
  Future<void> deleteFuel(String id) async {
  try {
    await supabase
        .from('fuel_entries')
        .delete()
        .eq('id', id);

    await loadFuelHistory();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Fuel entry deleted successfully")),
    );
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Delete failed: $e")),
    );
  }
}

  Future<void> loadFuelHistory() async {
    try {
      setState(() => loading = true);

      final bike = await getBike();

      if (bike == null) {
        if (!mounted) return;
        setState(() {
          fuelList = [];
          loading = false;
        });
        return;
      }

      final data = await supabase
          .from('fuel_entries')
          .select()
          .eq('bike_id', bike['id'])
          .order('fuel_date', ascending: false);

      calculateSummary(data);

      if (!mounted) return;

      setState(() {
        fuelList = data;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Fuel Load Error: $e")),
      );
    }
  }

  void calculateSummary(List<dynamic> data) {
    if (data.isEmpty) {
      fuelPercent = 0;
      currentLiters = 0;
      averageMileage = 0;
      monthlyExpense = 0;
      return;
    }

    currentLiters = (data.first['liters'] as num?)?.toDouble() ?? 0;
    fuelPercent = ((currentLiters / tankCapacity) * 100).clamp(0, 100).toDouble();

    monthlyExpense = 0;
    final now = DateTime.now();

    for (final item in data) {
      final date = DateTime.tryParse(item['fuel_date']?.toString() ?? "");
      final amount = (item['amount'] as num?)?.toDouble() ?? 0;

      if (date != null && date.month == now.month && date.year == now.year) {
        monthlyExpense += amount;
      }
    }

    double totalMileage = 0;
    int mileageCount = 0;

    for (int i = 0; i < data.length - 1; i++) {
      final latest = data[i];
      final previous = data[i + 1];

      final latestOdo = (latest['odometer'] as num?)?.toDouble() ?? 0;
      final previousOdo = (previous['odometer'] as num?)?.toDouble() ?? 0;
      final liters = (latest['liters'] as num?)?.toDouble() ?? 0;

      final distance = latestOdo - previousOdo;

      if (distance > 0 && liters > 0) {
        totalMileage += distance / liters;
        mileageCount++;
      }
    }

    averageMileage = mileageCount == 0 ? 0 : totalMileage / mileageCount;
  }

  String formatDate(String date) {
    final d = DateTime.tryParse(date);
    if (d == null) return date;

    const months = [
      "JAN", "FEB", "MAR", "APR", "MAY", "JUN",
      "JUL", "AUG", "SEP", "OCT", "NOV", "DEC",
    ];

    return "${d.day}\n${months[d.month - 1]}";
  }

  String lastUpdatedText() {
    if (fuelList.isEmpty) return "Last Updated : No data";

    final date = fuelList.first['fuel_date']?.toString() ?? "";
    return "Last Updated : $date";
  }

  double calculateMileageForIndex(int index) {
    if (index >= fuelList.length - 1) return 0;

    final latest = fuelList[index];
    final previous = fuelList[index + 1];

    final latestOdo = (latest['odometer'] as num?)?.toDouble() ?? 0;
    final previousOdo = (previous['odometer'] as num?)?.toDouble() ?? 0;
    final liters = (latest['liters'] as num?)?.toDouble() ?? 0;

    final distance = latestOdo - previousOdo;

    if (distance <= 0 || liters <= 0) return 0;

    return distance / liters;
  }

  List<FlSpot> chartSpots() {
    if (fuelList.isEmpty) return const [FlSpot(0, 0)];

    final reversed = fuelList.reversed.toList();

    return reversed.asMap().entries.map((entry) {
      final index = entry.key.toDouble();
      final liters = (entry.value['liters'] as num?)?.toDouble() ?? 0;
      return FlSpot(index, liters);
    }).toList();
  }

  double chartMaxX() {
    if (fuelList.length <= 1) return 1;
    return fuelList.length - 1;
  }

  double chartMaxY() {
    if (fuelList.isEmpty) return tankCapacity;

    double max = 0;

    for (final item in fuelList) {
      final liters = (item['liters'] as num?)?.toDouble() ?? 0;
      if (liters > max) max = liters;
    }

    return max < tankCapacity ? tankCapacity : max + 2;
  }

  void changePage(int index) {
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
    final percentText = "${fuelPercent.toStringAsFixed(0)}%";

    return Scaffold(
      backgroundColor: const Color(0xFF070B14),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Fuel Tracker",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        //leading: const BackButton(color: Colors.white),
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
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Add Fuel", style: TextStyle(color: Colors.white)),
        onPressed: () async {
          final result = await showAddFuelDialog(context);

          if (result == true) {
            await loadFuelHistory();
          }
        },
      ),
      body: loading
          ? const FuelShimmer()
          : RefreshIndicator(
              onRefresh: loadFuelHistory,
              color: primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    fuelGaugeCard(percentText),
                    const SizedBox(height: 16),
                    summaryCards(),
                    const SizedBox(height: 25),
                    fuelChartCard(),
                    const SizedBox(height: 25),
                    historyTitle(),
                    const SizedBox(height: 15),
                    fuelHistoryList(),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
    );
  }

  Widget fuelGaugeCard(String percentText) {
    return Container(
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
                    value: fuelPercent / 100,
                    strokeWidth: 13,
                    backgroundColor: Colors.white12,
                    valueColor: const AlwaysStoppedAnimation(primary),
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
                    Text(
                      "${currentLiters.toStringAsFixed(1)} L / 13 L",
                      style: const TextStyle(color: Colors.white54),
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
    );
  }

  Widget summaryCards() {
    return Row(
      children: [
        Expanded(
          child: miniCard(
            "Avg Mileage",
            "${averageMileage.toStringAsFixed(1)} km/L",
            Icons.speed,
            Colors.cyan,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: miniCard(
            "This Month",
            "₹ ${monthlyExpense.toStringAsFixed(0)}",
            Icons.currency_rupee,
            Colors.green,
          ),
        ),
      ],
    );
  }

  Widget miniCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(color: Colors.white54)),
        ],
      ),
    );
  }

  Widget fuelChartCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Fuel Liters Chart",
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),
          SizedBox(
            height: 220,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(color: Colors.white10, strokeWidth: 1);
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
                      reservedSize: 34,
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
                    spots: chartSpots(),
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
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget historyTitle() {
    return Row(
      children: const [
        Text(
          "Fuel History",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Spacer(),
        Text("Recent 5", style: TextStyle(color: Colors.white54)),
      ],
    );
  }

  Widget fuelHistoryList() {
    if (fuelList.isEmpty) {
      return 
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
      );
    }

    final itemCount = fuelList.length > 5 ? 5 : fuelList.length;

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final fuel = fuelList[index];

        final date = formatDate(fuel['fuel_date']?.toString() ?? "");

        final liters =
            "${((fuel['liters'] as num?)?.toDouble() ?? 0).toStringAsFixed(1)} L";

        final amount =
            "₹ ${((fuel['amount'] as num?)?.toDouble() ?? 0).toStringAsFixed(0)}";

        final mileageValue = calculateMileageForIndex(index);

        final mileage = mileageValue == 0
            ? "--"
            : "${mileageValue.toStringAsFixed(1)} km/L";

        return Dismissible(
  key: ValueKey(fuel['id']),
  direction: DismissDirection.endToStart,

  confirmDismiss: (_) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Fuel Entry"),
        content: const Text(
          "Are you sure you want to delete this fuel entry?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              "Delete",
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await deleteFuel(fuel['id'].toString());
      return true;
    }

    return false;
  },

  background: Container(
    alignment: Alignment.centerRight,
    padding: const EdgeInsets.only(right: 20),
    decoration: BoxDecoration(
      color: Colors.red,
      borderRadius: BorderRadius.circular(16),
    ),
    child: const Icon(Icons.delete, color: Colors.white),
  ),

  child: Container(
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
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
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
  ),
);
      },
    );
  }

  
}