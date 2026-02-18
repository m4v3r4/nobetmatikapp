import 'dart:async';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'admob_ids.dart';

class AdMobService {
  InterstitialAd? _interstitialAd;
  bool _isLoadingInterstitial = false;
  bool _isInitialized = false;
  bool _isEnabled = false;
  bool get isAdsEnabled => _isEnabled;

  bool get _isSupportedPlatform =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<void> initialize() async {
    if (_isInitialized || !_isSupportedPlatform) return;
    if (AdMobIds.appId.isEmpty || AdMobIds.interstitialAdUnitId.isEmpty) return;
    if (!await _canUseAdsOnDevice()) return;

    await MobileAds.instance.initialize();
    _isInitialized = true;
    _isEnabled = true;
    await loadInterstitial();
  }

  Future<void> loadInterstitial() async {
    if (!_isInitialized ||
        !_isEnabled ||
        _isLoadingInterstitial ||
        _interstitialAd != null) {
      return;
    }

    _isLoadingInterstitial = true;
    await InterstitialAd.load(
      adUnitId: AdMobIds.interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          _interstitialAd = ad;
          _isLoadingInterstitial = false;
        },
        onAdFailedToLoad: (LoadAdError error) {
          _isLoadingInterstitial = false;
        },
      ),
    );
  }

  Future<void> showInterstitialIfAvailable() async {
    if (!_isInitialized || !_isEnabled) return;
    if (_interstitialAd == null) {
      await loadInterstitial();
      return;
    }

    final Completer<void> completer = Completer<void>();
    final InterstitialAd ad = _interstitialAd!;
    _interstitialAd = null;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (InterstitialAd ad) {
        ad.dispose();
        if (!completer.isCompleted) completer.complete();
        loadInterstitial();
      },
      onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
        ad.dispose();
        if (!completer.isCompleted) completer.complete();
        loadInterstitial();
      },
    );

    ad.show();
    await completer.future.timeout(
      const Duration(seconds: 5),
      onTimeout: () {},
    );
  }

  void dispose() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
  }

  Future<bool> _canUseAdsOnDevice() async {
    if (kDebugMode) return false;
    if (kIsWeb) return false;

    if (defaultTargetPlatform == TargetPlatform.android) {
      final AndroidDeviceInfo androidInfo =
          await DeviceInfoPlugin().androidInfo;
      if (!androidInfo.isPhysicalDevice) return false;
      // Eski Android + OEM/emulator kombinasyonlarında Google Ads modul crash edebiliyor.
      if (androidInfo.version.sdkInt < 31) return false;
      return true;
    }

    return false;
  }
}
