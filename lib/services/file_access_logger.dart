import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/document_model.dart';

/// FileAccessLogger - Logs file access events for recommendation training
///
/// Maintains a CSV log of when files are accessed to train the recommender model
class FileAccessLogger {
  static const String _logFileName = 'access_log.csv';

  /// Get path to access log file
  Future<String> get _logPath async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/$_logFileName';
  }

  /// Initialize log file with headers if it doesn't exist
  Future<void> initialize() async {
    final path = await _logPath;
    final file = File(path);

    if (!await file.exists()) {
      await file.writeAsString('file_path,file_name,file_type,access_timestamp\n');
    }
  }

  /// Log a file access event
  Future<void> logAccess(DocumentModel document) async {
    try {
      final path = await _logPath;
      final file = File(path);

      final timestamp = DateTime.now().toIso8601String();
      final entry = '${document.path},${document.name},${document.type},$timestamp\n';

      // Append to log file
      await file.writeAsString(entry, mode: FileMode.append);
    } catch (e) {
      print('Error logging access: $e');
    }
  }

  /// Get the log file path (for training recommender)
  Future<String> getLogPath() async {
    return await _logPath;
  }

  /// Clear the access log
  Future<void> clearLog() async {
    try {
      final path = await _logPath;
      final file = File(path);
      await file.writeAsString('file_path,file_name,file_type,access_timestamp\n');
    } catch (e) {
      print('Error clearing log: $e');
    }
  }

  /// Get log entry count
  Future<int> getLogCount() async {
    try {
      final path = await _logPath;
      final file = File(path);

      if (!await file.exists()) return 0;

      final lines = await file.readAsLines();
      return lines.length - 1; // Subtract header
    } catch (e) {
      print('Error getting log count: $e');
      return 0;
    }
  }
}
