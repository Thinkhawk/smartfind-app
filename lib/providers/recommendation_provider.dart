import 'package:flutter/foundation.dart';
import '../services/ml_service.dart';
import '../models/document_model.dart';
import '../services/file_access_logger.dart';

class RecommendationProvider with ChangeNotifier {
  final MLService _mlService = MLService();
  final FileAccessLogger _logger = FileAccessLogger();

  // Renamed to match your UI usage, likely 'recommendedFilePaths'
  List<String> _recommendedFilePaths = [];
  bool _isLoading = false;

  List<String> get recommendedFilePaths => _recommendedFilePaths;
  bool get isLoading => _isLoading;

  /// CRITICAL FIX: Directly update recommendations based on a specific document
  /// This replaces the passive 'setLastOpened' logic.
  Future<void> updateRecommendations(DocumentModel currentDoc) async {
    _isLoading = true;
    // Notify immediately to show loading spinner in UI
    notifyListeners();

    try {
      print("DEBUG: Updating recommendations for ${currentDoc.name}...");

      // 1. Fetch Content-Based Recommendations (Semantic Similarity)
      // This calls the Python 'get_similar_files' function
      final similarPaths = await _mlService.getSimilarFiles(currentDoc.path);

      // 2. Filter Results
      // Remove the file itself from the list
      List<String> newRecs = similarPaths
          .where((path) => path != currentDoc.path)
          .toSet() // Remove duplicates
          .toList();

      // 3. Fallback: If no semantic matches, use Time-Based (Habit) logs
      if (newRecs.isEmpty) {
        print("DEBUG: No semantic matches. Falling back to time-based history.");
        final logPath = await _logger.getLogPath();
        await _mlService.trainRecommendationModel(logPath);
        final timeBased = await _mlService.getRecommendations();

        for (var path in timeBased) {
          if (path != currentDoc.path && !newRecs.contains(path)) {
            newRecs.add(path);
          }
        }
      }

      // 4. Update State
      _recommendedFilePaths = newRecs;
      print("DEBUG: Final recommendations count: ${_recommendedFilePaths.length}");

    } catch (e) {
      print('Error updating recommendations: $e');
      _recommendedFilePaths = [];
    } finally {
      _isLoading = false;
      // CRITICAL: This triggers the UI to redraw with the new list
      notifyListeners();
    }
  }

  /// Initial load (Optional, for cold start)
  Future<void> loadRecommendations() async {
    _isLoading = true;
    notifyListeners();
    try {
      final logPath = await _logger.getLogPath();
      await _mlService.trainRecommendationModel(logPath);
      _recommendedFilePaths = await _mlService.getRecommendations();
    } catch (e) {
      print(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}