import 'package:flutter/foundation.dart';
import '../services/ml_service.dart';
import '../models/document_model.dart';

class RecommendationProvider with ChangeNotifier {
  final MLService _mlService = MLService();

  List<String> _recommendedFilePaths = [];
  bool _isLoading = false;

  // Simple in-memory tracker for the "Efficient Approach"
  // We recommend based on the last file the user was interested in.
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
      print("DEBUG: Loading Home recommendations based on last viewed: $_lastViewedFilePath");
      final similarPaths = await _mlService.getSimilarFiles(_lastViewedFilePath!);

      // Filter out the source file itself
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

  /// Updates recommendations when a specific document is opened.
  Future<void> updateRecommendations(DocumentModel currentDoc) async {
    _isLoading = true;

    // 1. Update Session History (The "Efficient" Tracker)
    _lastViewedFilePath = currentDoc.path;

    notifyListeners();

    try {
      print("DEBUG: Fetching content-based recommendations for ${currentDoc.name}...");

      // 2. Fetch Content-Based Recommendations (Semantic Similarity)
      final similarPaths = await _mlService.getSimilarFiles(currentDoc.path);

      // 3. Filter Results
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