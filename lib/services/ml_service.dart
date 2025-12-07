import 'package:flutter/services.dart';

/// MLService - Bridge to Python ML models via platform channels
class MLService {
  static const MethodChannel _channel = MethodChannel('com.smartfind/ml');

  /// Classify document text and get topic assignment
  Future<Map<String, dynamic>> classifyFile(String text) async {
    try {
      final result = await _channel.invokeMethod('classifyFile', {
        'text': text,
      });
      return Map<String, dynamic>.from(result);
    } catch (e) {
      print('Classification error: $e');
      return {'topic_number': -1, 'confidence': 0.0};
    }
  }

  /// Generate extractive summary of document
  Future<String?> getSummary(String text) async {
    try {
      final result = await _channel.invokeMethod('summarizeFile', {
        'text': text,
      });
      return result['summary'] as String?;
    } catch (e) {
      print('Summarization error: $e');
      return null;
    }
  }

  /// Read file content
  Future<String?> readFile(String filePath) async {
    try {
      final result = await _channel.invokeMethod('readFile', {
        'file_path': filePath,
      });
      return result['content'] as String?;
    } catch (e) {
      print('File reading error: $e');
      return null;
    }
  }

  /// Perform semantic search
  Future<List<String>> semanticSearch(String query) async {
    try {
      final result = await _channel.invokeMethod('searchDocuments', {
        'query': query,
      });
      return List<String>.from(result['results']);
    } catch (e) {
      print('Search error: $e');
      return [];
    }
  }

  /// Add single document to search index (Legacy/Single addition)
  Future<void> indexFile(String filePath, String content) async {
    try {
      await _channel.invokeMethod('addToIndex', {
        'file_path': filePath,
        'content': content,
      });
    } catch (e) {
      print('Indexing error: $e');
    }
  }

  /// NEW: Trigger on-device training for search
  /// contentMap: { 'path': 'file content' }
  Future<void> trainSearchIndex(Map<String, String> contentMap) async {
    try {
      print("DEBUG: Sending ${contentMap.length} docs for training...");
      await _channel.invokeMethod('trainSearchIndex', {
        'files': contentMap,
      });
    } catch (e) {
      print('Training error: $e');
    }
  }

  /// Get recommendations
  Future<List<String>> getRecommendations() async {
    try {
      final now = DateTime.now();
      final result = await _channel.invokeMethod('getRecommendations', {
        'month': now.month,
        'weekday': now.weekday,
        'hour': now.hour,
      });
      return List<String>.from(result['recommendations']);
    } catch (e) {
      print('Recommendation error: $e');
      return [];
    }
  }

  /// Train recommendation model
  Future<void> trainRecommendationModel(String logPath) async {
    try {
      await _channel.invokeMethod('trainRecommender', {
        'log_path': logPath,
      });
    } catch (e) {
      print('Training error: $e');
    }
  }

  Future<List<String>> getIndexedPaths() async {
    try {
      final List<dynamic> result = await _channel.invokeMethod('getIndexedPaths', {});
      return result.cast<String>();
    } catch (e) {
      print('Error getting indexed paths: $e');
      return [];
    }
  }
}