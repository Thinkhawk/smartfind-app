import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import '../models/file_tag_model.dart';
import '../models/document_model.dart';
import '../services/ml_service.dart';

/// TagProvider - Manages file-to-topic mappings
/// Uses a Hybrid approach: Extension Check (for Code) + ML Model (for Docs)
class TagProvider with ChangeNotifier {
  final MLService _mlService = MLService();

  FileTagMapping? _tagMapping;
  Map<String, String> _topicNames = {};
  bool _isLoading = false;

  FileTagMapping? get tagMapping => _tagMapping;
  bool get isLoading => _isLoading;

  // RESTORED: This getter was missing
  Set<int> get visibleTopics => _tagMapping?.getVisibleTopics() ?? {};

  /// Load topic names from local JSON asset
  Future<void> loadTopicNames() async {
    try {
      final jsonString = await rootBundle.loadString('assets/topic_map.json');
      final Map<String, dynamic> jsonMap = json.decode(jsonString);

      _topicNames = jsonMap.map((key, value) => MapEntry(key, value.toString()));
      notifyListeners();
    } catch (e) {
      print('Error loading topic map: $e');
      _topicNames = {"default": "General"};
    }
  }

  /// Load tag mapping from CSV file
  Future<void> loadTagMapping() async {
    _isLoading = true;
    notifyListeners();

    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/file_tags.csv');

      // Convert String map to Int map for the FileTagMapping model
      final Map<int, String> intTopicMap = {};
      _topicNames.forEach((key, value) {
        final intKey = int.tryParse(key);
        if (intKey != null) {
          intTopicMap[intKey] = value;
        }
      });

      // Ensure "Programming" exists in the map for our manual override
      intTopicMap[9999] = "Programming";
      intTopicMap[100] = "Others"; // Default fallback

      if (await file.exists()) {
        final csvContent = await file.readAsString();
        _tagMapping = FileTagMapping.fromCsv(csvContent, intTopicMap);
      } else {
        _tagMapping = FileTagMapping(
          fileToTopics: {},
          topicNames: intTopicMap,
          topicToFiles: {},
        );
      }
    } catch (e) {
      print('Error loading tag mapping: $e');
      _tagMapping = FileTagMapping(
        fileToTopics: {},
        topicNames: {},
        topicToFiles: {},
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Classify and tag a document
  Future<void> classifyAndTagFile(DocumentModel document) async {

    // --- 1. EXTENSION SAFETY NET ---
    // ML models trained on News often fail on Code. We force a tag here.
    final ext = document.type.toLowerCase();
    const codeExtensions = ['py', 'java', 'cpp', 'js', 'html', 'css', 'dart', 'c', 'h', 'xml', 'json', 'sql', 'php', 'rb', 'go', 'kt', 'swift'];

    if (codeExtensions.contains(ext)) {
      print("DEBUG: Detected code extension '$ext'. Forcing 'Programming' tag.");
      _assignToTopic(document, 9999, forceName: "Programming");
      return;
    }

    // --- 2. ML CLASSIFICATION ---
    try {
      final content = await _mlService.readFile(document.path);

      if (content == null || content.isEmpty) {
        _assignToTopic(document, 100); // "General" / Others
        return;
      }

      final result = await _mlService.classifyFile(content);
      int topicNumber = result['topic_number'] ?? -1;

      // Handle Invalid/Low Confidence
      if (topicNumber == -1) {
        topicNumber = 100;
      }

      _assignToTopic(document, topicNumber);

    } catch (e) {
      print('Error classifying file: $e');
      _assignToTopic(document, 100);
    }
  }

  void _assignToTopic(DocumentModel document, int topicNumber, {String? forceName}) {
    // 1. Determine Name
    String topicName;

    if (forceName != null) {
      topicName = forceName;
    } else {
      topicName = _topicNames[topicNumber.toString()] ??
          _topicNames['default'] ??
          'General';
    }

    // 2. Update Document
    document.topicNumber = topicNumber;
    document.topicName = topicName;

    // 3. Update Provider Data
    _tagMapping?.fileToTopics
        .putIfAbsent(document.path, () => [])
        .add(topicNumber);

    if (_tagMapping?.topicToFiles.containsKey(topicNumber) != true) {
      _tagMapping?.topicToFiles[topicNumber] = {};
    }
    _tagMapping?.topicToFiles[topicNumber]!.add(document.path);

    // Add to internal map if missing (for runtime display)
    if (!_topicNames.containsKey(topicNumber.toString())) {
      _topicNames[topicNumber.toString()] = topicName;
    }

    // 4. Save
    _saveTagMapping();
    notifyListeners();
  }

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

  List<String> getFilesForTopic(int topicNumber) {
    return _tagMapping?.getFilesForTopic(topicNumber) ?? [];
  }

  String getTopicName(int topicNumber) {
    if (topicNumber == 9999) return "Programming";
    return _topicNames[topicNumber.toString()] ?? 'General';
  }

  int getTopicFileCount(int topicNumber) {
    return _tagMapping?.getTopicFileCount(topicNumber) ?? 0;
  }
}