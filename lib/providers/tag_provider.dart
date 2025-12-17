import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import '../models/file_tag_model.dart';
import '../models/document_model.dart';
import '../services/ml_service.dart';

class TagProvider with ChangeNotifier {
  final MLService _mlService = MLService();

  FileTagMapping? _tagMapping;
  Map<String, String> _topicNames = {};
  bool _isLoading = false;

  FileTagMapping? get tagMapping => _tagMapping;

  bool get isLoading => _isLoading;

  Set<int> get visibleTopics => _tagMapping?.getVisibleTopics() ?? {};

  Future<void> loadTopicNames() async {
    try {
      // CHANGE THIS LINE: Load from 'assets/models/' where the python script saved it
      final jsonString =
          await rootBundle.loadString('assets/models/topic_map.json');
      final Map<String, dynamic> jsonMap = json.decode(jsonString);

      _topicNames =
          jsonMap.map((key, value) => MapEntry(key, value.toString()));
      notifyListeners();
    } catch (e) {
      print('Error loading topic map: $e');
      _topicNames = {"default": "General"};
    }
  }

  Future<void> loadTagMapping() async {
    _isLoading = true;
    notifyListeners();

    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/file_tags.csv');

      final Map<int, String> intTopicMap = {};
      _topicNames.forEach((key, value) {
        final intKey = int.tryParse(key);
        if (intKey != null) {
          intTopicMap[intKey] = value;
        }
      });

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

  Future<void> classifyAndTagFile(DocumentModel document) async {
    final codeExtensions = [
      'py',
      'dart',
      'java',
      'cpp',
      'c',
      'h',
      'js',
      'ts',
      'html',
      'css',
      'json',
      'xml',
      'yaml',
      'sh',
      'bat',
      'sql'
    ];

    if (codeExtensions.contains(document.type.toLowerCase())) {
      print("DEBUG: Heuristic match for ${document.name} -> Programming");

      int? programmingId;
      _topicNames.forEach((key, value) {
        if (value == "Programming") {
          programmingId = int.tryParse(key);
        }
      });

      if (programmingId != null) {
        _assignToTopic(document, programmingId!);
        return;
      }
    }

    try {
      final content = await _mlService.readFile(document.path);

      if (content == null || content.isEmpty) {
        print(
            "DEBUG: Content empty for ${document.name}. Assigning to Others.");
        _assignToTopic(document, 100); // 100 = "Others" / Uncategorized
        return;
      }

      print("DEBUG: Sending '${document.name}' to ML Classifier...");

      final result = await _mlService.classifyFile(content);
      int topicNumber = result['topic_number'] ?? -1;
      double confidence = result['confidence'] ?? 0.0;

      if (topicNumber == -1 || confidence < 0.2) {
        print(
            "DEBUG: Low confidence ($confidence) for ${document.name}. Tagging as Others.");
        topicNumber = 100;
      } else {
        print(
            "DEBUG: Classified ${document.name} -> Topic $topicNumber ($confidence)");
      }

      _assignToTopic(document, topicNumber);
    } catch (e) {
      print('Error classifying file ${document.name}: $e');
      _assignToTopic(document, 100);
    }
  }

  void _assignToTopic(DocumentModel document, int topicNumber,
      {String? forceName}) {
    String topicName;

    if (forceName != null) {
      topicName = forceName;
    } else {
      topicName = _topicNames[topicNumber.toString()] ??
          _topicNames['default'] ??
          'General';
    }

    document.topicNumber = topicNumber;
    document.topicName = topicName;

    _tagMapping?.fileToTopics
        .putIfAbsent(document.path, () => [])
        .add(topicNumber);

    if (_tagMapping?.topicToFiles.containsKey(topicNumber) != true) {
      _tagMapping?.topicToFiles[topicNumber] = {};
    }
    _tagMapping?.topicToFiles[topicNumber]!.add(document.path);

    if (!_topicNames.containsKey(topicNumber.toString())) {
      _topicNames[topicNumber.toString()] = topicName;
    }

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
