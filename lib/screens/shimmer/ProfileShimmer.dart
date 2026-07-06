import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';


class ProfileShimmer extends StatelessWidget {
  const ProfileShimmer({super.key});

  Widget box({
    double height = 100,
    double width = double.infinity,
    double radius = 18,
  }) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFF1E293B),
      highlightColor: const Color(0xFF334155),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Profile Header
            box(height: 120, radius: 26),

            const SizedBox(height: 16),

            // Stats
            Row(
              children: [
                Expanded(child: box(height: 110)),
                const SizedBox(width: 10),
                Expanded(child: box(height: 110)),
                const SizedBox(width: 10),
                Expanded(child: box(height: 110)),
              ],
            ),

            const SizedBox(height: 16),

            // Bike Card
            box(height: 110, radius: 22),

            const SizedBox(height: 20),

            // Menu Items
            ...List.generate(
              6,
              (_) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: box(height: 60, radius: 16),
              ),
            ),

            const SizedBox(height: 20),

            // Logout Button
            box(height: 55, radius: 16),
          ],
        ),
      ),
    );
  }
}