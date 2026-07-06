import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class TripsShimmer extends StatelessWidget {
  const TripsShimmer({super.key});

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
            // Header
            box(height: 120, radius: 24),

            const SizedBox(height: 16),

            // Filter Tabs
            Row(
              children: List.generate(
                3,
                (index) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: box(height: 45, radius: 14),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Search
            box(height: 55, radius: 16),

            const SizedBox(height: 16),

            // Summary Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 4,
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemBuilder: (_, __) => box(height: 120, radius: 18),
            ),

            const SizedBox(height: 20),

            // Map Card
            box(height: 210, radius: 24),

            const SizedBox(height: 20),

            // Trip Cards
            ...List.generate(
              4,
              (_) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: box(height: 150, radius: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}