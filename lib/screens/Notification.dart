import 'package:bikeservice/screens/shimmer/NotificationShimmer.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final supabase = Supabase.instance.client;

  static const primary = Color(0xFFFF5A1F);

  bool loading = true;
  List<Map<String, dynamic>> notifications = [];

  @override
  void initState() {
    super.initState();
    loadNotifications();
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

  Future<void> loadNotifications() async {
    try {
      setState(() => loading = true);

      final bike = await getBike();

      if (bike == null) {
        if (!mounted) return;
        setState(() {
          notifications = [];
          loading = false;
        });
        return;
      }

      final service = await supabase
          .from('services')
          .select()
          .eq('bike_id', bike['id'])
          .order('service_date', ascending: false)
          .limit(1)
          .maybeSingle();

      final fuel = await supabase
          .from('fuel_entries')
          .select()
          .eq('bike_id', bike['id'])
          .order('fuel_date', ascending: false)
          .limit(1)
          .maybeSingle();

      final List<Map<String, dynamic>> list = [];

      final currentKm = (bike['current_km'] as num?)?.toInt() ?? 0;

      if (service != null) {
        final nextKm = (service['next_service_km'] as num?)?.toInt() ?? 0;
        final dueKm = nextKm - currentKm;

        if (nextKm > 0 && dueKm <= 500 && dueKm > 0) {
          list.add({
            'title': 'Service Reminder',
            'message': 'Your bike service is due in $dueKm km.',
            'icon': Icons.build,
            'color': Colors.orange,
            'time': 'Today',
          });
        }

        if (nextKm > 0 && dueKm <= 0) {
          list.add({
            'title': 'Service Overdue',
            'message': 'Your bike service is overdue. Please service soon.',
            'icon': Icons.warning_amber,
            'color': Colors.red,
            'time': 'Today',
          });
        }
      }

      if (fuel != null) {
        final liters = (fuel['liters'] as num?)?.toDouble() ?? 0;
        const tankCapacity = 13.0;
        final percent = ((liters / tankCapacity) * 100).clamp(0, 100);

        if (percent <= 25) {
          list.add({
            'title': 'Low Fuel Alert',
            'message': 'Fuel level is ${percent.toStringAsFixed(0)}%. Please refill soon.',
            'icon': Icons.local_gas_station,
            'color': Colors.redAccent,
            'time': 'Today',
          });
        }
      }

      if (list.isEmpty) {
        list.add({
          'title': 'All Good',
          'message': 'No important alerts right now. Your bike status looks good.',
          'icon': Icons.check_circle,
          'color': Colors.green,
          'time': 'Now',
        });
      }

      if (!mounted) return;

      setState(() {
        notifications = list;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Notification Load Error: $e")),
      );
    }
  }

  void clearNotifications() {
    setState(() {
      notifications.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070B14),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        title: const Text(
          "Notifications",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: clearNotifications,
            child: const Text(
              "Clear",
              style: TextStyle(color: primary),
            ),
          ),
        ],
      ),
      body: loading
          ? const NotificationShimmer()
          : RefreshIndicator(
              onRefresh: loadNotifications,
              color: primary,
              child: notifications.isEmpty
                  ? ListView(
                      padding: const EdgeInsets.all(16),
                      children: const [
                        SizedBox(height: 120),
                        Icon(
                          Icons.notifications_off,
                          color: Colors.white24,
                          size: 80,
                        ),
                        SizedBox(height: 20),
                        Center(
                          child: Text(
                            "No notifications",
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: notifications.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final item = notifications[index];

                        return notificationCard(
                          title: item['title'],
                          message: item['message'],
                          icon: item['icon'],
                          color: item['color'],
                          time: item['time'],
                        );
                      },
                    ),
            ),
    );
  }

  Widget notificationCard({
    required String title,
    required String message,
    required IconData icon,
    required Color color,
    required String time,
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
          CircleAvatar(
            radius: 25,
            backgroundColor: color.withOpacity(.18),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      time,
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white54,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}