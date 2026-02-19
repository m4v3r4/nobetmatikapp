// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

class AdSenseBanner extends StatefulWidget {
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
  State<AdSenseBanner> createState() => _AdSenseBannerState();
}

class _AdSenseBannerState extends State<AdSenseBanner> {
  static int _counter = 0;

  late final String _viewType;
  bool _requested = false;

  @override
  void initState() {
    super.initState();
    _viewType = 'adsense-banner-${_counter++}';
    _registerViewFactory();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestAd();
    });
  }

  void _registerViewFactory() {
    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
      final web.HTMLElement container =
          web.document.createElement('div') as web.HTMLElement;
      container.setAttribute(
        'style',
        'display:block;width:100%;height:${widget.height}px;',
      );

      final web.HTMLElement adElement =
          web.document.createElement('ins') as web.HTMLElement;
      adElement.className = 'adsbygoogle';
      adElement.setAttribute(
        'style',
        'display:block;width:100%;height:${widget.height}px;',
      );
      adElement.setAttribute('data-ad-client', widget.adClient);
      adElement.setAttribute('data-ad-slot', widget.adSlot);
      adElement.setAttribute('data-ad-format', 'horizontal');
      adElement.setAttribute('data-full-width-responsive', 'true');
      container.append(adElement);
      return container;
    });
  }

  void _requestAd() {
    if (_requested) return;

    try {
      final web.HTMLScriptElement script =
          web.document.createElement('script') as web.HTMLScriptElement;
      script.text = '(adsbygoogle = window.adsbygoogle || []).push({});';
      web.document.body?.append(script);
      _requested = true;
    } catch (_) {
      // Script henuz yuklenmediyse sessizce gec.
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: HtmlElementView(viewType: _viewType),
    );
  }
}
