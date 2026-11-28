import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../core/theme.dart';
import '../models/document_item.dart';
import '../services/document_store.dart';
import '../services/pdf_service.dart';
import '../services/scanner_service.dart';
import '../widgets/library_banner_ad.dart';
import 'pdf_view_screen.dart';
import 'tools_screen.dart';
import 'premium_screen.dart';

class HomeScreen extends StatefulWidget {
  final ValueChanged<bool> onThemeChanged;
  final bool darkMode;
  const HomeScreen({super.key, required this.onThemeChanged, required this.darkMode});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int tab = 0;
  String search = '';
  bool busy = false;
  final picker = ImagePicker();

  List<DocumentItem> get filtered => DocumentStore.instance.all.where((d) => d.title.toLowerCase().contains(search.toLowerCase())).toList();

  Future<void> scan() async {
    if (busy) return;
    setState(() => busy = true);
    try {
      final images = await ScannerService.scan();
      if (images.isNotEmpty) {
        final doc = await PdfService.createFromImages(images);
        if (mounted) openDoc(doc);
      }
    } catch (e) {
      if (mounted) msg('Scanner error: $e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> importPhotos() async {
    if (busy) return;
    try {
      final selected = await picker.pickMultiImage(imageQuality: 92);
      if (selected.isNotEmpty) {
        if (mounted) setState(() => busy = true);
        final d = await PdfService.createFromImages(
          selected.map((x) => x.path).toList(),
          title: 'Imported ${DateFormat('MMM d, yyyy').format(DateTime.now())}',
        );
        if (mounted) openDoc(d);
      }
    } catch (e) {
      if (mounted) msg('$e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> importPdf() async {
    try {
      final f = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
      if (f == null || f.files.isEmpty || f.files.single.path == null) return;
      await PdfService.importPdf(f.files.single.path!);
      if (mounted) {
        refresh();
        msg('PDF added to library');
      }
    } catch (e) {
      if (mounted) msg('Import failed: $e');
    }
  }

  void refresh() {
    if (mounted) setState(() {});
  }

  void msg(String s) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));
  }

  void openDoc(DocumentItem d) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => PdfViewScreen(document: d, onChanged: refresh)));
  }

  Future<void> rename(DocumentItem d) async {
    final c = TextEditingController(text: d.title);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename document'),
        content: TextField(controller: c, autofocus: true, decoration: const InputDecoration(labelText: 'Document name')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
        ],
      ),
    );
    if (ok == true && c.text.trim().isNotEmpty) {
      await DocumentStore.instance.rename(d, c.text.trim());
      refresh();
    }
    c.dispose();
  }

  Future<void> remove(DocumentItem d) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete document?'),
        content: Text('“${d.title}” will be deleted from this device.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true) {
      await DocumentStore.instance.delete(d);
      refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final docs = filtered;
    return Scaffold(
      body: SafeArea(
        child: tab == 0
            ? home(docs)
            : tab == 1
                ? ToolsScreen(onScan: scan, onImport: importPdf, onDocumentCreated: (doc) { refresh(); openDoc(doc); })
                : settings(),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          NavigationBar(
            selectedIndex: tab,
            onDestinationSelected: (i) => setState(() => tab = i),
            destinations: const [
              NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
              NavigationDestination(icon: Icon(Icons.grid_view_rounded), label: 'Tools'),
              NavigationDestination(icon: Icon(Icons.settings_outlined), label: 'Settings'),
            ],
          ),
          if (tab == 0) const LibraryBannerAd(),
        ],
      ),
      floatingActionButton: tab == 0
          ? FloatingActionButton.extended(
              onPressed: busy ? null : scan,
              icon: busy ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.document_scanner),
              label: Text(busy ? 'Scanning…' : 'Scan document'),
            )
          : null,
    );
  }

  Widget home(List<DocumentItem> docs) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 16, 22, 10),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('PaperScan', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 3),
                Text('Your pocket document scanner', style: Theme.of(context).textTheme.bodyMedium),
              ])),
              IconButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PremiumScreen())),
                icon: const Icon(Icons.workspace_premium_rounded, color: AppTheme.blue),
                tooltip: 'Go Pro',
              ),
            ]),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Ready to scan?', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 5),
              const Text('Scan paper documents into clean, shareable PDFs. Free scanning, no page limits.'),
              const SizedBox(height: 15),
              Row(children: [
                Expanded(child: FilledButton.icon(onPressed: busy ? null : scan, icon: const Icon(Icons.camera_alt_outlined), label: const Text('Scan now'))),
                const SizedBox(width: 10),
                Expanded(child: OutlinedButton.icon(onPressed: busy ? null : importPhotos, icon: const Icon(Icons.photo_library_outlined), label: const Text('Photos'))),
              ]),
            ]))),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(padding: const EdgeInsets.fromLTRB(20, 20, 20, 10), child: Row(children: [
            Expanded(child: Text('Your documents', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold))),
            Text('${docs.length} files', style: Theme.of(context).textTheme.bodySmall),
          ])),
        ),
        SliverToBoxAdapter(
          child: Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: TextField(
            onChanged: (v) => setState(() => search = v),
            decoration: const InputDecoration(hintText: 'Search documents', prefixIcon: Icon(Icons.search), contentPadding: EdgeInsets.symmetric(vertical: 12)),
          )),
        ),
        SliverToBoxAdapter(
          child: Padding(padding: const EdgeInsets.fromLTRB(20, 10, 20, 0), child: Row(children: [
            Expanded(child: OutlinedButton.icon(onPressed: importPdf, icon: const Icon(Icons.file_open_outlined), label: const Text('Import PDF'))),
            const SizedBox(width: 10),
            Expanded(child: OutlinedButton.icon(onPressed: busy ? null : importPhotos, icon: const Icon(Icons.image_outlined), label: const Text('Import images'))),
          ])),
        ),
        if (docs.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: Padding(padding: const EdgeInsets.all(30), child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.folder_open_outlined, size: 58, color: Theme.of(context).colorScheme.primary.withValues(alpha: .7)),
              const SizedBox(height: 12),
              Text(search.isEmpty ? 'No documents yet' : 'No matches', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              Text(search.isEmpty ? 'Your scanned and imported PDFs will show up here.' : 'Try a different search term.', textAlign: TextAlign.center),
            ]))),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            sliver: SliverList(delegate: SliverChildBuilderDelegate((ctx, i) {
              final d = docs[i];
              return Card(child: ListTile(
                leading: Container(width: 48, height: 56, decoration: BoxDecoration(color: AppTheme.blue.withValues(alpha: .1), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.picture_as_pdf, color: AppTheme.blue)),
                title: Text(d.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text('${d.pageCount} page${d.pageCount == 1 ? '' : 's'} • ${DateFormat('MMM d, yyyy').format(d.createdAt)}'),
                onTap: () => openDoc(d),
                trailing: PopupMenuButton<String>(
                  onSelected: (v) { if (v == 'rename') rename(d); if (v == 'delete') remove(d); },
                  itemBuilder: (_) => const [PopupMenuItem(value: 'rename', child: Text('Rename')), PopupMenuItem(value: 'delete', child: Text('Delete'))],
                ),
              ));
            }, childCount: docs.length)),
          ),
      ],
    );
  }

  Widget settings() => ListView(padding: const EdgeInsets.all(20), children: [
    Text('Settings', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
    const SizedBox(height: 16),
    Card(child: SwitchListTile(title: const Text('Dark mode'), subtitle: const Text('Use a dark appearance'), value: widget.darkMode, onChanged: widget.onThemeChanged)),
    Card(child: const ListTile(leading: Icon(Icons.shield_outlined), title: Text('Privacy'), subtitle: Text('Documents are processed and stored locally by default. PaperScan does not upload your PDFs to a server.'))),
    Card(child: const ListTile(leading: Icon(Icons.info_outline), title: Text('Advertisements'), subtitle: Text('Development build uses a Google test banner on the Home/library screen only. Real ad IDs and consent management must be configured before release.'))),
    Card(child: ListTile(leading: const Icon(Icons.workspace_premium_outlined), title: const Text('PaperScan Pro'), subtitle: const Text('Subscription and lifetime purchase options'), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PremiumScreen())))),
    Card(child: const ListTile(leading: Icon(Icons.info_outline), title: Text('About PaperScan'), subtitle: Text('Version 1.0.0 • Offline-first scanner'))),
  ]);
}
