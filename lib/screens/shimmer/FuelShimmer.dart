import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class FuelShimmer extends StatelessWidget {
  const FuelShimmer({super.key});

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
            box(height: 280, radius: 24),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(child: box(height: 110)),
                const SizedBox(width: 12),
                Expanded(child: box(height: 110)),
              ],
            ),

            const SizedBox(height: 20),

            box(height: 260, radius: 20),

            const SizedBox(height: 20),

            box(height: 24, width: 150),

            const SizedBox(height: 16),

            ...List.generate(
              5,
              (_) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: box(height: 78, radius: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}