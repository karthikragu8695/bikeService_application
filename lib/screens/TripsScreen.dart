import 'package:bikeservice/screens/ProfileScreen.dart';
import 'package:bikeservice/screens/fuel.dart';
import 'package:bikeservice/screens/home.dart';
import 'package:bikeservice/screens/service.dart';
import 'package:bikeservice/screens/shimmer/TripsShimmer.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TripsScreen extends StatefulWidget {
  const TripsScreen({super.key});

  @override
  State<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends State<TripsScreen> {
  final supabase = Supabase.instance.client;

  static const primary = Color(0xFFFF5A1F);

  int selectedIndex = 3;
  int selectedTab = 0;
  bool loading = true;

  final searchController = TextEditingController();

  List<dynamic> allTrips = [];
  List<dynamic> filteredTrips = [];

  double totalDistance = 0;
  double totalFuel = 0;
  int totalDuration = 0;
  double avgMileage = 0;

  @override
  void initState() {
    super.initState();
    loadTrips();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>?> getBike() async {
    final user = supabase.auth.currentUser;
    if (user == null) return null;

    return await supabase
        .from('bikes')
        .select('id')
        .eq('user_id', user.id)
        .maybeSingle();
  }

  Future<void> loadTrips() async {
    try {
      if (!mounted) setState(() => loading = true);

      final bike = await getBike();

      if (bike == null) {
        if (!mounted) return;
        setState(() {
          allTrips = [];
          filteredTrips = [];
          loading = false;
        });
        return;
      }

      final data = await supabase
          .from('trips')
          .select()
          .eq('bike_id', bike['id'])
          .order('trip_date', ascending: false);

      if (!mounted) return;

      setState(() {
        allTrips = data;
        loading = false;
      });

      applyFilter();
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Trip Load Error: $e")));
    }
  }

  void applyFilter() {
    List<dynamic> result = List.from(allTrips);
    final now = DateTime.now();

    if (selectedTab == 1) {
      result = result.where((trip) {
        final date = DateTime.tryParse(trip['trip_date']?.toString() ?? "");
        return date != null && date.month == now.month && date.year == now.year;
      }).toList();
    }

    if (selectedTab == 2) {
      result = result.where((trip) {
        final date = DateTime.tryParse(trip['trip_date']?.toString() ?? "");
        return date != null && date.year == now.year;
      }).toList();
    }

    final keyword = searchController.text.trim().toLowerCase();

    if (keyword.isNotEmpty) {
      result = result.where((trip) {
        final title = trip['title']?.toString().toLowerCase() ?? "";
        final notes = trip['notes']?.toString().toLowerCase() ?? "";
        return title.contains(keyword) || notes.contains(keyword);
      }).toList();
    }

    double distance = 0;
    double fuel = 0;
    int duration = 0;

    for (final trip in result) {
      distance += (trip['distance_km'] as num?)?.toDouble() ?? 0;
      fuel += (trip['fuel_used'] as num?)?.toDouble() ?? 0;
      duration += (trip['duration_min'] as num?)?.toInt() ?? 0;
    }

    setState(() {
      filteredTrips = result;
      totalDistance = distance;
      totalFuel = fuel;
      totalDuration = duration;
      avgMileage = fuel > 0 ? distance / fuel : 0;
    });
  }

  Future<void> deleteTrip(dynamic tripId) async {
    try {
      await supabase.from('trips').delete().eq('id', tripId);

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Trip deleted")));

      await loadTrips();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Delete Error: $e")));
    }
  }

  String formatDate(String date) {
    final d = DateTime.tryParse(date);
    if (d == null) return date;

    const months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec",
    ];

    return "${d.day} ${months[d.month - 1]} ${d.year}";
  }

  String formatDuration(int minutes) {
    if (minutes < 60) return "$minutes min";
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? "$h hr" : "$h hr $m min";
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

  Future<void> showAddTripDialog() async {
    final titleController = TextEditingController();
    final distanceController = TextEditingController();
    final durationController = TextEditingController();
    final fuelController = TextEditingController();
    final notesController = TextEditingController();
    final dateController = TextEditingController();

    dateController.text = DateTime.now().toIso8601String().split('T')[0];

    bool isLoading = false;

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF111827),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> saveTrip() async {
              final user = supabase.auth.currentUser;
              if (user == null) return;

              if (titleController.text.trim().isEmpty ||
                  distanceController.text.trim().isEmpty ||
                  durationController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Please fill required fields")),
                );
                return;
              }

              try {
                setModalState(() => isLoading = true);

                final bike = await getBike();

                if (bike == null) {
                  if (context.mounted) {
                    setModalState(() => isLoading = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Bike not found")),
                    );
                  }
                  return;
                }

                await supabase.from('trips').insert({
                  'user_id': user.id,
                  'bike_id': bike['id'],
                  'trip_date': dateController.text.trim(),
                  'title': titleController.text.trim(),
                  'distance_km':
                      double.tryParse(distanceController.text.trim()) ?? 0,
                  'duration_min':
                      int.tryParse(durationController.text.trim()) ?? 0,
                  'fuel_used': double.tryParse(fuelController.text.trim()) ?? 0,
                  'notes': notesController.text.trim(),
                });

                if (context.mounted) {
                  Navigator.pop(context, true);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Trip saved successfully")),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  setModalState(() => isLoading = false);
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text("Save Error: $e")));
                }
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 60,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "Add New Trip",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    tripField(
                      controller: dateController,
                      label: "Trip Date",
                      icon: Icons.calendar_month,
                      readOnly: true,
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );

                        if (picked != null) {
                          dateController.text = picked.toIso8601String().split(
                            'T',
                          )[0];
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    tripField(
                      controller: titleController,
                      label: "Trip Title",
                      icon: Icons.route,
                    ),
                    const SizedBox(height: 12),
                    tripField(
                      controller: distanceController,
                      label: "Distance KM",
                      icon: Icons.speed,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    tripField(
                      controller: durationController,
                      label: "Duration Minutes",
                      icon: Icons.timer,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    tripField(
                      controller: fuelController,
                      label: "Fuel Used Liter",
                      icon: Icons.local_gas_station,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    tripField(
                      controller: notesController,
                      label: "Notes",
                      icon: Icons.note_alt_outlined,
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          disabledBackgroundColor: Colors.grey,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: isLoading ? null : saveTrip,
                        child: isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Text(
                                "Save Trip",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (result == true) {
      await loadTrips();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070B14),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Trip Analytics",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        //  leading: const BackButton(color: Colors.white),
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
        label: const Text("Add Trip", style: TextStyle(color: Colors.white)),
        onPressed: showAddTripDialog,
      ),
      body: loading
          ? const TripsShimmer()
          : RefreshIndicator(
              onRefresh: loadTrips,
              color: primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    premiumHeader(),
                    const SizedBox(height: 16),
                    filterTabs(),
                    const SizedBox(height: 16),
                    searchBox(),
                    const SizedBox(height: 16),
                    summaryGrid(),
                    const SizedBox(height: 20),
                    premiumMapCard(),
                    const SizedBox(height: 22),
                    historyTitle(),
                    const SizedBox(height: 14),
                    tripList(),
                    const SizedBox(height: 90),
                  ],
                ),
              ),
            ),
    );
  }

  Widget premiumHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primary.withOpacity(.95), const Color(0xFF7C2D12)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            height: 65,
            width: 65,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.18),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.route, color: Colors.white, size: 35),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Total Ride Distance",
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 5),
                Text(
                  "${totalDistance.toStringAsFixed(1)} km",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "${filteredTrips.length} trips recorded",
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget filterTabs() {
    return Row(
      children: [
        buildTab("All", 0),
        const SizedBox(width: 10),
        buildTab("Month", 1),
        const SizedBox(width: 10),
        buildTab("Year", 2),
      ],
    );
  }

  Widget buildTab(String title, int index) {
    final isSelected = selectedTab == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedTab = index;
          });
          applyFilter();
        },
        child: Container(
          height: 45,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? primary : const Color(0xFF111827),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white10),
          ),
          child: Text(
            title,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white54,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget searchBox() {
    return TextField(
      controller: searchController,
      onChanged: (_) => applyFilter(),
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: "Search trips...",
        hintStyle: const TextStyle(color: Colors.white38),
        prefixIcon: const Icon(Icons.search, color: Colors.white54),
        filled: true,
        fillColor: const Color(0xFF111827),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget summaryGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.15,
      children: [
        statCard(
          "Duration",
          formatDuration(totalDuration),
          Icons.timer,
          Colors.orange,
        ),
        statCard(
          "Fuel Used",
          "${totalFuel.toStringAsFixed(1)} L",
          Icons.local_gas_station,
          Colors.green,
        ),
        statCard(
          "Mileage",
          "${avgMileage.toStringAsFixed(1)} km/L",
          Icons.speed,
          Colors.cyan,
        ),
        statCard(
          "Trips",
          "${filteredTrips.length}",
          Icons.two_wheeler,
          Colors.purpleAccent,
        ),
      ],
    );
  }

  Widget statCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
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
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget premiumMapCard() {
    return Container(
      height: 210,
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
      ),
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: MapPatternPainter())),
          Positioned(
            left: 20,
            top: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(.35),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                "Ride Route Preview",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
          Positioned(left: 55, bottom: 55, child: mapMarker(Colors.green)),
          Positioned(left: 145, top: 90, child: mapMarker(Colors.blue)),
          Positioned(right: 55, top: 45, child: mapMarker(Colors.red)),
          Positioned(
            right: 18,
            bottom: 18,
            child: Text(
              "${filteredTrips.length} routes",
              style: const TextStyle(color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }

  Widget mapMarker(Color color) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(.5),
            blurRadius: 12,
            spreadRadius: 3,
          ),
        ],
      ),
    );
  }

  Widget historyTitle() {
    return Row(
      children: const [
        Text(
          "Trip History",
          style: TextStyle(
            color: Colors.white,
            fontSize: 19,
            fontWeight: FontWeight.bold,
          ),
        ),
        Spacer(),
        Text(
          "Swipe to delete",
          style: TextStyle(color: Colors.white38, fontSize: 12),
        ),
      ],
    );
  }

  Widget tripList() {
    if (filteredTrips.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF111827),
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Center(
          child: Text(
            "No trips found",
            style: TextStyle(color: Colors.white54),
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filteredTrips.length,
      separatorBuilder: (_, _) => const SizedBox(height: 15),
      itemBuilder: (context, index) {
        final trip = filteredTrips[index];

        final tripId = trip['id'];
        final date = formatDate(trip['trip_date']?.toString() ?? "");
        final title = trip['title']?.toString() ?? "Trip";
        final notes = trip['notes']?.toString() ?? "";

        final distanceValue = (trip['distance_km'] as num?)?.toDouble() ?? 0;
        final fuelValue = (trip['fuel_used'] as num?)?.toDouble() ?? 0;
        final durationValue = (trip['duration_min'] as num?)?.toInt() ?? 0;

        final distance = "${distanceValue.toStringAsFixed(1)} km";
        final duration = formatDuration(durationValue);
        final fuel = "${fuelValue.toStringAsFixed(1)} L";
        final mileage = fuelValue > 0
            ? "${(distanceValue / fuelValue).toStringAsFixed(1)} km/L"
            : "--";

        return Dismissible(
          key: ValueKey(tripId),
          direction: DismissDirection.endToStart,
          confirmDismiss: (_) async {
            return await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    backgroundColor: const Color(0xFF111827),
                    title: const Text(
                      "Delete Trip?",
                      style: TextStyle(color: Colors.white),
                    ),
                    content: const Text(
                      "Are you sure want to delete this trip?",
                      style: TextStyle(color: Colors.white54),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text("Cancel"),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text(
                          "Delete",
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ) ??
                false;
          },
          onDismissed: (_) => deleteTrip(tripId),
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          child: tripCard(
            date: date,
            title: title,
            distance: distance,
            duration: duration,
            fuel: fuel,
            mileage: mileage,
            notes: notes,
          ),
        );
      },
    );
  }

  Widget tripCard({
    required String date,
    required String title,
    required String distance,
    required String duration,
    required String fuel,
    required String mileage,
    required String notes,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(date, style: const TextStyle(color: Colors.white54)),
          const SizedBox(height: 10),
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: primary,
                child: Icon(Icons.route, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (notes.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(notes, style: const TextStyle(color: Colors.white38)),
          ],
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(child: statItem(distance, "Distance")),
              Expanded(child: statItem(duration, "Duration")),
              Expanded(child: statItem(fuel, "Fuel")),
              Expanded(child: statItem(mileage, "Mileage")),
            ],
          ),
        ],
      ),
    );
  }

  Widget statItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 11),
        ),
      ],
    );
  }
}

class MapPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final roadPaint = Paint()
      ..color = Colors.white.withOpacity(.13)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    final thinRoadPaint = Paint()
      ..color = Colors.white.withOpacity(.07)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final routePaint = Paint()
      ..color = const Color(0xFFFF5A1F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    final path1 = Path()
      ..moveTo(0, size.height * .30)
      ..cubicTo(
        size.width * .25,
        size.height * .10,
        size.width * .40,
        size.height * .70,
        size.width,
        size.height * .45,
      );

    final path2 = Path()
      ..moveTo(size.width * .15, 0)
      ..cubicTo(
        size.width * .45,
        size.height * .25,
        size.width * .20,
        size.height * .65,
        size.width * .65,
        size.height,
      );

    final path3 = Path()
      ..moveTo(0, size.height * .75)
      ..quadraticBezierTo(
        size.width * .50,
        size.height * .45,
        size.width,
        size.height * .85,
      );

    final route = Path()
      ..moveTo(size.width * .18, size.height * .75)
      ..cubicTo(
        size.width * .35,
        size.height * .55,
        size.width * .48,
        size.height * .42,
        size.width * .62,
        size.height * .45,
      )
      ..quadraticBezierTo(
        size.width * .78,
        size.height * .50,
        size.width * .83,
        size.height * .25,
      );

    canvas.drawPath(path1, roadPaint);
    canvas.drawPath(path2, thinRoadPaint);
    canvas.drawPath(path3, thinRoadPaint);
    canvas.drawPath(route, routePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

Widget tripField({
  required TextEditingController controller,
  required String label,
  required IconData icon,
  TextInputType keyboardType = TextInputType.text,
  bool readOnly = false,
  VoidCallback? onTap,
}) {
  return TextField(
    controller: controller,
    readOnly: readOnly,
    onTap: onTap,
    keyboardType: keyboardType,
    style: const TextStyle(color: Colors.white),
    decoration: InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white54),
      prefixIcon: Icon(icon, color: Colors.white54),
      filled: true,
      fillColor: const Color(0xFF1A2234),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    ),
  );
}
