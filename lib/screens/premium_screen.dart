
import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../services/premium_service.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  bool loading = true;

  String note = '';

  List<dynamic> products = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  // Load premium products
  Future<void> load() async {
    try {
      final response = await PremiumService.instance.loadProducts();

      products = response.productDetails;

      note = response.error?.message ??
          (response.notFoundIDs.isNotEmpty
              ? 'Products not configured in Play Console: ${response.notFoundIDs.join(', ')}'
              : '');
    } catch (e) {
      note = 'Store setup required: $e';
    }

    if (mounted) {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PaperScan Pro'),
      ),

      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Premium header card
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF3868F5),
                  Color(0xFF6A8BFF),
                ],
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.workspace_premium,
                  size: 36,
                  color: Colors.white,
                ),

                SizedBox(height: 12),

                Text(
                  'PaperScan Pro',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                SizedBox(height: 6),

                Text(
                  'Unlock your document productivity toolkit.',
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Premium features
          ...[
            'PDF annotation & signatures',
            'Merge and split documents',
            'Compress PDFs',
            'OCR text extraction',
            'PDF conversions',
            'Password protection',
            'Ad-free experience',
          ].map(
            (s) => ListTile(
              leading: const Icon(
                Icons.check_circle,
                color: AppTheme.blue,
              ),
              title: Text(s),
            ),
          ),

          const SizedBox(height: 10),

          // Loading and product status
          if (loading)
            const Center(
              child: CircularProgressIndicator(),
            )
          else if (products.isEmpty)
            Text(
              note.isEmpty
                  ? 'In-app purchase products will appear once configured in Google Play Console.'
                  : note,
              style: Theme.of(context).textTheme.bodySmall,
            ),

          // Available purchase products
          ...products.map(
            (p) => Card(
              child: ListTile(
                title: Text(p.title),
                subtitle: Text(p.price),
                trailing: FilledButton(
                  onPressed: () => PremiumService.instance.buy(p),
                  child: const Text('Buy'),
                ),
              ),
            ),
          ),

          // Restore purchases
          OutlinedButton(
            onPressed: () => PremiumService.instance.restore(),
            child: const Text('Restore purchases'),
          ),

          const SizedBox(height: 10),

          // Pricing information
          const Text(
            'Launch prices proposed: \$3.99 monthly, \$19.99 yearly, \$39.99 lifetime. Configure these products and billing terms in Play Console before release.',
            style: TextStyle(
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
