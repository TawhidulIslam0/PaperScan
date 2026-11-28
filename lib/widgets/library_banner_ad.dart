import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/ad_service.dart';

class LibraryBannerAd extends StatefulWidget {
  const LibraryBannerAd({super.key});
  @override
  State<LibraryBannerAd> createState() => _LibraryBannerAdState();
}

class _LibraryBannerAdState extends State<LibraryBannerAd> {
  BannerAd? ad;
  bool loaded = false;

  @override
  void initState() {
    super.initState();
    ad = BannerAd(
      adUnitId: AdService.bannerTestId,
      size: AdSize.banner,
      request: const AdRequest(nonPersonalizedAds: true),
      listener: BannerAdListener(
        onAdLoaded: (ad) { if (mounted) setState(() => loaded = true); },
        onAdFailedToLoad: (ad, error) { ad.dispose(); if (mounted) setState(() { loaded = false; this.ad = null; }); },
      ),
    )..load();
  }

  @override
  void dispose() {
    ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!loaded || ad == null) return const SizedBox.shrink();
    return SizedBox(width: ad!.size.width.toDouble(), height: ad!.size.height.toDouble(), child: AdWidget(ad: ad!));
  }
}
