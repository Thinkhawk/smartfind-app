import 'package:flutter/foundation.dart';
import '../services/ml_service.dart';

/// RecommendationProvider - Manages file recommendations
///
/// Provides time-based file recommendations using access patterns
class RecommendationProvider with ChangeNotifier {
  final MLService _mlService = MLService();

  List<String> _recommendedFilePaths = [];
  bool _isLoading = false;

  List<String> get recommendedFilePaths => _recommendedFilePaths;
  bool get isLoading => _isLoading;

  /// Load recommendations for current time
  Future<void> loadRecommendations() async {
    _isLoading = true;
    notifyListeners();

    try {
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
