import 'package:flutter/services.dart';

/// MLService - Bridge to Python ML models via platform channels
///
/// This service communicates with Python scripts running via Chaquopy
/// to perform ML operations: classification, search, summarization, etc.
class MLService {
  static const MethodChannel _channel = MethodChannel('com.smartfind/ml');

  /// Classify document text and get topic assignment
  ///
  /// Returns: {topic_number: int, confidence: double}
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
  ///
  /// Returns: {summary: String}
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

  /// Read file content (supports PDF, DOCX, TXT, images with OCR)
  ///
  /// Returns: {content: String}
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

  /// Perform semantic search across indexed documents
  ///
  /// Returns: List of file paths
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

  /// Add document to search index
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

  /// Get file recommendations based on current time
  ///
  /// Returns: List of recommended file paths
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

  /// Train recommendation model on access logs
  Future<void> trainRecommendationModel(String logPath) async {
    try {
      await _channel.invokeMethod('trainRecommender', {
        'log_path': logPath,
      });
    } catch (e) {
      print('Training error: $e');
    }
  }
}
