import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/pdf_tools_service.dart';
import '../models/document_item.dart';

class PdfToolsWorkbench extends StatefulWidget {
  final ValueChanged<DocumentItem> onDocumentCreated;
  const PdfToolsWorkbench({super.key, required this.onDocumentCreated});

  @override
  State<PdfToolsWorkbench> createState() => _PdfToolsWorkbenchState();
}

class _PdfToolsWorkbenchState extends State<PdfToolsWorkbench> {
  bool working = false;
  final ImagePicker _imagePicker = ImagePicker();

  Future<void> _run(String label, Future<void> Function() task) async {
    if (working) return;
    setState(() => working = true);
    try {
      await task();
    } catch (e) {
      if (mounted) _message('$label failed: $e');
    } finally {
      if (mounted) setState(() => working = false);
    }
  }

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<String?> _pickOne() async {
    final paths = await PdfToolsService.pickPdfPaths();
    return paths.isEmpty ? null : paths.first;
  }

  Future<void> _created(DocumentItem doc) async {
    widget.onDocumentCreated(doc);
    if (mounted) _message('Saved to your PaperScan library: ${doc.title}');
  }

  Future<void> _merge() => _run('Merge PDFs', () async {
        final paths = await PdfToolsService.pickPdfPaths(multiple: true);
        if (paths.length < 2) {
          _message('Select two or more PDF files.');
          return;
        }
        await _created(await PdfToolsService.merge(paths));
      });

  Future<void> _split({bool extract = false}) => _run(extract ? 'Extract pages' : 'Split PDF', () async {
        final path = await _pickOne();
        if (path == null) return;
        final start = TextEditingController(text: '1');
        final end = TextEditingController(text: '1');
        final range = await showDialog<List<int>>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(extract ? 'Extract page range' : 'Split PDF'),
            content: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: start, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Start page (1-based)')),
              TextField(controller: end, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'End page (1-based)')),
            ]),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              FilledButton(onPressed: () {
                final a = int.tryParse(start.text);
                final b = int.tryParse(end.text);
                if (a != null && b != null && a > 0 && b >= a) Navigator.pop(ctx, [a, b]);
              }, child: const Text('Create PDF')),
            ],
          ),
        );
        start.dispose();
        end.dispose();
        if (range == null) return;
        await _created(await PdfToolsService.split(path, range[0], range[1]));
      });

  Future<void> _reorderPages() => _run('Reorder/delete pages', () async {
        final path = await _pickOne();
        if (path == null) return;
        final controller = TextEditingController();
        final order = await showDialog<String>(context: context, builder: (ctx) => AlertDialog(
          title: const Text('Reorder or remove pages'),
          content: TextField(controller: controller, autofocus: true, decoration: const InputDecoration(labelText: 'Page order', hintText: 'Example: 3,1,2'), maxLines: 2),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: const Text('Save order'))],
        ));
        controller.dispose();
        if (order == null || order.isEmpty) return;
        final pages = order.split(',').map((e) => int.tryParse(e.trim())).toList();
        if (pages.any((p) => p == null || p <= 0)) {
          _message('Use comma-separated positive page numbers, for example 3,1,2.');
          return;
        }
        await _created(await PdfToolsService.reorderPages(path, pages.cast<int>()));
      });

  Future<void> _compress() => _run('Optimize PDF', () async {
        final path = await _pickOne();
        if (path != null) await _created(await PdfToolsService.compress(path));
      });

  Future<void> _textExport({bool word = false}) => _run(word ? 'Convert to Word' : 'Extract text', () async {
        final path = await _pickOne();
        if (path == null) return;
        final file = word ? await PdfToolsService.exportWord(path) : await PdfToolsService.exportText(path);
        await PdfToolsService.shareFile(file, text: word ? 'Editable Word document (text-only conversion)' : 'Extracted PDF text');
      });

  Future<void> _csvExport() => _run('PDF to CSV', () async {
        final path = await _pickOne();
        if (path == null) return;
        final file = await PdfToolsService.exportCsv(path);
        await PdfToolsService.shareFile(file, text: 'Spreadsheet-compatible CSV export (one extracted text line per row)');
      });

  Future<void> _pdfToImages() => _run('PDF to images', () async {
        final path = await _pickOne();
        if (path == null) return;
        final images = await PdfToolsService.exportPdfImages(path);
        if (images.isEmpty) {
          _message('No pages could be exported.');
          return;
        }
        await PdfToolsService.shareFiles(images, text: 'PDF page images');
      });

  Future<void> _ocr() => _run('OCR', () async {
        final images = await _imagePicker.pickMultiImage(imageQuality: 95);
        if (images.isEmpty) return;
        final file = await PdfToolsService.ocrImages(images.map((e) => e.path).toList());
        await PdfToolsService.shareFile(file, text: 'OCR text extracted from selected images');
      });

  Future<void> _overlay({bool watermark = false, bool signature = false}) => _run(watermark ? 'Watermark' : signature ? 'Signature' : 'Add text', () async {
        final path = await _pickOne();
        if (path == null) return;
        final controller = TextEditingController();
        final input = await showDialog<String>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(watermark ? 'Watermark text' : signature ? 'Type your signature' : 'Text to add'),
            content: TextField(controller: controller, autofocus: true, maxLines: 3, decoration: const InputDecoration(hintText: 'Enter text here')),
            actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: const Text('Apply'))],
          ),
        );
        controller.dispose();
        if (input == null || input.trim().isEmpty) return;
        final doc = await PdfToolsService.addTextOverlay(path, input, watermark: watermark || signature);
        await _created(doc);
      });

  Future<void> _protect({bool unlock = false}) => _run(unlock ? 'Unlock PDF' : 'Password protect', () async {
        final path = await _pickOne();
        if (path == null) return;
        final controller = TextEditingController();
        final password = await showDialog<String>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(unlock ? 'Current PDF password' : 'Set PDF password'),
            content: TextField(controller: controller, obscureText: true, autofocus: true, decoration: const InputDecoration(labelText: 'Password')),
            actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(ctx, controller.text), child: const Text('Continue'))],
          ),
        );
        controller.dispose();
        if (password == null || password.isEmpty) return;
        await _created(unlock ? await PdfToolsService.unlock(path, password) : await PdfToolsService.protect(path, password));
      });

  Future<void> _highlight() => _run('Highlight text', () async {
        final path = await _pickOne();
        if (path == null) return;
        final controller = TextEditingController();
        final term = await showDialog<String>(context: context, builder: (ctx) => AlertDialog(
          title: const Text('Highlight text'),
          content: TextField(controller: controller, autofocus: true, decoration: const InputDecoration(labelText: 'Text to find')),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: const Text('Highlight'))],
        ));
        controller.dispose();
        if (term != null && term.isNotEmpty) await _created(await PdfToolsService.highlightSearchText(path, term));
      });

  Future<void> _fillForm() => _run('Fill PDF form', () async {
        final path = await _pickOne();
        if (path == null) return;
        final names = await PdfToolsService.textFieldNames(path);
        if (names.isEmpty) {
          _message('No editable text fields found in this PDF.');
          return;
        }
        final controllers = <String, TextEditingController>{for (final name in names) name: TextEditingController()};
        final values = await showDialog<Map<String, String>>(context: context, builder: (ctx) => AlertDialog(
          title: const Text('Fill form fields'),
          content: SizedBox(width: 400, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: names.map((name) => Padding(padding: const EdgeInsets.only(bottom: 10), child: TextField(controller: controllers[name], decoration: InputDecoration(labelText: name)))).toList()))),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(ctx, {for (final name in names) name: controllers[name]!.text}), child: const Text('Save form'))],
        ));
        for (final c in controllers.values) { c.dispose(); }
        if (values != null) await _created(await PdfToolsService.fillTextFields(path, values));
      });

  Future<void> _rotate() => _run('Rotate PDF', () async {
        final path = await _pickOne();
        if (path == null) return;
        final degree = await showModalBottomSheet<int>(context: context, builder: (ctx) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(title: const Text('Rotate 90° clockwise'), onTap: () => Navigator.pop(ctx, 90)),
          ListTile(title: const Text('Rotate 180°'), onTap: () => Navigator.pop(ctx, 180)),
          ListTile(title: const Text('Rotate 270° clockwise'), onTap: () => Navigator.pop(ctx, 270)),
        ])));
        if (degree != null) await _created(await PdfToolsService.rotate(path, degree));
      });

  @override
  Widget build(BuildContext context) {
    final tools = <_ToolItem>[
      _ToolItem('Merge PDFs', 'Combine files into one PDF', Icons.merge_type_rounded, _merge),
      _ToolItem('Split PDF', 'Save a selected page range', Icons.call_split_rounded, () => _split()),
      _ToolItem('Reorder / delete pages', 'Specify a page order; omit pages to remove them', Icons.swap_vert_rounded, _reorderPages),
      _ToolItem('Extract pages', 'Create a PDF from selected pages', Icons.content_cut_rounded, () => _split(extract: true)),
      _ToolItem('Optimize / compress', 'Rewrite and optimize PDF structure', Icons.compress_rounded, _compress),
      _ToolItem('PDF to Word', 'Export selectable PDF text to DOCX', Icons.description_outlined, () => _textExport(word: true)),
      _ToolItem('PDF to spreadsheet CSV', 'Export text lines to spreadsheet-compatible CSV', Icons.table_chart_outlined, _csvExport),
      _ToolItem('PDF to images', 'Export each page as a PNG image', Icons.image_outlined, _pdfToImages),
      _ToolItem('Extract text', 'Save embedded text as TXT', Icons.text_snippet_outlined, _textExport),
      _ToolItem('OCR images', 'Recognize text in photos offline', Icons.document_scanner_outlined, _ocr),
      _ToolItem('Add text', 'Place text on every PDF page', Icons.text_fields_rounded, _overlay),
      _ToolItem('Highlight matching text', 'Highlight selectable text matches', Icons.highlight_rounded, _highlight),
      _ToolItem('Fill PDF form', 'Fill existing text form fields', Icons.edit_note, _fillForm),
      _ToolItem('Typed signature', 'Place a typed signature on pages', Icons.draw_outlined, () => _overlay(signature: true)),
      _ToolItem('Watermark', 'Add a centered watermark', Icons.branding_watermark_rounded, () => _overlay(watermark: true)),
      _ToolItem('Password protect', 'Encrypt with an AES password', Icons.lock_outline_rounded, _protect),
      _ToolItem('Remove password', 'Unlock a PDF with its password', Icons.lock_open_rounded, () => _protect(unlock: true)),
      _ToolItem('Rotate pages', 'Rotate all pages in a PDF', Icons.rotate_90_degrees_ccw_rounded, _rotate),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('PDF Workbench')),
      body: Stack(children: [
        ListView(padding: const EdgeInsets.fromLTRB(18, 12, 18, 30), children: [
          Card(color: Theme.of(context).colorScheme.primaryContainer, child: const Padding(padding: EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Tools that work on-device', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
            SizedBox(height: 6), Text('Processing is local. Select files when you start each tool; results are saved in your library or shared as exports.'),
          ]))),
          const SizedBox(height: 12),
          ...tools.map((t) => Card(child: ListTile(
            leading: Container(width: 44, height: 44, decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withValues(alpha: .10), borderRadius: BorderRadius.circular(12)), child: Icon(t.icon, color: Theme.of(context).colorScheme.primary)),
            title: Text(t.title), subtitle: Text(t.subtitle), trailing: const Icon(Icons.chevron_right), onTap: working ? null : t.action,
          ))),
          const SizedBox(height: 12),
          const Text('Limitations: PDF-to-Word and CSV export extractable text only (they do not reconstruct table layout or embedded images). OCR is currently for selected photos/images. Compression rewrites and optimizes PDF structure, but may not reduce every PDF size. Typed signature is not a certificate-backed digital signature.', style: TextStyle(fontSize: 12)),
        ]),
        if (working) Container(color: Colors.black.withValues(alpha: .16), child: const Center(child: Card(child: Padding(padding: EdgeInsets.all(22), child: Column(mainAxisSize: MainAxisSize.min, children: [CircularProgressIndicator(), SizedBox(height: 12), Text('Working on your document…')]))))),
      ]),
    );
  }
}

class _ToolItem {
  final String title, subtitle;
  final IconData icon;
  final Future<void> Function() action;
  _ToolItem(this.title, this.subtitle, this.icon, this.action);
}
