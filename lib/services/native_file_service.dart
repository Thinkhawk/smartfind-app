import 'dart:io';
import 'package:path/path.dart' as path;
import '../models/document_model.dart';

/// NativeFileService - Scans and manages native file system
///
/// Discovers documents in common directories (Documents, Downloads, etc.)
class NativeFileService {
  /// Supported file extensions
  static const List<String> _supportedExtensions = [
    'pdf', 'doc', 'docx', 'txt', 'md',
    'jpg', 'jpeg', 'png', 'bmp', 'tiff'
  ];

  /// Common document directories on Android
  List<String> get _documentPaths => [
    '/storage/emulated/0/Documents',
    '/storage/emulated/0/Download',
    '/storage/emulated/0/DCIM',
  ];

  /// Scan all document directories for supported files
  Future<List<DocumentModel>> scanDocuments() async {
    final List<DocumentModel> documents = [];

    for (final dirPath in _documentPaths) {
      final dir = Directory(dirPath);

      if (!await dir.exists()) continue;

      try {
        await for (final entity in dir.list(recursive: true)) {
          if (entity is File) {
            final doc = await _createDocumentModel(entity);
            if (doc != null) {
              documents.add(doc);
            }
          }
        }
      } catch (e) {
        print('Error scanning $dirPath: $e');
      }
    }

    return documents;
  }

  /// Create DocumentModel from file
  Future<DocumentModel?> _createDocumentModel(File file) async {
    try {
      final fileName = path.basename(file.path);
      final extension = path.extension(fileName).replaceFirst('.', '').toLowerCase();

      // Check if extension is supported
      if (!_supportedExtensions.contains(extension)) {
        return null;
      }

      final stat = await file.stat();

      return DocumentModel(
        path: file.path,
        name: fileName,
        type: extension,
        size: stat.size,
        lastModified: stat.modified,
      );
    } catch (e) {
      print('Error creating document model: $e');
      return null;
    }
  }

  /// Check if a specific path exists
  Future<bool> fileExists(String filePath) async {
    return await File(filePath).exists();
  }

  /// Get file metadata
  Future<DocumentModel?> getFileMetadata(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return null;

      return await _createDocumentModel(file);
    } catch (e) {
      print('Error getting file metadata: $e');
      return null;
    }
  }
}
