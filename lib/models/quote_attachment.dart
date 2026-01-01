class QuoteAttachment {
  final int? id;
  final int quoteId;
  final String fileName;
  final String filePath;
  final String? mimeType;
  final int fileSize;
  final DateTime createdAt;

  QuoteAttachment({
    this.id,
    required this.quoteId,
    required this.fileName,
    required this.filePath,
    this.mimeType,
    required this.fileSize,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'quote_id': quoteId,
      'file_name': fileName,
      'file_path': filePath,
      'mime_type': mimeType,
      'file_size': fileSize,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory QuoteAttachment.fromMap(Map<String, dynamic> map) {
    return QuoteAttachment(
      id: map['id'],
      quoteId: map['quote_id'],
      fileName: map['file_name'],
      filePath: map['file_path'],
      mimeType: map['mime_type'],
      fileSize: map['file_size'] ?? 0,
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  QuoteAttachment copyWith({
    int? id,
    int? quoteId,
    String? fileName,
    String? filePath,
    String? mimeType,
    int? fileSize,
    DateTime? createdAt,
  }) {
    return QuoteAttachment(
      id: id ?? this.id,
      quoteId: quoteId ?? this.quoteId,
      fileName: fileName ?? this.fileName,
      filePath: filePath ?? this.filePath,
      mimeType: mimeType ?? this.mimeType,
      fileSize: fileSize ?? this.fileSize,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
