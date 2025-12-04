import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrService {
  final _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  /// Extract text from an image file path
  Future<String?> extractText(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognizedText = await _textRecognizer.processImage(inputImage);

      // Clean up the text (remove extra newlines)
      String text = recognizedText.text;
      if (text.trim().isEmpty) return null;

      return text;
    } catch (e) {
      print('OCR Error for $imagePath: $e');
      return null;
    }
  }

  void dispose() {
    _textRecognizer.close();
  }
}