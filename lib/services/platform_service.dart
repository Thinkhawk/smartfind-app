import 'package:flutter/services.dart';

/// PlatformService - Native platform operations
///
/// Handles Android-specific operations like opening settings
class PlatformService {
  static const MethodChannel _channel = MethodChannel('com.example.smartfind/permissions');

  /// Open "All files access" permission settings on Android 11+
  ///
  /// Returns true if settings were opened successfully
  Future<bool> openAllFilesAccessSettings() async {
    try {
      final result = await _channel.invokeMethod('openAllFilesAccessSettings');
      return result as bool;
    } on PlatformException catch (e) {
      print("Failed to open settings: ${e.message}");
      return false;
    }
  }
}
