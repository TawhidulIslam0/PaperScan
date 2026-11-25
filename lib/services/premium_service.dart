
import 'package:in_app_purchase/in_app_purchase.dart';

/// Store products must be created in Google Play Console
/// before purchase flows can succeed.

class PremiumService {
  static final instance = PremiumService._();

  PremiumService._();

  final _iap = InAppPurchase.instance;

  // Product IDs
  static const monthly = 'paperscan_pro_monthly';

  static const yearly = 'paperscan_pro_yearly';

  static const lifetime = 'paperscan_pro_lifetime';

  // Check store availability
  Future<bool> get storeAvailable {
    return _iap.isAvailable();
  }

  // Load available products
  Future<ProductDetailsResponse> loadProducts() {
    return _iap.queryProductDetails({
      monthly,
      yearly,
      lifetime,
    });
  }

  // Purchase product
  Future<void> buy(ProductDetails product) {
    return _iap.buyNonConsumable(
      purchaseParam: PurchaseParam(
        productDetails: product,
      ),
    );
  }

  // Purchase updates stream
  Stream<List<PurchaseDetails>> get purchaseStream {
    return _iap.purchaseStream;
  }

  // Restore previous purchases
  Future<void> restore() {
    return _iap.restorePurchases();
  }
}
