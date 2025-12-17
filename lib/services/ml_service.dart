import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class MLService {
  static const MethodChannel _channel = MethodChannel('com.smartfind/ml');

  /// Call this in main.dart before running the app
  Future<void> initialize() async {
    print("DEBUG: Initializing MLService assets...");
    final directory = await getApplicationSupportDirectory();
    final modelsDir = Directory('${directory.path}/models');

    if (!await modelsDir.exists()) {
      await modelsDir.create(recursive: true);
    }

    // List of ALL files to copy
    final assets = [
      'vocab.json',         // <--- Critical
      'word_vectors.npy',   // <--- Critical
      'topic_vectors.npy',
      'topic_words.npy',
      // 'doc2vec_lite.model', // Legacy, optional
    ];

    for (String assetName in assets) {
      final targetPath = '${modelsDir.path}/$assetName';

      try {
        // We use rootBundle to read from assets/models/
        final data = await rootBundle.load('assets/models/$assetName');
        final bytes = data.buffer.asUint8List();

        // Write to device storage
        await File(targetPath).writeAsBytes(bytes, flush: true);
        print('DEBUG: Successfully copied asset: $assetName to $targetPath');
      } catch (e) {
        // Don't crash if an optional file is missing, but warn
        print('WARNING: Failed to copy asset $assetName: $e');
      }
    }
  }

  // --- Core ML Methods ---

  Future<Map<String, dynamic>> classifyFile(String text) async {
    try {
      final result = await _channel.invokeMethod('classifyFile', {'text': text});
      return Map<String, dynamic>.from(result);
    } catch (e) {
      print('Classification error: $e');
      return {'topic_number': -1, 'confidence': 0.0};
    }
  }

  Future<String?> getSummary(String text) async {
    try {
      final result = await _channel.invokeMethod('summarizeFile', {'text': text});
      return result['summary'] as String?;
    } catch (e) {
      return null;
    }
  }

  Future<String?> readFile(String filePath) async {
    try {
      final result = await _channel.invokeMethod('readFile', {'file_path': filePath});
      return result['content'] as String?;
    } catch (e) {
      return null;
    }
  }

  // --- Search & Indexing ---

  Future<List<String>> semanticSearch(String query) async {
    try {
      final result = await _channel.invokeMethod('searchDocuments', {'query': query});
      return List<String>.from(result['results']);
    } catch (e) {
      return [];
    }
  }

  Future<void> trainSearchIndex(Map<String, String> contentMap) async {
    try {
      print("DEBUG: Sending ${contentMap.length} docs for training...");
      await _channel.invokeMethod('trainSearchIndex', {'files': contentMap});
    } catch (e) {
      print('Training error: $e');
    }
  }

  /// RESTORED: Add single document to search index
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

  /// RESTORED: Get list of indexed paths
  Future<List<String>> getIndexedPaths() async {
    try {
      final List<dynamic> result = await _channel.invokeMethod('getIndexedPaths', {});
      return result.cast<String>();
    } catch (e) {
      print('Error getting indexed paths: $e');
      return [];
    }
  }

  // --- Recommendation & Similarity ---

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
      return [];
    }
  }

  Future<void> trainRecommendationModel(String logPath) async {
    try {
      await _channel.invokeMethod('trainRecommender', {'log_path': logPath});
    } catch (e) {
      print('Training error: $e');
    }
  }

  /// RESTORED: Get similar files (Fixes your build error)
  Future<List<String>> getSimilarFiles(String filePath) async {
    try {
      final result = await _channel.invokeMethod('getSimilarFiles', {
        'file_path': filePath,
      });
      // Safety check if result is null or missing key
      if (result == null || result['results'] == null) return [];
      return List<String>.from(result['results']);
    } catch (e) {
      print('Similarity error: $e');
      return [];
    }
  }
}