import 'package:flutter/material.dart';

import 'premium_screen.dart';

class ToolsScreen extends StatelessWidget {
  final VoidCallback onScan;
  final VoidCallback onImport;

  const ToolsScreen({
    super.key,
    required this.onScan,
    required this.onImport,
  });

  @override
  Widget build(BuildContext context) {
    final tools = [
      (
        'Merge PDFs',
        Icons.merge_type,
        'Combine multiple PDFs into one file',
      ),
      (
        'Split PDF',
        Icons.call_split,
        'Save selected pages separately',
      ),
      (
        'Compress',
        Icons.compress,
        'Reduce PDF file size',
      ),
      (
        'Convert to Word',
        Icons.description_outlined,
        'Convert PDF text to editable DOCX',
      ),
      (
        'OCR text',
        Icons.text_snippet_outlined,
        'Recognize text from scanned pages',
      ),
      (
        'Sign & annotate',
        Icons.draw_outlined,
        'Sign, mark up and highlight PDFs',
      ),
      (
        'Protect PDF',
        Icons.lock_outline,
        'Add password protection',
      ),
      (
        'Extract pages',
        Icons.content_cut,
        'Export selected pages',
      ),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
      children: [
        // Screen heading
        Text(
          'PDF tools',
          style: Theme.of(context)
              .textTheme
              .headlineMedium
              ?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),

        const SizedBox(height: 6),

        const Text(
          'Your scanner is free and unlimited. Pro tools unlock advanced document workflows.',
        ),

        const SizedBox(height: 16),

        // Scan document
        Card(
          child: ListTile(
            leading: const Icon(
              Icons.camera_alt,
              color: Color(0xFF3868F5),
            ),
            title: const Text('Scan a document'),
            subtitle: const Text('Create a multi-page PDF'),
            trailing: const Icon(Icons.chevron_right),
            onTap: onScan,
          ),
        ),

        // Import PDF
        Card(
          child: ListTile(
            leading: const Icon(
              Icons.file_open,
              color: Color(0xFF3868F5),
            ),
            title: const Text('Import PDF'),
            subtitle: const Text(
              'Bring an existing PDF into your library',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: onImport,
          ),
        ),

        const SizedBox(height: 8),

        // Premium tools
        ...tools.map(
          (t) => Card(
            child: ListTile(
              leading: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFF3868F5)
                      .withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  t.$2,
                  color: const Color(0xFF3868F5),
                ),
              ),

              title: Text(t.$1),

              subtitle: Text(t.$3),

              trailing: const Icon(
                Icons.lock_outline,
                size: 18,
              ),

              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PremiumScreen(),
                  ),
                );
              },
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Information
        Text(
          'Advanced tools are shown as planned premium features. They are not enabled until their processing implementation is added.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}