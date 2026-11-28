import 'dart:async';

import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../core/theme.dart';
import '../services/premium_service.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});
  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  bool loading = true;
  bool restoring = false;
  bool hasPro = false;
  String note = '';
  List<ProductDetails> products = [];
  StreamSubscription<List<PurchaseDetails>>? purchaseSubscription;

  @override
  void initState() {
    super.initState();
    load();
    purchaseSubscription = PremiumService.instance.purchaseStream.listen(
      _handlePurchases,
      onError: (Object error) {
        if (mounted) setState(() => note = 'Purchase stream error: $error');
      },
    );
  }

  Future<void> load() async {
    try {
      hasPro = await PremiumService.instance.hasLocalPro;
      final available = await PremiumService.instance.storeAvailable;
      if (!available) {
        note = 'Google Play Billing is not available on this device. Use a Play Store test build to test purchases.';
      } else {
        final response = await PremiumService.instance.loadProducts();
        products = response.productDetails;
        note = response.error?.message ?? (response.notFoundIDs.isNotEmpty ? 'Create these product IDs in Play Console: ${response.notFoundIDs.join(', ')}' : '');
      }
    } catch (e) {
      note = 'Store configuration required: $e';
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> _handlePurchases(List<PurchaseDetails> purchases) async {
    await PremiumService.instance.processPurchaseUpdates(purchases);
    final purchased = purchases.any((p) => p.status == PurchaseStatus.purchased || p.status == PurchaseStatus.restored);
    final failed = purchases.where((p) => p.status == PurchaseStatus.error).toList();
    final pending = purchases.any((p) => p.status == PurchaseStatus.pending);
    if (!mounted) return;
    setState(() {
      hasPro = purchased || hasPro;
      restoring = false;
      if (purchased) note = 'Purchase/restore received. This starter stores a local entitlement; server verification is not yet configured.';
      if (failed.isNotEmpty) note = failed.first.error?.message ?? 'Purchase did not complete.';
      if (pending) note = 'Purchase pending. Wait for Google Play to finish processing.';
    });
  }

  Future<void> buy(ProductDetails product) async {
    try {
      await PremiumService.instance.buy(product);
      if (mounted) setState(() => note = 'Purchase request sent to Google Play.');
    } catch (e) {
      if (mounted) setState(() => note = 'Could not start purchase: $e');
    }
  }

  Future<void> restore() async {
    setState(() => restoring = true);
    try {
      await PremiumService.instance.restore();
      if (mounted) setState(() => note = 'Restore request sent. Google Play will return eligible purchases.');
    } catch (e) {
      if (mounted) setState(() { restoring = false; note = 'Restore failed: $e'; });
    }
  }

  @override
  void dispose() {
    purchaseSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PaperScan Pro')),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), gradient: const LinearGradient(colors: [Color(0xFF3868F5), Color(0xFF6A8BFF)])),
          child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.workspace_premium, size: 36, color: Colors.white),
            SizedBox(height: 12),
            Text('PaperScan Pro', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
            SizedBox(height: 6),
            Text('Advanced tools for your documents.', style: TextStyle(color: Colors.white)),
          ]),
        ),
        const SizedBox(height: 18),
        ...['Merge and split PDFs', 'PDF optimization', 'OCR text extraction from images', 'PDF text to DOCX / TXT export', 'Add text, watermarks and typed signatures', 'Password protection and unlock', 'Rotate pages'].map((feature) => ListTile(leading: const Icon(Icons.check_circle, color: AppTheme.blue), title: Text(feature))),
        const SizedBox(height: 10),
        if (hasPro) Card(color: Theme.of(context).colorScheme.primaryContainer, child: const ListTile(leading: Icon(Icons.verified), title: Text('Pro purchase detected locally'), subtitle: Text('Local entitlement only; verify purchases on a server before release.'))),
        if (loading) const Center(child: CircularProgressIndicator())
        else if (products.isEmpty) Text(note.isEmpty ? 'Products will appear after they are configured and available through Google Play.' : note, style: Theme.of(context).textTheme.bodySmall)
        else ...products.map((product) => Card(child: ListTile(title: Text(product.title), subtitle: Text('${product.price}\n${product.description}', maxLines: 3), isThreeLine: true, trailing: FilledButton(onPressed: () => buy(product), child: const Text('Buy'))))),
        OutlinedButton.icon(onPressed: restoring ? null : restore, icon: restoring ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.restore), label: Text(restoring ? 'Restoring…' : 'Restore purchases')),
        if (note.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 12), child: Text(note, style: Theme.of(context).textTheme.bodySmall)),
        const SizedBox(height: 12),
       const Text(
  'Suggested launch prices: \$3.99 monthly, \$19.99 yearly and \$39.99 lifetime. Configure products and pricing in Play Console. Billing currently uses client-side purchase state only; it does not include receipt validation, account-based entitlement sync, or subscription expiry checks.',
  style: TextStyle(fontSize: 12),
)
      ]),
    );
  }
}
