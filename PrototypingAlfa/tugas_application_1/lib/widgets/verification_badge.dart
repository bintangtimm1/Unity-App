import 'package:flutter/material.dart';

class VerificationBadge extends StatelessWidget {
  final String tier;
  final double size;
  const VerificationBadge({super.key, required this.tier, this.size = 16});

  @override
  Widget build(BuildContext context) {
    if (tier == 'blue') {
      return Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Icon(Icons.verified, color: Colors.blue, size: size),
      );
    }
    if (tier == 'gold') {
      return Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Icon(Icons.verified, color: Colors.amber, size: size),
      );
    }
    return const SizedBox.shrink();
  }
}
