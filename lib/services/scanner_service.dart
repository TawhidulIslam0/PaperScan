
import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';

class ScannerService {
  // Scan document
  static Future<List<String>> scan() async {
    final options = DocumentScannerOptions(
      mode: ScannerMode.full,
      pageLimit: 50,
      isGalleryImport: true,
    );

    final scanner = DocumentScanner(
      options: options,
    );

    try {
      final result = await scanner.scanDocument();

      return result.images ?? [];
    } finally {
      await scanner.close();
    }
  }
}
