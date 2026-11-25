
import 'dart:io';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:image/image.dart' as img;
import 'package:uuid/uuid.dart';

import '../models/document_item.dart';
import 'document_store.dart';

class PdfService {
  // Create PDF from images
  static Future<DocumentItem> createFromImages(
    List<String> paths, {
    String? title,
  }) async {
    if (paths.isEmpty) {
      throw Exception('No images selected.');
    }

    final pdf = pw.Document();

    int pageCount = 0;

    for (final path in paths) {
      final file = File(path);

      if (!await file.exists()) {
        continue;
      }

      final bytes = await file.readAsBytes();

      final decoded = img.decodeImage(bytes);

      if (decoded == null) {
        continue;
      }

      // Fix image orientation
      final fixed = img.bakeOrientation(decoded);

      // Convert image to JPEG
      final jpg = img.encodeJpg(
        fixed,
        quality: 92,
      );

      final image = pw.MemoryImage(jpg);

      // Add image as a PDF page
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(0),
          build: (ctx) {
            return pw.Center(
              child: pw.Image(
                image,
                fit: pw.BoxFit.contain,
              ),
            );
          },
        ),
      );

      pageCount++;
    }

    // Check if any valid pages were created
    if (pageCount == 0) {
      throw Exception('No usable scan images found.');
    }

    // Generate PDF bytes
    final bytes = await pdf.save();

    // Generate unique document ID
    final id = const Uuid().v4();

    // Generate document title
    final name = title?.trim().isNotEmpty == true
        ? title!.trim()
        : 'Scan ${DateTime.now().toLocal().toString().substring(0, 16)}';

    // Get document directory
    final directory = DocumentStore.instance.docsDir;

    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    // Create PDF file
    final file = File(
      '${directory.path}/$id.pdf',
    );

    await file.writeAsBytes(
      bytes,
      flush: true,
    );

    // Create document item
    final item = DocumentItem(
      id: id,
      title: name,
      pdfPath: file.path,
      createdAt: DateTime.now(),
      pageCount: pageCount,
    );

    // Save document to storage
    await DocumentStore.instance.save(item);

    return item;
  }

  // Import existing PDF
  static Future<DocumentItem> importPdf(
    String source, {
    String? title,
  }) async {
    final src = File(source);

    // Check source file
    if (!await src.exists()) {
      throw Exception('Selected file was not found.');
    }

    if (await src.length() == 0) {
      throw Exception('Selected PDF is empty.');
    }

    // Get document directory
    final directory = DocumentStore.instance.docsDir;

    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    // Generate unique document ID
    final id = const Uuid().v4();

    // Create destination file
    final dest = File(
      '${directory.path}/$id.pdf',
    );

    await src.copy(dest.path);

    // Get original filename
    final originalName = src.uri.pathSegments.last;

    final name = title?.trim().isNotEmpty == true
        ? title!.trim()
        : originalName.replaceAll(
            RegExp(
              r'\.pdf$',
              caseSensitive: false,
            ),
            '',
          );

    // Create document item
    final item = DocumentItem(
      id: id,
      title: name,
      pdfPath: dest.path,
      createdAt: DateTime.now(),
      pageCount: 1,
    );

    // Save document to storage
    await DocumentStore.instance.save(item);

    return item;
  }
}
