import 'package:flutter/widgets.dart';

class AdSenseBanner extends StatelessWidget {
  const AdSenseBanner({
    super.key,
    required this.adClient,
    required this.adSlot,
    this.height = 90,
  });

  final String adClient;
  final String adSlot;
  final double height;

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
