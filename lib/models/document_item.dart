class DocumentItem {
  final String id;
  final String title;
  final String pdfPath;

  final DateTime createdAt;
  final int pageCount;
  final String folder;

  DocumentItem({
    required this.id,
    required this.title,
    required this.pdfPath,
    required this.createdAt,
    required this.pageCount,
    this.folder = 'All documents',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'pdfPath': pdfPath,
        'createdAt': createdAt.toIso8601String(),
        'pageCount': pageCount,
        'folder': folder,
      };

  factory DocumentItem.fromJson(Map<String, dynamic> j) {
    return DocumentItem(
      id: j['id'],
      title: j['title'],
      pdfPath: j['pdfPath'],
      createdAt: DateTime.parse(j['createdAt']),
      pageCount: j['pageCount'] ?? 1,
      folder: j['folder'] ?? 'All documents',
    );
  }
}