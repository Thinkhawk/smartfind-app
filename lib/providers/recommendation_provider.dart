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

  /// Load recommendations for current time
  Future<void> loadRecommendations() async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Train first! (Consume any new logs from CSV)
      final logPath = await _logger.getLogPath();
      await _mlService.trainRecommendationModel(logPath);

      // 2. Now get predictions based on the updated model
      _recommendedFilePaths = await _mlService.getRecommendations();

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
