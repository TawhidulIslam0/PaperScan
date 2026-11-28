import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Play Billing client-side wiring. Server-side receipt verification is required
/// before this local entitlement flag should be trusted for a public release.
class PremiumService {
  static final instance = PremiumService._();
  PremiumService._();

  final InAppPurchase _iap = InAppPurchase.instance;
  static const monthly = 'paperscan_pro_monthly';
  static const yearly = 'paperscan_pro_yearly';
  static const lifetime = 'paperscan_pro_lifetime';
  static const _entitlementKey = 'paperscan_pro_local_entitlement_v1';

  Future<bool> get storeAvailable => _iap.isAvailable();
  Stream<List<PurchaseDetails>> get purchaseStream => _iap.purchaseStream;
  Future<ProductDetailsResponse> loadProducts() => _iap.queryProductDetails({monthly, yearly, lifetime});
  Future<void> buy(ProductDetails product) async {
    await _iap.buyNonConsumable(purchaseParam: PurchaseParam(productDetails: product));
  }
  Future<void> restore() => _iap.restorePurchases();

  Future<bool> get hasLocalPro async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_entitlementKey) ?? false;
  }

  Future<void> setLocalPro(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_entitlementKey, value);
  }

  Future<void> processPurchaseUpdates(List<PurchaseDetails> updates) async {
    for (final purchase in updates) {
      if (purchase.status == PurchaseStatus.purchased || purchase.status == PurchaseStatus.restored) {
        // Local-only unlock: do not treat this as secure proof of entitlement.
        await setLocalPro(true);
      }
      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }
    }
  }
}
