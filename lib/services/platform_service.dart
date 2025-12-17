import 'package:flutter/services.dart';

class PlatformService {
  static const MethodChannel _channel =
      MethodChannel('com.example.smartfind/permissions');

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
