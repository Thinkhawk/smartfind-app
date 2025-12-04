import 'dart:io';
import 'package:path/path.dart' as path;
import '../models/document_model.dart';

class NativeFileService {
  static const List<String> _supportedExtensions = [
    'pdf', 'doc', 'docx', 'txt', 'md',
    'jpg', 'jpeg', 'png', 'bmp', 'tiff'
  ];

  List<String> get _documentPaths => [
    '/storage/emulated/0/Documents',
    '/storage/emulated/0/Download',
    '/storage/emulated/0/DCIM',
  ];

  Future<List<DocumentModel>> scanDocuments() async {
    final List<DocumentModel> documents = [];
    print("DEBUG: Starting scan...");

    for (final dirPath in _documentPaths) {
      final dir = Directory(dirPath);
      if (!await dir.exists()) {
        print("DEBUG: Skipping $dirPath (does not exist)");
        continue;
      }

      print("DEBUG: Scanning directory: $dirPath");
      try {
        await for (final entity in dir.list(recursive: true)) {
          if (entity is File) {
            final doc = await _createDocumentModel(entity);
            if (doc != null) {
              print("DEBUG: Found supported file: ${doc.name}");
              documents.add(doc);
            }
          }
        }
      } catch (e) {
        print('DEBUG: Error scanning $dirPath: $e');
      }
    }

    print("DEBUG: Scan complete. Found ${documents.length} files.");
    return documents;
  }

  Future<DocumentModel?> _createDocumentModel(File file) async {
    try {
      final fileName = path.basename(file.path);
      // Handle files with no extension
      if (!fileName.contains('.')) return null;

      final extension = path.extension(fileName).replaceFirst('.', '').toLowerCase();

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
      print('DEBUG: Error creating model for ${file.path}: $e');
      return null;
    }
  }

// ... keep other methods ...
}