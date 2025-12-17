import 'package:flutter/foundation.dart';
import '../services/ml_service.dart';
import '../models/document_model.dart';

class RecommendationProvider with ChangeNotifier {
  final MLService _mlService = MLService();

  List<String> _recommendedFilePaths = [];
  bool _isLoading = false;

  List<String> get recommendedFilePaths => _recommendedFilePaths;
  bool get isLoading => _isLoading;

  /// Updates recommendations based ONLY on the content of the current document.
  Future<void> updateRecommendations(DocumentModel currentDoc) async {
    _isLoading = true;
    // Notify immediately to show loading spinner in UI if needed
    notifyListeners();

    try {
      print("DEBUG: Fetching content-based recommendations for ${currentDoc.name}...");

      // 1. Fetch Content-Based Recommendations (Semantic Similarity)
      // This calls the Python logic to compare Vector Embeddings
      final similarPaths = await _mlService.getSimilarFiles(currentDoc.path);

      // 2. Filter Results
      // Remove the file itself from the list and ensure uniqueness
      _recommendedFilePaths = similarPaths
          .where((path) => path != currentDoc.path)
          .toSet() // Remove duplicates
          .toList();

      print("DEBUG: Content-based results count: ${_recommendedFilePaths.length}");

    } catch (e) {
      print('Error updating recommendations: $e');
      _recommendedFilePaths = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clears recommendations (useful when closing a document)
  void clearRecommendations() {
    _recommendedFilePaths = [];
    notifyListeners();
  }
}