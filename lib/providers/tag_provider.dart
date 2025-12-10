import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import '../models/file_tag_model.dart';
import '../models/document_model.dart';
import '../services/ml_service.dart';

/// TagProvider - Manages file-to-topic mappings
///
/// UPDATED: Uses a Pure ML approach. All files are sent to the trained model
/// for classification. No hardcoded extension rules.
class TagProvider with ChangeNotifier {
  final MLService _mlService = MLService();

  FileTagMapping? _tagMapping;
  Map<String, String> _topicNames = {};
  bool _isLoading = false;

  FileTagMapping? get tagMapping => _tagMapping;
  bool get isLoading => _isLoading;

  Set<int> get visibleTopics => _tagMapping?.getVisibleTopics() ?? {};

  /// Load topic names from local JSON asset
  Future<void> loadTopicNames() async {
    try {
      // CHANGE THIS LINE: Load from 'assets/models/' where the python script saved it
      final jsonString = await rootBundle.loadString('assets/models/topic_map.json');
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

      // Default fallback
      intTopicMap[100] = "Others";

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

  /// Classify and tag a document using purely the ML Model
  Future<void> classifyAndTagFile(DocumentModel document) async {

    // --- ML CLASSIFICATION (Dynamic) ---
    // We send the content to Python. The Python 'classifier.py' script
    // uses the trained model (vectors) to decide the topic.
    try {
      final content = await _mlService.readFile(document.path);

      if (content == null || content.isEmpty) {
        print("DEBUG: Content empty for ${document.name}. Assigning to Others.");
        _assignToTopic(document, 100); // 100 = "Others" / Uncategorized
        return;
      }

      print("DEBUG: Sending '${document.name}' to ML Classifier...");

      final result = await _mlService.classifyFile(content);
      int topicNumber = result['topic_number'] ?? -1;
      double confidence = result['confidence'] ?? 0.0;

      // Filter Low Confidence if necessary
      if (topicNumber == -1 || confidence < 0.2) {
        // 0.2 is an example threshold. Adjust based on your model's performance.
        print("DEBUG: Low confidence ($confidence) for ${document.name}. Tagging as Others.");
        topicNumber = 100;
      } else {
        print("DEBUG: Classified ${document.name} -> Topic $topicNumber ($confidence)");
      }

      _assignToTopic(document, topicNumber);

    } catch (e) {
      print('Error classifying file ${document.name}: $e');
      _assignToTopic(document, 100); // Fail gracefully to Others
    }
  }

  void _assignToTopic(DocumentModel document, int topicNumber, {String? forceName}) {
    // 1. Determine Name
    String topicName;

    if (forceName != null) {
      topicName = forceName;
    } else {
      // Look up the ID in the JSON map we loaded earlier
      topicName = _topicNames[topicNumber.toString()] ??
          _topicNames['default'] ??
          'General';
    }

    // 2. Update Document Model
    document.topicNumber = topicNumber;
    document.topicName = topicName;

    // 3. Update Provider Data (In-Memory)
    _tagMapping?.fileToTopics
        .putIfAbsent(document.path, () => [])
        .add(topicNumber);

    if (_tagMapping?.topicToFiles.containsKey(topicNumber) != true) {
      _tagMapping?.topicToFiles[topicNumber] = {};
    }
    _tagMapping?.topicToFiles[topicNumber]!.add(document.path);

    // Add to internal map if missing (ensures UI shows correct name)
    if (!_topicNames.containsKey(topicNumber.toString())) {
      _topicNames[topicNumber.toString()] = topicName;
    }

    // 4. Persist to Storage
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
    return _topicNames[topicNumber.toString()] ?? 'General';
  }

  int getTopicFileCount(int topicNumber) {
    return _tagMapping?.getTopicFileCount(topicNumber) ?? 0;
  }
}