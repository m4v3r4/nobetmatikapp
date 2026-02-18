import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../services/ads/admob_ids.dart';

class AdBannerStrip extends StatefulWidget {
  const AdBannerStrip({super.key, required this.enabled});

  final bool enabled;

  @override
  State<AdBannerStrip> createState() => _AdBannerStripState();
}

class _AdBannerStripState extends State<AdBannerStrip> {
  BannerAd? _bannerAd;
  bool _loaded = false;

  bool get _canShow {
    if (!widget.enabled) return false;
    if (kIsWeb) return false;
    if (defaultTargetPlatform != TargetPlatform.android) return false;
    return AdMobIds.bannerAdUnitId.isNotEmpty;
  }

  @override
  void initState() {
    super.initState();
    _loadBanner();
  }

  @override
  void didUpdateWidget(covariant AdBannerStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_canShow && _bannerAd == null) {
      _loadBanner();
    }
    if (!_canShow && _bannerAd != null) {
      _disposeBanner();
    }
  }

  @override
  void dispose() {
    _disposeBanner();
    super.dispose();
  }

  void _disposeBanner() {
    _bannerAd?.dispose();
    _bannerAd = null;
    _loaded = false;
  }

  void _loadBanner() {
    if (!_canShow) return;
    if (_bannerAd != null) return;

    final BannerAd ad = BannerAd(
      size: AdSize.banner,
      adUnitId: AdMobIds.bannerAdUnitId,
      listener: BannerAdListener(
        onAdLoaded: (Ad ad) {
          if (!mounted) return;
          setState(() => _loaded = true);
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          ad.dispose();
          if (!mounted) return;
          setState(() {
            _bannerAd = null;
            _loaded = false;
          });
        },
      ),
      request: const AdRequest(),
    );

    _bannerAd = ad;
    ad.load();
  }

  @override
  Widget build(BuildContext context) {
    if (!_canShow || !_loaded || _bannerAd == null) {
      return const SizedBox.shrink();
    }
    return SizedBox(
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }
}
