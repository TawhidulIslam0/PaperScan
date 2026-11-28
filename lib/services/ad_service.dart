import 'package:google_mobile_ads/google_mobile_ads.dart';

/// AdMob development integration. Uses Google's test IDs until real app/ad IDs
/// and a consent flow are configured for release.
class AdService {
  AdService._();
  static final instance = AdService._();
  Future<void> initialize() async {
    await MobileAds.instance.initialize();
  }

  static const bannerTestId = 'ca-app-pub-3940256099942544/6300978111';
}
