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
  final SupabaseClient supabase = Supabase.instance.client;

  static const Color primary = Color(0xFFFF5A1F);
  static const Color backgroundColor = Color(0xFF070B14);
  static const Color cardColor = Color(0xFF111827);

  static const double tankCapacity = 13.0;

  int selectedIndex = 1;
  bool loading = true;

  List<Map<String, dynamic>> fuelList = [];

  double fuelPercent = 0;
  double currentLiters = 0;
  double averageMileage = 0;
  double monthlyExpense = 0;
  double estimatedDistance = 0;

  @override
  void initState() {
    super.initState();
    loadFuelHistory();
  }

  Future<Map<String, dynamic>?> getBike() async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      return null;
    }

    final data = await supabase
        .from('bikes')
        .select('id')
        .eq('user_id', user.id)
        .maybeSingle();

    return data;
  }

  Future<void> loadFuelHistory() async {
    try {
      if (mounted) {
        setState(() {
          loading = true;
        });
      }

      final bike = await getBike();

      if (bike == null) {
        if (!mounted) return;

        setState(() {
          fuelList = [];
          resetSummary();
          loading = false;
        });

        return;
      }

      final response = await supabase
          .from('fuel_entries')
          .select()
          .eq('bike_id', bike['id'])
          .order('fuel_date', ascending: false)
          .order('created_at', ascending: false);

      final List<Map<String, dynamic>> data =
          List<Map<String, dynamic>>.from(response);

      calculateSummary(data);

      if (!mounted) return;

      setState(() {
        fuelList = data;
        loading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        loading = false;
      });

      showMessage(
        'Unable to load fuel history: $error',
        isError: true,
      );
    }
  }

  void resetSummary() {
    fuelPercent = 0;
    currentLiters = 0;
    averageMileage = 0;
    monthlyExpense = 0;
    estimatedDistance = 0;
  }

  void calculateSummary(List<Map<String, dynamic>> data) {
    if (data.isEmpty) {
      resetSummary();
      return;
    }

    currentLiters = getDouble(data.first['liters']);

    fuelPercent =
        ((currentLiters / tankCapacity) * 100).clamp(0, 100).toDouble();

    monthlyExpense = calculateMonthlyExpense(data);
    averageMileage = calculateAverageMileage(data);
    estimatedDistance = currentLiters * averageMileage;
  }

  double calculateMonthlyExpense(List<Map<String, dynamic>> data) {
    final now = DateTime.now();
    double total = 0;

    for (final item in data) {
      final date = DateTime.tryParse(
        item['fuel_date']?.toString() ?? '',
      );

      final amount = getDouble(item['amount']);

      if (date != null &&
          date.month == now.month &&
          date.year == now.year) {
        total += amount;
      }
    }

    return total;
  }

  double calculateAverageMileage(List<Map<String, dynamic>> data) {
    if (data.length < 2) {
      return 0;
    }

    double totalMileage = 0;
    int validMileageCount = 0;

    for (int index = 0; index < data.length - 1; index++) {
      final latestEntry = data[index];
      final previousEntry = data[index + 1];

      final latestOdometer = getDouble(latestEntry['odometer']);
      final previousOdometer = getDouble(previousEntry['odometer']);
      final liters = getDouble(latestEntry['liters']);

      final distance = latestOdometer - previousOdometer;

      if (distance > 0 && liters > 0) {
        final mileage = distance / liters;

        if (mileage > 0 && mileage < 150) {
          totalMileage += mileage;
          validMileageCount++;
        }
      }
    }

    if (validMileageCount == 0) {
      return 0;
    }

    return totalMileage / validMileageCount;
  }

  double calculateMileageForIndex(int index) {
    if (index >= fuelList.length - 1) {
      return 0;
    }

    final latestEntry = fuelList[index];
    final previousEntry = fuelList[index + 1];

    final latestOdometer = getDouble(latestEntry['odometer']);
    final previousOdometer = getDouble(previousEntry['odometer']);
    final liters = getDouble(latestEntry['liters']);

    final distance = latestOdometer - previousOdometer;

    if (distance <= 0 || liters <= 0) {
      return 0;
    }

    final mileage = distance / liters;

    if (mileage > 150) {
      return 0;
    }

    return mileage;
  }

  double getDouble(dynamic value) {
    if (value == null) {
      return 0;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString()) ?? 0;
  }

  Future<void> deleteFuelEntry({
    required String id,
    required int index,
  }) async {
    final removedItem = fuelList[index];

    setState(() {
      fuelList.removeAt(index);
      calculateSummary(fuelList);
    });

    try {
      await supabase.from('fuel_entries').delete().eq('id', id);

      if (!mounted) return;

      showMessage('Fuel entry deleted successfully.');
    } catch (error) {
      if (!mounted) return;

      setState(() {
        fuelList.insert(index, removedItem);
        calculateSummary(fuelList);
      });

      showMessage(
        'Delete failed: $error',
        isError: true,
      );
    }
  }

  Future<bool> showDeleteConfirmation() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Delete Fuel Entry',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'Are you sure you want to delete this fuel record?',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  void showMessage(
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String formatDate(String value) {
    final date = DateTime.tryParse(value);

    if (date == null) {
      return '--';
    }

    const months = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC',
    ];

    return '${date.day.toString().padLeft(2, '0')}\n'
        '${months[date.month - 1]}';
  }

  String lastUpdatedText() {
    if (fuelList.isEmpty) {
      return 'Last updated: No data';
    }

    final value = fuelList.first['fuel_date']?.toString() ?? '';
    final date = DateTime.tryParse(value);

    if (date == null) {
      return 'Last updated: $value';
    }

    return 'Last updated: '
        '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  Color getGaugeColor() {
    if (fuelPercent <= 20) {
      return Colors.red;
    }

    if (fuelPercent <= 50) {
      return Colors.orange;
    }

    return Colors.green;
  }

  List<FlSpot> chartSpots() {
    if (fuelList.isEmpty) {
      return const [
        FlSpot(0, 0),
      ];
    }

    final reversedList = fuelList.reversed.toList();

    return reversedList.asMap().entries.map((entry) {
      final xValue = entry.key.toDouble();
      final liters = getDouble(entry.value['liters']);

      return FlSpot(xValue, liters);
    }).toList();
  }

  double chartMaxX() {
    if (fuelList.length <= 1) {
      return 1;
    }

    return (fuelList.length - 1).toDouble();
  }

  double chartMaxY() {
    if (fuelList.isEmpty) {
      return tankCapacity;
    }

    double maximumLiters = 0;

    for (final item in fuelList) {
      final liters = getDouble(item['liters']);

      if (liters > maximumLiters) {
        maximumLiters = liters;
      }
    }

    if (maximumLiters < tankCapacity) {
      return tankCapacity;
    }

    return maximumLiters + 2;
  }

  void changePage(int index) {
    if (index == selectedIndex) {
      return;
    }

    late final Widget screen;

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
      MaterialPageRoute(
        builder: (context) => screen,
      ),
    );
  }

  Future<void> openAddFuelDialog() async {
    final result = await showAddFuelDialog(context);

    if (result == true) {
      await loadFuelHistory();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        surfaceTintColor: backgroundColor,
        elevation: 0,
        title: const Text(
          'Fuel Tracker',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      bottomNavigationBar: buildBottomNavigationBar(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: openAddFuelDialog,
        backgroundColor: primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Add Fuel',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: loading
          ? const FuelShimmer()
          : RefreshIndicator(
              onRefresh: loadFuelHistory,
              color: primary,
              backgroundColor: cardColor,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                child: Column(
                  children: [
                    fuelGaugeCard(),
                    const SizedBox(height: 16),
                    summaryCards(),
                    const SizedBox(height: 24),
                    fuelChartCard(),
                    const SizedBox(height: 24),
                    historyTitle(),
                    const SizedBox(height: 14),
                    fuelHistoryList(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: selectedIndex,
      backgroundColor: const Color(0xFF0F172A),
      selectedItemColor: primary,
      unselectedItemColor: Colors.white54,
      type: BottomNavigationBarType.fixed,
      onTap: changePage,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.local_gas_station_outlined),
          activeIcon: Icon(Icons.local_gas_station),
          label: 'Fuel',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.build_outlined),
          activeIcon: Icon(Icons.build),
          label: 'Service',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.route_outlined),
          activeIcon: Icon(Icons.route),
          label: 'Trips',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }

  Widget fuelGaugeCard() {
    final gaugeColor = getGaugeColor();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 24,
      ),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white10,
        ),
      ),
      child: Column(
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
                    strokeCap: StrokeCap.round,
                    backgroundColor: Colors.white12,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      gaugeColor,
                    ),
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.local_gas_station_rounded,
                      color: gaugeColor,
                      size: 34,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${fuelPercent.toStringAsFixed(0)}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '${currentLiters.toStringAsFixed(1)} L / '
                      '${tankCapacity.toStringAsFixed(0)} L',
                      style: const TextStyle(
                        color: Colors.white54,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            lastUpdatedText(),
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget summaryCards() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: miniCard(
                title: 'Avg Mileage',
                value: averageMileage == 0
                    ? '-- km/L'
                    : '${averageMileage.toStringAsFixed(1)} km/L',
                icon: Icons.speed_rounded,
                iconColor: Colors.cyan,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: miniCard(
                title: 'This Month',
                value: '₹${monthlyExpense.toStringAsFixed(0)}',
                icon: Icons.currency_rupee_rounded,
                iconColor: Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        miniCard(
          title: 'Estimated Travel Distance',
          value: estimatedDistance == 0
              ? 'Add more fuel records'
              : '${estimatedDistance.toStringAsFixed(0)} km',
          icon: Icons.route_rounded,
          iconColor: Colors.orange,
          fullWidth: true,
        ),
      ],
    );
  }

  Widget miniCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
    bool fullWidth = false,
  }) {
    final card = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white10,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: iconColor,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );

    if (fullWidth) {
      return card;
    }

    return card;
  }

  Widget fuelChartCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white10,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Fuel Litres History',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Fuel added during each entry',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 220,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: chartMaxX(),
                minY: 0,
                maxY: chartMaxY(),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) {
                    return const FlLine(
                      color: Colors.white10,
                      strokeWidth: 1,
                    );
                  },
                ),
                borderData: FlBorderData(
                  show: false,
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: false,
                    ),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: false,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 34,
                      interval: 2,
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
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt() + 1}',
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (spots) {
                      return spots.map((spot) {
                        return LineTooltipItem(
                          '${spot.y.toStringAsFixed(1)} L',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: chartSpots(),
                    isCurved: true,
                    color: Colors.cyanAccent,
                    barWidth: 4,
                    dotData: const FlDotData(
                      show: true,
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          Colors.cyanAccent.withOpacity(0.25),
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
    return const Row(
      children: [
        Text(
          'Fuel History',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        Spacer(),
        Text(
          'Recent 5',
          style: TextStyle(
            color: Colors.white54,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget fuelHistoryList() {
    if (fuelList.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 40,
        ),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.white10,
          ),
        ),
        child: const Column(
          children: [
            Icon(
              Icons.local_gas_station_outlined,
              color: Colors.white24,
              size: 45,
            ),
            SizedBox(height: 12),
            Text(
              'No fuel records found',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 5),
            Text(
              'Tap Add Fuel to create your first entry.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white54,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    final itemCount = fuelList.length > 5 ? 5 : fuelList.length;

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      separatorBuilder: (context, index) {
        return const SizedBox(height: 12);
      },
      itemBuilder: (context, index) {
        final fuel = fuelList[index];

        final String fuelId = fuel['id'].toString();
        final String date = formatDate(
          fuel['fuel_date']?.toString() ?? '',
        );

        final double litersValue = getDouble(fuel['liters']);
        final double amountValue = getDouble(fuel['amount']);
        final double odometerValue = getDouble(fuel['odometer']);
        final double mileageValue = calculateMileageForIndex(index);

        return Dismissible(
          key: ValueKey(fuelId),
          direction: DismissDirection.endToStart,
          confirmDismiss: (direction) async {
            return showDeleteConfirmation();
          },
          onDismissed: (direction) {
            deleteFuelEntry(
              id: fuelId,
              index: index,
            );
          },
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 22),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.delete_outline_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.white10,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 55,
                  height: 58,
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      date,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        height: 1.3,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${litersValue.toStringAsFixed(1)} L',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Odometer: ${odometerValue.toStringAsFixed(0)} km',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${amountValue.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      mileageValue == 0
                          ? '-- km/L'
                          : '${mileageValue.toStringAsFixed(1)} km/L',
                      style: const TextStyle(
                        color: Colors.cyan,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}