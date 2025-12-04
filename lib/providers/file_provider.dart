import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_file/open_file.dart';
import '../models/document_model.dart';
import '../services/native_file_service.dart';
import '../services/file_access_logger.dart';
import '../services/ml_service.dart';

/// FileProvider - Manages document scanning, access, and search training
class FileProvider with ChangeNotifier {
  final NativeFileService _fileService = NativeFileService();
  final FileAccessLogger _logger = FileAccessLogger();
  final MLService _mlService = MLService();

  List<DocumentModel> _documents = [];
  bool _isLoading = false;
  bool _hasPermission = false;
  String? _errorMessage;

  List<DocumentModel> get documents => _documents;
  bool get isLoading => _isLoading;
  bool get hasPermission => _hasPermission;
  String? get errorMessage => _errorMessage;

  /// Initialize provider
  Future<void> initialize() async {
    await _logger.initialize();
    await checkPermissions();
  }

  /// Check storage permissions
  Future<void> checkPermissions() async {
    try {
      final status = await Permission.manageExternalStorage.status;
      _hasPermission = status.isGranted;
      notifyListeners();
    } catch (e) {
      print('Error checking permissions: $e');
      _hasPermission = false;
      notifyListeners();
    }
  }

  /// Request storage permission
  Future<bool> requestPermission() async {
    try {
      final status = await Permission.manageExternalStorage.request();
      _hasPermission = status.isGranted;
      notifyListeners();
      return _hasPermission;
    } catch (e) {
      print('Error requesting permission: $e');
      _hasPermission = false;
      notifyListeners();
      return false;
    }
  }

  /// Load documents and train search index
  Future<void> loadDocuments() async {
    if (!_hasPermission) {
      _errorMessage = 'Storage permission not granted';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Scan files from device
      _documents = await _fileService.scanDocuments();
      _errorMessage = null;

      // 2. Train Search Index on these specific files
      // This allows the app to learn keywords like "Python" or "Flink"
      // directly from the user's documents.
      await _trainSearchModel();

    } catch (e) {
      _errorMessage = 'Error loading documents: $e';
      print(_errorMessage);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Helper: Reads all files and sends content to Python for indexing
  Future<void> _trainSearchModel() async {
    final Map<String, String> corpus = {};

    print("DEBUG: Preparing to train search index...");

    // Read content for each document
    for (final doc in _documents) {
      try {
        final content = await _mlService.readFile(doc.path);
        if (content != null && content.isNotEmpty) {
          corpus[doc.path] = content;
        }
      } catch (e) {
        print("DEBUG: Failed to read ${doc.path} for training: $e");
      }
    }

    // Send to Python if we have data
    if (corpus.isNotEmpty) {
      print("DEBUG: Starting bulk training for search with ${corpus.length} documents...");
      await _mlService.trainSearchIndex(corpus);
    } else {
      print("DEBUG: No content available to train search index.");
    }
  }

  /// Open document with default app
  Future<void> openDocument(DocumentModel document) async {
    try {
      // Log access for recommendations
      await _logger.logAccess(document);

      // Open file
      await OpenFile.open(document.path);
    } catch (e) {
      print('Error opening document: $e');
    }
  }

  /// Get document by path
  DocumentModel? getDocumentByPath(String path) {
    try {
      return _documents.firstWhere((doc) => doc.path == path);
    } catch (e) {
      return null;
    }
  }

  /// Refresh document list
  Future<void> refresh() async {
    await loadDocuments();
  }

  /// Get access log path for training
  Future<String> getAccessLogPath() async {
    return await _logger.getLogPath();
  }
}