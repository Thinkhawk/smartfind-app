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
/// - File classification (with "Others" fallback)
/// - Tag mapping persistence
class TagProvider with ChangeNotifier {
  final MLService _mlService = MLService();

  FileTagMapping? _tagMapping;
  Map<int, String> _topicNames = {};
  bool _isLoading = false;

  FileTagMapping? get tagMapping => _tagMapping;
  bool get isLoading => _isLoading;
  Set<int> get visibleTopics => _tagMapping?.getVisibleTopics() ?? {};

  /// Initialize with default topic names
  Future<void> loadTopicNames() async {
    // Basic topics from 20 Newsgroups dataset (indices 0-19)
    // Plus our fallback category (99)
    _topicNames = {
      0: "Tech / Graphics", 1: "Windows OS", 2: "IBM Hardware", 3: "Mac Hardware", 4: "PC Hardware",
      5: "For Sale", 6: "Autos", 7: "Motorcycles", 8: "Baseball", 9: "Hockey",
      10: "Crypto / Security", 11: "Electronics", 12: "Medicine", 13: "Space", 14: "Christianity",
      15: "Politics / Guns", 16: "Politics / Mideast", 17: "Politics / Misc", 18: "Religion / Atheism", 19: "Religion / Misc",
      // Fallback Category for unclassified files
      99: "Others",
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
      // 1. Read file content
      final content = await _mlService.readFile(document.path);

      // If read fails or empty, assign to Others immediately
      if (content == null || content.isEmpty) {
        print('DEBUG: Content empty/failed for ${document.name}. Assigning to Others.');
        _assignToTopic(document, 99);
        return;
      }

      // NOTE: We REMOVED the 'indexFile' call here because indexing is now
      // done in bulk by FileProvider._trainSearchModel()

      // 2. Classify content
      final result = await _mlService.classifyFile(content);

      int topicNumber = result['topic_number'] ?? -1;

      // LOGIC FIX: If topic is -1 (Unknown/Low Confidence), assign to "Others" (99)
      // This prevents files from disappearing from the UI.
      if (topicNumber == -1) {
        print("DEBUG: Model returned -1 for '${document.name}'. Assigning to Others.");
        topicNumber = 99;
      } else {
        print("DEBUG: Classified '${document.name}' -> Topic $topicNumber");
      }

      _assignToTopic(document, topicNumber);

    } catch (e) {
      print('Error classifying file: $e');
      // Fallback on error -> Others
      _assignToTopic(document, 99);
    }
  }

  /// Helper to assign topic and save
  void _assignToTopic(DocumentModel document, int topicNumber) {
    // Generate a name if we don't have one (e.g. if model predicts Topic 45)
    final topicName = _topicNames[topicNumber] ?? 'Topic $topicNumber';

    // Cache the name so it persists in the UI
    if (!_topicNames.containsKey(topicNumber)) {
      _topicNames[topicNumber] = topicName;
    }

    // Update Document Model
    document.topicNumber = topicNumber;
    document.topicName = topicName;

    // Update Mappings
    _tagMapping?.fileToTopics
        .putIfAbsent(document.path, () => [])
        .add(topicNumber);

    if (_tagMapping?.topicToFiles.containsKey(topicNumber) != true) {
      _tagMapping?.topicToFiles[topicNumber] = {};
    }
    _tagMapping?.topicToFiles[topicNumber]!.add(document.path);

    // Update the mapping object reference
    _tagMapping = FileTagMapping(
        fileToTopics: _tagMapping!.fileToTopics,
        topicNames: _topicNames,
        topicToFiles: _tagMapping!.topicToFiles
    );

    _saveTagMapping();
    notifyListeners();
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