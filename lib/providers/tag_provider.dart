import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/file_tag_model.dart';
import '../models/document_model.dart';
import '../services/ml_service.dart';

/// TagProvider - Manages file-to-topic mappings
///
/// Handles:
/// - Topic name loading
/// - File classification
/// - Tag mapping persistence
/// - Topic queries
class TagProvider with ChangeNotifier {
  final MLService _mlService = MLService();

  FileTagMapping? _tagMapping;
  Map<int, String> _topicNames = {};
  bool _isLoading = false;

  FileTagMapping? get tagMapping => _tagMapping;
  bool get isLoading => _isLoading;
  Set<int> get visibleTopics => _tagMapping?.getVisibleTopics() ?? {};

  /// Initialize with topic names
  ///
  /// TODO: Load from assets or backend
  /// For now, using hardcoded example topics
  Future<void> loadTopicNames() async {
    _topicNames = {
      0: "Finance",
      1: "Work",
      2: "Personal",
      3: "Research",
      4: "Health",
      5: "Education",
      6: "Travel",
      7: "Legal",
      8: "Technology",
      9: "Entertainment",
    };
    notifyListeners();
  }

  /// Load tag mapping from CSV file
  Future<void> loadTagMapping() async {
    _isLoading = true;
    notifyListeners();

    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/file_tags.csv');

      if (await file.exists()) {
        final csvContent = await file.readAsString();
        _tagMapping = FileTagMapping.fromCsv(csvContent, _topicNames);
      } else {
        // Initialize empty mapping
        _tagMapping = FileTagMapping(
          fileToTopics: {},
          topicNames: _topicNames,
          topicToFiles: {},
        );
      }
    } catch (e) {
      print('Error loading tag mapping: $e');
      _tagMapping = FileTagMapping(
        fileToTopics: {},
        topicNames: _topicNames,
        topicToFiles: {},
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Classify and tag a document
  Future<void> classifyAndTagFile(DocumentModel document) async {
    try {
      // First, read file content
      final content = await _mlService.readFile(document.path);

      if (content == null || content.isEmpty) {
        print('Could not read file: ${document.path}');
        return;
      }

      // Classify content
      final result = await _mlService.classifyFile(content);

      if (result.isNotEmpty && result['topic_number'] != -1) {
        final topicNumber = result['topic_number'] as int;
        final confidence = result['confidence'] as double;

        // Only tag if confidence is reasonable
        if (confidence > 0.3) {
          final topicName = _topicNames[topicNumber] ?? 'Topic $topicNumber';

          // Update document
          document.topicNumber = topicNumber;
          document.topicName = topicName;

          // Update mapping
          _tagMapping?.fileToTopics
              .putIfAbsent(document.path, () => [])
              .add(topicNumber);
          _tagMapping?.topicToFiles
              .putIfAbsent(topicNumber, () => {})
              .add(document.path);

          // Save mapping
          await _saveTagMapping();

          // Index for search
          await _mlService.indexFile(document.path, content);

          notifyListeners();
        }
      }
    } catch (e) {
      print('Error classifying file: $e');
    }
  }

  /// Save tag mapping to CSV file
  Future<void> _saveTagMapping() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/file_tags.csv');

      final csvContent = _tagMapping?.toCsv() ?? 'file_path,topic_number\n';
      await file.writeAsString(csvContent);
    } catch (e) {
      print('Error saving tag mapping: $e');
    }
  }

  /// Get files for a specific topic
  List<String> getFilesForTopic(int topicNumber) {
    return _tagMapping?.getFilesForTopic(topicNumber) ?? [];
  }

  /// Get topic name by number
  String? getTopicName(int topicNumber) {
    return _topicNames[topicNumber];
  }

  /// Get file count for topic
  int getTopicFileCount(int topicNumber) {
    return _tagMapping?.getTopicFileCount(topicNumber) ?? 0;
  }
}
