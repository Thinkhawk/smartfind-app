import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_file/open_file.dart';
import '../models/document_model.dart';
import '../services/native_file_service.dart';
import '../services/file_access_logger.dart';
import '../services/ml_service.dart';
import '../services/ocr_service.dart';

class FileProvider with ChangeNotifier {
  final NativeFileService _fileService = NativeFileService();
  final FileAccessLogger _logger = FileAccessLogger();
  final MLService _mlService = MLService();
  final OcrService _ocrService = OcrService();

  List<DocumentModel> _documents = [];
  bool _isLoading = false;
  bool _hasPermission = false;
  String? _errorMessage;

  List<DocumentModel> get documents => _documents;
  bool get isLoading => _isLoading;
  bool get hasPermission => _hasPermission;
  String? get errorMessage => _errorMessage;

  Future<void> initialize() async {
    await _logger.initialize();
    await checkPermissions();
  }

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
    notifyListeners();

    try {
      // 1. Scan files
      _documents = await _fileService.scanDocuments();
      _errorMessage = null;

      // 2. Extract Content & Train
      // We extract content here and pass it directly to training
      // so we don't lose the OCR results.
      await _processAndTrain();

    } catch (e) {
      _errorMessage = 'Error loading documents: $e';
      print(_errorMessage);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _processAndTrain() async {
    final Map<String, String> corpus = {};
    print("DEBUG: Extracting content for ${documents.length} files...");

    for (final doc in _documents) {
      try {
        String? content;

        // CHECK FILE TYPE
        if (_isImage(doc.type)) {
          // Use Flutter OCR for Images
          content = await _ocrService.extractText(doc.path);
        } else {
          // Use Python for PDF/Docs
          content = await _mlService.readFile(doc.path);
        }

        if (content != null && content.isNotEmpty) {
          // --- CHANGE HERE ---
          // Inject "keywords" about the file itself.
          // If it's a png, we add words like "image picture png" to the content.
          String metaTags = "${doc.name} ${doc.type}";

          if (_isImage(doc.type)) {
            metaTags += " image picture photo";
          } else if (doc.type == 'pdf' || doc.type == 'docx') {
            metaTags += " document paper file";
          }

          // Combine metadata + real content
          corpus[doc.path] = "$metaTags \n $content";
        }
      } catch (e) {
        print("DEBUG: Failed to process ${doc.path}: $e");
      }
    }

    if (corpus.isNotEmpty) {
      await _mlService.trainSearchIndex(corpus);
    }
  }

  bool _isImage(String extension) {
    return ['jpg', 'jpeg', 'png', 'bmp', 'tiff'].contains(extension.toLowerCase());
  }

  Future<void> openDocument(DocumentModel document) async {
    try {
      await _logger.logAccess(document);
      await OpenFile.open(document.path);
    } catch (e) {
      print('Error opening document: $e');
    }
  }

  DocumentModel? getDocumentByPath(String path) {
    try {
      return _documents.firstWhere((doc) => doc.path == path);
    } catch (e) {
      return null;
    }
  }

  Future<void> refresh() async {
    await loadDocuments();
  }

  Future<String> getAccessLogPath() async {
    return await _logger.getLogPath();
  }

  @override
  void dispose() {
    _ocrService.dispose();
    super.dispose();
  }
}