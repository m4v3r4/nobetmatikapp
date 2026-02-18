import 'package:flutter/foundation.dart';

class AdMobIds {
  // Uretim ID'leri
  static const String _androidAppId = 'ca-app-pub-8870945603882381~7933131496';
  static const String _iosAppId = 'ca-app-pub-8870945603882381~7933131496';
  static const String _androidInterstitialId =
      'ca-app-pub-8870945603882381/3993886484';
  static const String _iosInterstitialId =
      'ca-app-pub-8870945603882381/3993886484';
  static const String _androidBannerId =
      'ca-app-pub-8870945603882381/6782769141';
  static const String _iosBannerId = 'ca-app-pub-8870945603882381/6995598825';

  static String get appId {
    if (kIsWeb) return '';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return _androidAppId;
      case TargetPlatform.iOS:
        return _iosAppId;
      default:
        return '';
    }
  }

  static String get interstitialAdUnitId {
    if (kIsWeb) return '';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return _androidInterstitialId;
      case TargetPlatform.iOS:
        return _iosInterstitialId;
      default:
        return '';
    }
  }

  static String get bannerAdUnitId {
    if (kIsWeb) return '';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return _androidBannerId;
      case TargetPlatform.iOS:
        return _iosBannerId;
      default:
        return '';
    }
  }
}
