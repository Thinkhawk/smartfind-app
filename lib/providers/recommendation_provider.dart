import 'package:flutter/foundation.dart';
import '../services/ml_service.dart';
import '../services/file_access_logger.dart'; // Import Logger

class RecommendationProvider with ChangeNotifier {
  final MLService _mlService = MLService();
  final FileAccessLogger _logger = FileAccessLogger(); // Access logger to get path

  List<String> _recommendedFilePaths = [];
  bool _isLoading = false;

  List<String> get recommendedFilePaths => _recommendedFilePaths;
  bool get isLoading => _isLoading;

// Add a field to track the last opened file
  String? _lastOpenedPath;

  void setLastOpened(String path) {
    _lastOpenedPath = path;
    // Auto-refresh recommendations when context changes
    refresh();
  }

  Future<void> loadRecommendations() async {
    _isLoading = true;
    notifyListeners();

    try {
      List<String> results = [];

      // STRATEGY 1: Content-Based (High Priority)
      // "Since you just looked at X, here is Y"
      if (_lastOpenedPath != null) {
        print("DEBUG: Fetching content-based recs for $_lastOpenedPath");
        final similar = await _mlService.getSimilarFiles(_lastOpenedPath!);
        results.addAll(similar);
      }

      // STRATEGY 2: Time-Based (Fill the rest)
      // "It's Monday morning, here is what you usually open"
      if (results.length < 5) {
        // Train first to ensure logs are up to date
        final logPath = await _logger.getLogPath();
        await _mlService.trainRecommendationModel(logPath);

        final timeBased = await _mlService.getRecommendations();

        // Add unique items only
        for (var path in timeBased) {
          if (!results.contains(path) && results.length < 5) {
            results.add(path);
          }
        }
      }

      _recommendedFilePaths = results;

    } catch (e) {
      print('Error loading recommendations: $e');
      _recommendedFilePaths = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Train recommendation model
  Future<void> trainModel(String logPath) async {
    try {
      await _mlService.trainRecommendationModel(logPath);
    } catch (e) {
      print('Training error: $e');
    }
  }

  /// Refresh recommendations
  Future<void> refresh() async {
    await loadRecommendations();
  }
}
