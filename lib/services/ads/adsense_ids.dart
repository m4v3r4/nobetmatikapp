class AdSenseIds {
  // Web yayin icin --dart-define ile verin:
  // ADSENSE_CLIENT=ca-pub-xxxxxxxxxxxxxxxx
  // ADSENSE_BANNER_SLOT=1234567890
  static const String adClient = String.fromEnvironment(
    'ca-pub-8870945603882381',
    defaultValue: '',
  );

  static const String bannerSlotId = String.fromEnvironment(
    'ADSENSE_BANNER_SLOT',
    defaultValue: '',
  );
}
