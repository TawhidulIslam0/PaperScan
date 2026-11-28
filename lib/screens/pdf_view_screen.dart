import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:share_plus/share_plus.dart';

import '../models/document_item.dart';
import 'pdf_tools_workbench.dart';

class PdfViewScreen extends StatelessWidget {
  final DocumentItem document;
  final VoidCallback onChanged;
  const PdfViewScreen({super.key, required this.document, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(document.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(onPressed: () => Share.shareXFiles([XFile(document.pdfPath)], text: document.title), icon: const Icon(Icons.share)),
          IconButton(
            tooltip: 'PDF tools',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PdfToolsWorkbench(onDocumentCreated: (_) => onChanged()))),
            icon: const Icon(Icons.build_circle_outlined),
          ),
        ],
      ),
      body: PdfViewer.file(document.pdfPath, params: const PdfViewerParams(enableTextSelection: true, margin: 8)),
    );
  }
}
