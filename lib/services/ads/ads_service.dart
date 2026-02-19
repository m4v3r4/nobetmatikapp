import 'package:flutter/foundation.dart';

import 'admob_service.dart';
import 'adsense_service.dart';

class AdsService {
  final AdMobService _adMobService = AdMobService();
  final AdSenseService _adSenseService = AdSenseService();

  bool get isAdsEnabled =>
      kIsWeb ? _adSenseService.isAdsEnabled : _adMobService.isAdsEnabled;

  Future<void> initialize() async {
    if (kIsWeb) {
      await _adSenseService.initialize();
      return;
    }
    await _adMobService.initialize();
  }

  Future<void> showInterstitialIfAvailable() async {
    if (kIsWeb) {
      await _adSenseService.showInterstitialIfAvailable();
      return;
    }
    await _adMobService.showInterstitialIfAvailable();
  }

  void dispose() {
    if (kIsWeb) {
      _adSenseService.dispose();
      return;
    }
    _adMobService.dispose();
  }
}
