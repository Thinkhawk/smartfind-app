/// DocumentModel - Represents a file/document in the system
///
/// Stores file metadata and ML-generated properties like topic classification
/// and summaries.
class DocumentModel {
  final String path;           // Full file path
  final String name;           // File name
  final String type;           // File extension (pdf, txt, docx, etc.)
  final int size;              // File size in bytes
  final DateTime lastModified; // Last modification timestamp

  // ML-generated fields (populated after processing)
  int? topicNumber;            // Topic ID from classifier
  String? topicName;           // Human-readable topic name
  String? summary;             // Extractive summary

  DocumentModel({
    required this.path,
    required this.name,
    required this.type,
    required this.size,
    required this.lastModified,
    this.topicNumber,
    this.topicName,
    this.summary,
  });

  /// Unique identifier (using file path)
  String get id => path;

  /// Convert to Map for storage/serialization
  Map<String, dynamic> toMap() => {
    'path': path,
    'name': name,
    'type': type,
    'size': size,
    'lastModified': lastModified.toIso8601String(),
    'topicNumber': topicNumber,
    'topicName': topicName,
    'summary': summary,
  };

  /// Create from Map (deserialization)
  factory DocumentModel.fromMap(Map<String, dynamic> map) => DocumentModel(
    path: map['path'],
    name: map['name'],
    type: map['type'],
    size: map['size'],
    lastModified: DateTime.parse(map['lastModified']),
    topicNumber: map['topicNumber'],
    topicName: map['topicName'],
    summary: map['summary'],
  );

  /// Format file size for display
  String get formattedSize {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Get file icon based on type
  String get icon {
    switch (type.toLowerCase()) {
      case 'pdf':
        return '📄';
      case 'doc':
      case 'docx':
        return '📝';
      case 'txt':
      case 'md':
        return '📃';
      case 'jpg':
      case 'jpeg':
      case 'png':
        return '🖼️';
      default:
        return '📁';
    }
  }
}
