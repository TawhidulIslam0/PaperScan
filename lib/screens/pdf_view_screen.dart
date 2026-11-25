// ignore_for_file: unused_import

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:share_plus/share_plus.dart';

import '../models/document_item.dart';
import 'tools_screen.dart';

class PdfViewScreen extends StatelessWidget {
  final DocumentItem document;
  final VoidCallback onChanged;

  const PdfViewScreen({
    super.key,
    required this.document,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          document.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),

        actions: [
          IconButton(
            onPressed: () => Share.shareXFiles(
              [XFile(document.pdfPath)],
              text: document.title,
            ),
            icon: const Icon(Icons.share),
          ),

          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'tools') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ToolsScreen(
                      onScan: () => Navigator.pop(context),
                      onImport: () => Navigator.pop(context),
                    ),
                  ),
                );
              }
            },

            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'tools',
                child: Text('PDF tools'),
              ),
            ],
          ),
        ],
      ),

      body: PdfViewer.file(
        document.pdfPath,
        params: const PdfViewerParams(
          enableTextSelection: true,
          margin: 8,
        ),
      ),
    );
  }
}