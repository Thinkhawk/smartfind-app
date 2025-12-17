import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_file/open_file.dart';
import '../models/document_model.dart';
import '../services/native_file_service.dart';
import '../services/ml_service.dart';
import '../services/ocr_service.dart';
import 'recommendation_provider.dart';
import 'dart:io';

class FileProvider with ChangeNotifier {
  final NativeFileService _fileService = NativeFileService();
  final MLService _mlService = MLService();
  final OcrService _ocrService = OcrService();

  List<List<DocumentModel>> _duplicateClusters = [];
  List<List<DocumentModel>> get duplicateClusters => _duplicateClusters;

  List<DocumentModel> _documents = [];
  bool _isLoading = false;
  bool _hasPermission = false;
  String? _errorMessage;

  List<DocumentModel> get documents => _documents;

  bool get isLoading => _isLoading;

  bool get hasPermission => _hasPermission;

  String? get errorMessage => _errorMessage;

  Future<void> initialize() async {
    await checkPermissions();
  }

  Future<String?> getFileContent(DocumentModel doc) async {
    try {
      if (_isImage(doc.type)) {
        return await _ocrService.extractText(doc.path);
      } else {
        return await _mlService.readFile(doc.path);
      }
    } catch (e) {
      print("Error reading content for ${doc.name}: $e");
      return null;
    }
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

  Future<void> loadDocuments() async {
    if (!_hasPermission) {
      _errorMessage = 'Storage permission not granted';
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      _documents = await _fileService.scanDocuments();
      _errorMessage = null;
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
        final content = await getFileContent(doc);

        if (content != null && content.isNotEmpty) {
          String metaTags =
              "${doc.name} ${doc.name} ${doc.name} ${doc.type} ${doc.type}";

          if (_isImage(doc.type)) {
            metaTags += " image image image picture photo";
          } else if (doc.type == 'pdf' || doc.type == 'docx') {
            metaTags += " document paper file";
          }

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
    return ['jpg', 'jpeg', 'png', 'bmp', 'tiff']
        .contains(extension.toLowerCase());
  }

  Future<void> openDocument(
      DocumentModel document, RecommendationProvider recProvider) async {
    try {
      await recProvider.updateRecommendations(document);
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

  @override
  void dispose() {
    _ocrService.dispose();
    super.dispose();
  }

  Future<void> scanForDuplicates() async {
    _isLoading = true;
    notifyListeners();

    try {
      final List<dynamic> rawClusters = await _mlService.findDuplicateClusters();

      _duplicateClusters = rawClusters.map((paths) {
        return (paths as List).map((path) => getDocumentByPath(path.toString()))
            .whereType<DocumentModel>() // Remove nulls if a file was moved
            .toList();
      }).toList();

    } catch (e) {
      print("Error scanning duplicates: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteDocument(DocumentModel doc) async {
    try {
      final file = File(doc.path);
      if (await file.exists()) {
        await file.delete();

        _documents.removeWhere((item) => item.path == doc.path);

        for (var cluster in _duplicateClusters) {
          cluster.removeWhere((item) => item.path == doc.path);
        }
        _duplicateClusters.removeWhere((cluster) => cluster.length < 2);

        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print("Failed to delete file: $e");
      return false;
    }
  }
}
