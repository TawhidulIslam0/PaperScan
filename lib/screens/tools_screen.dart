import 'package:flutter/material.dart';
import 'premium_screen.dart';
import 'pdf_tools_workbench.dart';
import '../models/document_item.dart';

class ToolsScreen extends StatelessWidget {
  final VoidCallback onScan;
  final VoidCallback onImport;
  final ValueChanged<DocumentItem>? onDocumentCreated;
  const ToolsScreen({super.key, required this.onScan, required this.onImport, this.onDocumentCreated});

  @override
  Widget build(BuildContext context) {
    final tools = [
      ('Merge PDFs', Icons.merge_type, 'Combine multiple PDF files'),
      ('Split & extract pages', Icons.call_split, 'Save page ranges as separate PDFs'),
      ('Optimize PDF', Icons.compress, 'Rewrite PDF structure for optimization'),
      ('PDF to Word', Icons.description_outlined, 'Export selectable text to DOCX'),
      ('OCR text', Icons.text_snippet_outlined, 'Recognize text from photos'),
      ('Text, signature & watermark', Icons.draw_outlined, 'Add text or typed signature overlays'),
      ('Password tools', Icons.lock_outline, 'Encrypt or unlock with a password'),
      ('Rotate pages', Icons.rotate_90_degrees_ccw, 'Rotate all pages'),
    ];
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
      children: [
        Text('PDF tools', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        const Text('Free unlimited scanning. Advanced processing tools are available in the workbench.'),
        const SizedBox(height: 16),
        Card(child: ListTile(leading: const Icon(Icons.camera_alt, color: Color(0xFF3868F5)), title: const Text('Scan a document'), subtitle: const Text('Create a multi-page PDF'), trailing: const Icon(Icons.chevron_right), onTap: onScan)),
        Card(child: ListTile(leading: const Icon(Icons.file_open, color: Color(0xFF3868F5)), title: const Text('Import PDF'), subtitle: const Text('Add an existing PDF to your library'), trailing: const Icon(Icons.chevron_right), onTap: onImport)),
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            leading: Container(width: 44, height: 44, decoration: BoxDecoration(color: const Color(0xFF3868F5).withValues(alpha: .12), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.build_circle_outlined, color: Color(0xFF3868F5))),
            title: const Text('Open PDF Workbench', style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text('Launch the implemented PDF processing tools'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PdfToolsWorkbench(onDocumentCreated: onDocumentCreated ?? (_) {}))),
          ),
        ),
        const SizedBox(height: 8),
        ...tools.map((t) => Card(child: ListTile(leading: Icon(t.$2, color: const Color(0xFF3868F5)), title: Text(t.$1), subtitle: Text(t.$3), trailing: const Icon(Icons.chevron_right), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PdfToolsWorkbench(onDocumentCreated: onDocumentCreated ?? (_) {})))))),
        const SizedBox(height: 16),
        Card(child: ListTile(leading: const Icon(Icons.workspace_premium_outlined), title: const Text('PaperScan Pro'), subtitle: const Text('Subscription and lifetime plans'), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PremiumScreen())))),
        const SizedBox(height: 12),
        const Text('Some conversion workflows preserve extracted text rather than reconstructing the original document layout. OCR is currently image/photo based. Compression may not shrink every file.', style: TextStyle(fontSize: 12)),
      ],
    );
  }
}
