import 'package:bikeservice/screens/ProfileScreen.dart';
import 'package:bikeservice/screens/TripsScreen.dart';
import 'package:bikeservice/screens/fuel.dart';
import 'package:bikeservice/screens/home.dart';
import 'package:bikeservice/screens/shimmer/ServiceShimmer.dart';
import 'package:bikeservice/widget/Addservice.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ServiceScreen extends StatefulWidget {
  const ServiceScreen({super.key});

  @override
  State<ServiceScreen> createState() => _ServiceScreenState();
}

class _ServiceScreenState extends State<ServiceScreen> {
  final supabase = Supabase.instance.client;

  static const primary = Color(0xFFFF5A1F);

  int selectedIndex = 2;
  bool loading = true;

  List<dynamic> allServices = [];
  List<dynamic> filteredServices = [];

  double totalServiceCost = 0;
  int serviceDueKm = 0;
  int totalServices = 0;

  String selectedFilter = "All";
  final searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadServices();
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
        .select('id, current_km')
        .eq('user_id', user.id)
        .maybeSingle();
  }

  Future<void> loadServices() async {
    try {
      if (mounted) setState(() => loading = true);

      final bike = await getBike();

      if (bike == null) {
        if (!mounted) return;
        setState(() {
          allServices = [];
          filteredServices = [];
          totalServiceCost = 0;
          serviceDueKm = 0;
          totalServices = 0;
          loading = false;
        });
        return;
      }

      final data = await supabase
          .from('services')
          .select()
          .eq('bike_id', bike['id'])
          .order('service_date', ascending: false);

      calculateSummary(data, bike);

      if (!mounted) return;

      setState(() {
        allServices = data;
        filteredServices = data;
        loading = false;
      });

      applyFilter();
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Service Load Error: $e")),
      );
    }
  }

  void calculateSummary(List<dynamic> data, Map<String, dynamic> bike) {
    totalServiceCost = 0;
    totalServices = data.length;
    serviceDueKm = 0;

    final now = DateTime.now();

    for (final item in data) {
      final date = DateTime.tryParse(item['service_date']?.toString() ?? "");
      final cost = (item['cost'] as num?)?.toDouble() ?? 0;

      if (date != null && date.year == now.year) {
        totalServiceCost += cost;
      }
    }

    if (data.isNotEmpty) {
      final latestService = data.first;
      final currentKm = (bike['current_km'] as num?)?.toInt() ?? 0;
      final nextKm = (latestService['next_service_km'] as num?)?.toInt() ?? 0;

      serviceDueKm = nextKm > currentKm ? nextKm - currentKm : 0;
    }
  }

  void applyFilter() {
    List<dynamic> result = List.from(allServices);

    final now = DateTime.now();

    if (selectedFilter == "This Year") {
      result = result.where((item) {
        final date = DateTime.tryParse(item['service_date']?.toString() ?? "");
        return date != null && date.year == now.year;
      }).toList();
    }

    if (selectedFilter == "This Month") {
      result = result.where((item) {
        final date = DateTime.tryParse(item['service_date']?.toString() ?? "");
        return date != null &&
            date.year == now.year &&
            date.month == now.month;
      }).toList();
    }

    final keyword = searchController.text.trim().toLowerCase();

    if (keyword.isNotEmpty) {
      result = result.where((item) {
        final type = item['service_type']?.toString().toLowerCase() ?? "";
        final notes = item['notes']?.toString().toLowerCase() ?? "";
        return type.contains(keyword) || notes.contains(keyword);
      }).toList();
    }

    setState(() {
      filteredServices = result;
    });
  }

  Future<void> deleteService(dynamic serviceId) async {
    try {
      await supabase.from('services').delete().eq('id', serviceId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Service deleted")),
      );

      await loadServices();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Delete Error: $e")),
      );
    }
  }

  String formatDate(String date) {
    final d = DateTime.tryParse(date);
    if (d == null) return date;

    const months = [
      "Jan", "Feb", "Mar", "Apr", "May", "Jun",
      "Jul", "Aug", "Sep", "Oct", "Nov", "Dec",
    ];

    return "${d.day} ${months[d.month - 1]} ${d.year}";
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
    return Scaffold(
      backgroundColor: const Color(0xFF070B14),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
       // leading: const BackButton(color: Colors.white),
        centerTitle: true,
        title: const Text(
          "Service Tracker",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
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
        label: const Text("Add Service", style: TextStyle(color: Colors.white)),
        onPressed: () async {
          final result = await showAddServiceDialog(context);

          if (result == true) {
            await loadServices();
          }
        },
      ),
      body: loading
          ? const ServiceShimmer()
          : RefreshIndicator(
              onRefresh: loadServices,
              color: primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    topSummaryCard(),
                    const SizedBox(height: 16),
                    smallSummaryCards(),
                    const SizedBox(height: 20),
                    searchBox(),
                    const SizedBox(height: 14),
                    filterChips(),
                    const SizedBox(height: 22),
                    historyTitle(),
                    const SizedBox(height: 14),
                    serviceList(),
                    const SizedBox(height: 90),
                  ],
                ),
              ),
            ),
    );
  }

  Widget topSummaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            height: 70,
            width: 70,
            decoration: BoxDecoration(
              color: primary.withOpacity(.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.miscellaneous_services,
              color: primary,
              size: 38,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Total Service Cost",
                  style: TextStyle(color: Colors.white54),
                ),
                const SizedBox(height: 6),
                Text(
                  "₹ ${totalServiceCost.toStringAsFixed(0)}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  "This Year",
                  style: TextStyle(color: Colors.white54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget smallSummaryCards() {
    return Row(
      children: [
        Expanded(
          child: miniCard(
            title: "Next Service",
            value: serviceDueKm == 0 ? "--" : "$serviceDueKm km",
            icon: Icons.speed,
            color: Colors.orange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: miniCard(
            title: "Services",
            value: "$totalServices",
            icon: Icons.build_circle,
            color: Colors.green,
          ),
        ),
      ],
    );
  }

  Widget miniCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 3),
          Text(title, style: const TextStyle(color: Colors.white54)),
        ],
      ),
    );
  }

  Widget searchBox() {
    return TextField(
      controller: searchController,
      onChanged: (_) => applyFilter(),
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: "Search service...",
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

  Widget filterChips() {
    final filters = ["All", "This Month", "This Year"];

    return Row(
      children: filters.map((filter) {
        final selected = selectedFilter == filter;

        return Padding(
          padding: const EdgeInsets.only(right: 10),
          child: ChoiceChip(
            label: Text(filter),
            selected: selected,
            selectedColor: primary,
            backgroundColor: const Color(0xFF111827),
            labelStyle: TextStyle(
              color: selected ? Colors.white : Colors.white54,
            ),
            onSelected: (_) {
              setState(() {
                selectedFilter = filter;
              });
              applyFilter();
            },
          ),
        );
      }).toList(),
    );
  }

  Widget historyTitle() {
    return Row(
      children: const [
        Text(
          "Service History",
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

  Widget serviceList() {
    if (filteredServices.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: const Color(0xFF111827),
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Center(
          child: Text(
            "No service records found",
            style: TextStyle(color: Colors.white54),
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filteredServices.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final service = filteredServices[index];

        final serviceId = service['id'];
        final title = service['service_type']?.toString() ?? "Service";
        final date = formatDate(service['service_date']?.toString() ?? "");
        final amount =
            "₹ ${((service['cost'] as num?)?.toDouble() ?? 0).toStringAsFixed(0)}";
        final nextKm =
            (service['next_service_km'] as num?)?.toInt() ?? 0;
        final notes = service['notes']?.toString() ?? "";

        return Dismissible(
          key: ValueKey(serviceId),
          direction: DismissDirection.endToStart,
          confirmDismiss: (_) async {
            return await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    backgroundColor: const Color(0xFF111827),
                    title: const Text(
                      "Delete Service?",
                      style: TextStyle(color: Colors.white),
                    ),
                    content: const Text(
                      "Are you sure want to delete this service?",
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
          onDismissed: (_) => deleteService(serviceId),
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          child: serviceCard(
            title: title,
            date: date,
            amount: amount,
            nextKm: nextKm,
            notes: notes,
          ),
        );
      },
    );
  }

  Widget serviceCard({
    required String title,
    required String date,
    required String amount,
    required int nextKm,
    required String notes,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            radius: 24,
            backgroundColor: Colors.green,
            child: Icon(Icons.check, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(date, style: const TextStyle(color: Colors.white54)),
                if (nextKm > 0) ...[
                  const SizedBox(height: 6),
                  Text(
                    "Next Service: $nextKm km",
                    style: const TextStyle(color: Colors.orange),
                  ),
                ],
                if (notes.trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    notes,
                    style: const TextStyle(color: Colors.white38),
                  ),
                ],
              ],
            ),
          ),
          Text(
            amount,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}