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
      'vocab.json',
      'word_vectors.npy',
      'topic_vectors.npy',
      'topic_words.npy',
    ];

    for (String assetName in assets) {
      final targetPath = '${modelsDir.path}/$assetName';
      try {
        final data = await rootBundle.load('assets/models/$assetName');
        final bytes = data.buffer.asUint8List();
        await File(targetPath).writeAsBytes(bytes, flush: true);
        print('DEBUG: Successfully copied asset: $assetName');
      } catch (e) {
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

  Future<List<String>> getIndexedPaths() async {
    try {
      final List<dynamic> result = await _channel.invokeMethod('getIndexedPaths', {});
      return result.cast<String>();
    } catch (e) {
      print('Error getting indexed paths: $e');
      return [];
    }
  }

  // --- Content-Based Similarity Only ---

  /// Finds files that are semantically similar to the provided file path.
  /// Uses Vector Embeddings (Word2Vec/Doc2Vec) via Python backend.
  Future<List<String>> getSimilarFiles(String filePath) async {
    try {
      final result = await _channel.invokeMethod('getSimilarFiles', {
        'file_path': filePath,
      });
      // Safety check
      if (result == null || result['results'] == null) return [];
      return List<String>.from(result['results']);
    } catch (e) {
      print('Similarity error: $e');
      return [];
    }
  }
}