// ignore_for_file: avoid_web_libraries_in_flutter

import 'package:web/web.dart' as web;
import 'adsense_ids.dart';

class AdSenseService {
  static bool _scriptInjected = false;
  bool _isEnabled = false;
  bool _isInitialized = false;

  bool get isAdsEnabled => _isEnabled;

  Future<void> initialize() async {
    if (_isInitialized) return;
    if (AdSenseIds.adClient.isEmpty || AdSenseIds.bannerSlotId.isEmpty) return;

    _injectScriptIfNeeded();
    _isInitialized = true;
    _isEnabled = true;
  }

  Future<void> showInterstitialIfAvailable() async {
    // AdSense tarafinda uygulama ici gecislerde interstitial kullanilmiyor.
  }

  void dispose() {}

  void _injectScriptIfNeeded() {
    if (_scriptInjected) return;

    final web.HTMLScriptElement
    script = web.document.createElement('script') as web.HTMLScriptElement
      ..async = true
      ..src =
          'https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js?client=${AdSenseIds.adClient}'
      ..crossOrigin = 'anonymous';

    web.document.head?.append(script);
    _scriptInjected = true;
  }
}
