import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;

import '../models/document_item.dart';
import 'document_store.dart';

/// On-device PDF processing. Inputs and outputs stay on the device.
class PdfToolsService {
  static Future<List<String>> pickPdfPaths({bool multiple = false}) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
      allowMultiple: multiple,
    );
    return (result?.files ?? [])
        .map((f) => f.path)
        .whereType<String>()
        .where((p) => p.isNotEmpty)
        .toList();
  }

  static Future<DocumentItem> merge(List<String> paths) async {
    if (paths.length < 2) throw Exception('Select at least two PDFs to merge.');
    final output = sf.PdfDocument();
    sf.PdfSection? section;
    final sourceDocs = <sf.PdfDocument>[];
    try {
      for (final path in paths) {
        final source = sf.PdfDocument(inputBytes: await File(path).readAsBytes());
        sourceDocs.add(source);
        for (var i = 0; i < source.pages.count; i++) {
          final template = source.pages[i].createTemplate();
          if (section == null || section.pageSettings.size != template.size) {
            section = output.sections!.add();
            section.pageSettings.size = template.size;
            section.pageSettings.margins.all = 0;
          }
          section.pages.add().graphics.drawPdfTemplate(template, const ui.Offset(0, 0));
        }
      }
      return await _saveGenerated(output, 'Merged PDF', 'Merged');
    } finally {
      for (final source in sourceDocs) {
        source.dispose();
      }
      output.dispose();
    }
  }

  static Future<DocumentItem> split(String path, int startPage, int endPage) async {
    final source = sf.PdfDocument(inputBytes: await File(path).readAsBytes());
    final output = sf.PdfDocument();
    try {
      final start = math.max(1, startPage).toInt();
      final end = math.min(source.pages.count, endPage).toInt();
      if (start > end || source.pages.count == 0) {
        throw Exception('Page range is invalid for this PDF.');
      }
      sf.PdfSection? section;
      for (var i = start - 1; i < end; i++) {
        final template = source.pages[i].createTemplate();
        if (section == null || section.pageSettings.size != template.size) {
          section = output.sections!.add();
          section.pageSettings.size = template.size;
          section.pageSettings.margins.all = 0;
        }
        section.pages.add().graphics.drawPdfTemplate(template, const ui.Offset(0, 0));
      }
      return await _saveGenerated(output, 'Extracted pages $start-$end', 'Extracted');
    } finally {
      source.dispose();
      output.dispose();
    }
  }

  static Future<DocumentItem> reorderPages(String path, List<int> order) async {
    final source = sf.PdfDocument(inputBytes: await File(path).readAsBytes());
    final output = sf.PdfDocument();
    try {
      if (order.isEmpty) throw Exception('Keep at least one page in the output.');
      for (final pageNumber in order) {
        if (pageNumber < 1 || pageNumber > source.pages.count) {
          throw Exception('Page $pageNumber is outside this PDF page range.');
        }
      }
      sf.PdfSection? section;
      for (final pageNumber in order) {
        final template = source.pages[pageNumber - 1].createTemplate();
        if (section == null || section.pageSettings.size != template.size) {
          section = output.sections!.add();
          section.pageSettings.size = template.size;
          section.pageSettings.margins.all = 0;
        }
        section.pages.add().graphics.drawPdfTemplate(template, const ui.Offset(0, 0));
      }
      return await _saveGenerated(output, 'Reordered pages', 'Reordered');
    } finally {
      source.dispose();
      output.dispose();
    }
  }

  static Future<DocumentItem> compress(String path) async {
    final doc = sf.PdfDocument(inputBytes: await File(path).readAsBytes());
    try {
      doc.fileStructure.incrementalUpdate = false;
      doc.compressionLevel = sf.PdfCompressionLevel.best;
      return await _saveGenerated(doc, 'Optimized PDF', 'Optimized');
    } finally {
      doc.dispose();
    }
  }

  static Future<String> extractText(String path) async {
    final doc = sf.PdfDocument(inputBytes: await File(path).readAsBytes());
    try {
      return sf.PdfTextExtractor(doc).extractText();
    } finally {
      doc.dispose();
    }
  }

  static Future<List<File>> exportPdfImages(String path) async {
    final bytes = await File(path).readAsBytes();
    final docsDir = await getApplicationDocumentsDirectory();
    final output = <File>[];
    var pageNumber = 0;

    await for (final page in Printing.raster(bytes, dpi: 144)) {
      pageNumber++;
      final rawImage = await page.toImage();
      final byteData = await rawImage.toByteData(format: ui.ImageByteFormat.rawRgba);
      rawImage.dispose();
      if (byteData == null) {
        throw Exception('Could not rasterize page $pageNumber.');
      }
      final decoded = img.Image.fromBytes(
        width: rawImage.width,
        height: rawImage.height,
        bytes: byteData.buffer,
        numChannels: 4,
      );
      final pngBytes = img.encodePng(decoded);
      final file = File(
        '${docsDir.path}/PaperScan_Page_${pageNumber}_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(pngBytes, flush: true);
      output.add(file);
    }

    return output;
  }

  static Future<File> exportCsv(String path) async {
    final text = await extractText(path);
    final rows = text.split(RegExp(r'\r?\n'));
    String csvCell(String value) => '"' + value.replaceAll('"', '""') + '"';
    final csv = rows.map(csvCell).join('\r\n');
    final file = File('${(await getApplicationDocumentsDirectory()).path}/PaperScan_${DateTime.now().millisecondsSinceEpoch}.csv');
    await file.writeAsString(csv, flush: true);
    return file;
  }

  static Future<File> exportText(String path) async {
    final text = await extractText(path);
    final file = File('${(await getApplicationDocumentsDirectory()).path}/PaperScan_${DateTime.now().millisecondsSinceEpoch}.txt');
    await file.writeAsString(text, flush: true);
    return file;
  }

  /// Creates a basic editable DOCX from the PDF's extractable text. Layout,
  /// tables, and images are not reconstructed; scanned PDFs need OCR first.
  static Future<File> exportWord(String path) async {
    final text = await extractText(path);
    final paragraphs = text.split(RegExp(r'\r?\n')).map((line) {
      final safe = _xml(line);
      return '<w:p><w:r><w:t xml:space="preserve">$safe</w:t></w:r></w:p>';
    }).join();
    final archive = Archive();
    void add(String name, String content) {
      final bytes = utf8.encode(content);
      archive.addFile(ArchiveFile(name, bytes.length, bytes));
    }
    add('[Content_Types].xml', '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"><Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/><Default Extension="xml" ContentType="application/xml"/><Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/></Types>''');
    add('_rels/.rels', '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/></Relationships>''');
    add('word/document.xml', '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?><w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"><w:body>$paragraphs<w:sectPr><w:pgSz w:w="12240" w:h="15840"/><w:pgMar w:top="1440" w:right="1440" w:bottom="1440" w:left="1440"/></w:sectPr></w:body></w:document>''');
    final zipBytes = ZipEncoder().encode(archive);
    if (zipBytes == null) throw Exception('Could not create Word document.');
    final file = File('${(await getApplicationDocumentsDirectory()).path}/PaperScan_${DateTime.now().millisecondsSinceEpoch}.docx');
    await file.writeAsBytes(zipBytes, flush: true);
    return file;
  }

  static Future<File> ocrImages(List<String> imagePaths) async {
    if (imagePaths.isEmpty) throw Exception('No images selected.');
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    final buffer = StringBuffer();
    try {
      for (var i = 0; i < imagePaths.length; i++) {
        final input = InputImage.fromFilePath(imagePaths[i]);
        final result = await recognizer.processImage(input);
        buffer.writeln('--- Image ${i + 1} ---');
        buffer.writeln(result.text);
        buffer.writeln();
      }
    } finally {
      await recognizer.close();
    }
    final file = File('${(await getApplicationDocumentsDirectory()).path}/PaperScan_OCR_${DateTime.now().millisecondsSinceEpoch}.txt');
    await file.writeAsString(buffer.toString(), flush: true);
    return file;
  }

  static Future<DocumentItem> addTextOverlay(String path, String text, {bool watermark = false}) async {
    if (text.trim().isEmpty) throw Exception('Enter some text first.');
    final doc = sf.PdfDocument(inputBytes: await File(path).readAsBytes());
    try {
      final font = sf.PdfStandardFont(sf.PdfFontFamily.helvetica, watermark ? 30 : 14);
      for (var i = 0; i < doc.pages.count; i++) {
        final page = doc.pages[i];
        final bounds = page.getClientSize();
        page.graphics.drawString(
          text,
          font,
          brush: sf.PdfSolidBrush(sf.PdfColor(55, 95, 210)),
          bounds: ui.Rect.fromLTWH(24, watermark ? bounds.height * .42 : bounds.height - 60, bounds.width - 48, 42),
          format: sf.PdfStringFormat(alignment: watermark ? sf.PdfTextAlignment.center : sf.PdfTextAlignment.left),
        );
      }
      return await _saveGenerated(doc, watermark ? 'Watermarked PDF' : 'Text added PDF', watermark ? 'Watermarked' : 'Edited');
    } finally {
      doc.dispose();
    }
  }

  static Future<DocumentItem> protect(String path, String password) async {
    if (password.length < 4) throw Exception('Password must be at least 4 characters.');
    final doc = sf.PdfDocument(inputBytes: await File(path).readAsBytes());
    try {
      doc.security.userPassword = password;
      doc.security.ownerPassword = password;
      doc.security.algorithm = sf.PdfEncryptionAlgorithm.aesx256Bit;
      return await _saveGenerated(doc, 'Protected PDF', 'Protected');
    } finally {
      doc.dispose();
    }
  }

  static Future<DocumentItem> unlock(String path, String password) async {
    final doc = sf.PdfDocument(inputBytes: await File(path).readAsBytes(), password: password);
    try {
      doc.security.userPassword = '';
      doc.security.ownerPassword = '';
      return await _saveGenerated(doc, 'Unlocked PDF', 'Unlocked');
    } finally {
      doc.dispose();
    }
  }

  static Future<DocumentItem> highlightSearchText(String path, String searchText) async {
    if (searchText.trim().isEmpty) throw Exception('Enter text to highlight.');
    final doc = sf.PdfDocument(inputBytes: await File(path).readAsBytes());
    try {
      final matches = sf.PdfTextExtractor(doc).findText([searchText.trim()]);
      if (matches.isEmpty) throw Exception('No matching selectable text was found.');
      for (final match in matches) {
        final annotation = sf.PdfTextMarkupAnnotation(
          match.bounds,
          'Highlight: $searchText',
          sf.PdfColor(255, 245, 80),
          author: 'PaperScan',
          subject: 'Text highlight',
          textMarkupAnnotationType: sf.PdfTextMarkupAnnotationType.highlight,
          modifiedDate: DateTime.now(),
          setAppearance: true,
        );
        doc.pages[match.pageIndex].annotations.add(annotation);
      }
      return await _saveGenerated(doc, 'Highlighted PDF', 'Highlighted');
    } finally {
      doc.dispose();
    }
  }

  static Future<List<String>> textFieldNames(String path) async {
    final doc = sf.PdfDocument(inputBytes: await File(path).readAsBytes());
    try {
      final names = <String>[];
      for (var i = 0; i < doc.form.fields.count; i++) {
        final field = doc.form.fields[i];
        if (field is sf.PdfTextBoxField && (field.name ?? '').trim().isNotEmpty) {
          names.add(field.name!.trim());
        }
      }
      return names;
    } finally {
      doc.dispose();
    }
  }

  static Future<DocumentItem> fillTextFields(String path, Map<String, String> values) async {
    final doc = sf.PdfDocument(inputBytes: await File(path).readAsBytes());
    try {
      var filled = 0;
      for (var i = 0; i < doc.form.fields.count; i++) {
        final field = doc.form.fields[i];
        if (field is sf.PdfTextBoxField && values.containsKey(field.name)) {
          field.text = values[field.name] ?? '';
          filled++;
        }
      }
      if (filled == 0) throw Exception('No text form fields were filled.');
      doc.form.flattenAllFields();
      return await _saveGenerated(doc, 'Filled PDF form', 'Filled');
    } finally {
      doc.dispose();
    }
  }

  static Future<DocumentItem> rotate(String path, int degrees) async {
    final doc = sf.PdfDocument(inputBytes: await File(path).readAsBytes());
    try {
      final angle = degrees == 90
          ? sf.PdfPageRotateAngle.rotateAngle90
          : degrees == 180
              ? sf.PdfPageRotateAngle.rotateAngle180
              : sf.PdfPageRotateAngle.rotateAngle270;
      for (var i = 0; i < doc.pages.count; i++) {
        doc.pages[i].rotation = angle;
      }
      return await _saveGenerated(doc, 'Rotated PDF', 'Rotated');
    } finally {
      doc.dispose();
    }
  }

  static Future<DocumentItem> _saveGenerated(sf.PdfDocument doc, String title, String prefix) async {
    final bytes = await doc.save();
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final file = File('${DocumentStore.instance.docsDir.path}/$id.pdf');
    await file.writeAsBytes(bytes, flush: true);
    final item = DocumentItem(
      id: id,
      title: '$prefix • $title • ${DateTime.now().toLocal().toString().substring(0, 16)}',
      pdfPath: file.path,
      createdAt: DateTime.now(),
      pageCount: doc.pages.count,
    );
    await DocumentStore.instance.save(item);
    return item;
  }

  static String _xml(String value) => value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&apos;');

  static Future<void> shareFiles(List<File> files, {String? text}) async {
    if (files.isEmpty) return;
    await Share.shareXFiles(files.map((file) => XFile(file.path)).toList(), text: text ?? 'PaperScan exports');
  }

  static Future<void> shareFile(File file, {String? text}) async {
    await Share.shareXFiles([XFile(file.path)], text: text ?? file.uri.pathSegments.last);
  }
}