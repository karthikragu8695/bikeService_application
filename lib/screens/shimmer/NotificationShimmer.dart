import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';


class NotificationShimmer extends StatelessWidget {
  const NotificationShimmer({super.key});

  Widget box({
    double height = 80,
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
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: List.generate(
          6,
          (_) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: box(height: 86, radius: 18),
          ),
        ),
      ),
    );
  }
}