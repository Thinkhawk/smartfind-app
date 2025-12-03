import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_file/open_file.dart';
import '../models/document_model.dart';
import '../services/native_file_service.dart';
import '../services/file_access_logger.dart';

/// FileProvider - Manages document scanning and access
///
/// Handles:
/// - Permission checking
/// - File scanning
/// - File opening
/// - Access logging
class FileProvider with ChangeNotifier {
  final NativeFileService _fileService = NativeFileService();
  final FileAccessLogger _logger = FileAccessLogger();

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

  /// Load all documents from file system
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
      _documents = await _fileService.scanDocuments();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Error loading documents: $e';
      print(_errorMessage);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Open document with default app
  Future<void> openDocument(DocumentModel document) async {
    try {
      // Log access
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
