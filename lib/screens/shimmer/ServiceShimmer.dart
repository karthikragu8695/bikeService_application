import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ServiceShimmer extends StatelessWidget {
  const ServiceShimmer({super.key});

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
            // Top Summary Card
            box(height: 120, radius: 24),

            const SizedBox(height: 16),

            // Summary Cards
            Row(
              children: [
                Expanded(child: box(height: 100)),
                const SizedBox(width: 12),
                Expanded(child: box(height: 100)),
              ],
            ),

            const SizedBox(height: 20),

            // Search Box
            box(height: 55, radius: 16),

            const SizedBox(height: 16),

            // Filter Chips
            Row(
              children: List.generate(
                3,
                (index) => Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: box(
                    width: 90,
                    height: 36,
                    radius: 25,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Service Cards
            ...List.generate(
              5,
              (_) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: box(height: 95, radius: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}