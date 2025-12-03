/// FileTagMapping - Maps files to topics/tags
///
/// Maintains bidirectional mapping:
/// - File path → List of topic numbers
/// - Topic number → Set of file paths
class FileTagMapping {
  final Map<String, List<int>> fileToTopics;    // path -> [topic_numbers]
  final Map<int, String> topicNames;            // topic_number -> topic_name
  final Map<int, Set<String>> topicToFiles;     // topic_number -> {paths}

  FileTagMapping({
    required this.fileToTopics,
    required this.topicNames,
    required this.topicToFiles,
  });

  /// Get all topics that have at least one file
  Set<int> getVisibleTopics() {
    return topicToFiles.keys
        .where((topic) => topicToFiles[topic]!.isNotEmpty)
        .toSet();
  }

  /// Get all files tagged with a specific topic
  List<String> getFilesForTopic(int topicNumber) {
    return topicToFiles[topicNumber]?.toList() ?? [];
  }

  /// Get topic count (number of files in topic)
  int getTopicFileCount(int topicNumber) {
    return topicToFiles[topicNumber]?.length ?? 0;
  }

  /// Create from CSV content
  ///
  /// CSV format: path,topic_number
  factory FileTagMapping.fromCsv(String csvContent, Map<int, String> topicMap) {
    final Map<String, List<int>> fileToTopics = {};
    final Map<int, Set<String>> topicToFiles = {};

    final lines = csvContent.split('\n');

    // Skip header line
    for (int i = 1; i < lines.length; i++) {
      final parts = lines[i].trim().split(',');

      if (parts.length >= 2) {
        final path = parts[0].trim();
        final topic = int.tryParse(parts[1].trim());

        if (topic != null && path.isNotEmpty) {
          // Add to file -> topics mapping
          fileToTopics.putIfAbsent(path, () => []).add(topic);

          // Add to topic -> files mapping
          topicToFiles.putIfAbsent(topic, () => {}).add(path);
        }
      }
    }

    return FileTagMapping(
      fileToTopics: fileToTopics,
      topicNames: topicMap,
      topicToFiles: topicToFiles,
    );
  }

  /// Convert to CSV string for storage
  String toCsv() {
    final buffer = StringBuffer('file_path,topic_number\n');

    fileToTopics.forEach((path, topics) {
      for (final topic in topics) {
        buffer.writeln('$path,$topic');
      }
    });

    return buffer.toString();
  }
}
