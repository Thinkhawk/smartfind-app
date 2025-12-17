import 'package:flutter/foundation.dart';
import '../services/ml_service.dart';
import '../models/document_model.dart';

class RecommendationProvider with ChangeNotifier {
  final MLService _mlService = MLService();

  List<String> _recommendedFilePaths = [];
  bool _isLoading = false;
  String? _lastViewedFilePath;

  List<String> get recommendedFilePaths => _recommendedFilePaths;

  bool get isLoading => _isLoading;

  Future<void> loadRecommendations() async {
    if (_lastViewedFilePath == null) {
      _recommendedFilePaths = [];
      notifyListeners();
      return;
    }
    _isLoading = true;
    notifyListeners();
    try {
      print(
          "DEBUG: Loading Home recommendations based on last viewed: $_lastViewedFilePath");
      final similarPaths =
          await _mlService.getSimilarFiles(_lastViewedFilePath!);
      _recommendedFilePaths = similarPaths
          .where((path) => path != _lastViewedFilePath)
          .take(5) // Limit to top 5 for efficiency
          .toList();
    } catch (e) {
      print("Error loading home recommendations: $e");
      _recommendedFilePaths = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateRecommendations(DocumentModel currentDoc) async {
    _isLoading = true;
    _lastViewedFilePath = currentDoc.path;

    notifyListeners();

    try {
      print(
          "DEBUG: Fetching content-based recommendations for ${currentDoc.name}...");
      final similarPaths = await _mlService.getSimilarFiles(currentDoc.path);
      _recommendedFilePaths = similarPaths
          .where((path) => path != currentDoc.path)
          .toSet()
          .toList();
    } catch (e) {
      print('Error updating recommendations: $e');
      _recommendedFilePaths = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearRecommendations() {
    _recommendedFilePaths = [];
    notifyListeners();
  }
}
