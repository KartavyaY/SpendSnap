import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Wraps Google ML Kit text recognition. Runs fully on-device.
class OcrService {
  final TextRecognizer _recognizer;

  OcrService(this._recognizer);

  /// Run OCR on an image file. Returns the raw concatenated text.
  /// Throws [PlatformException] from ML Kit on unsupported images.
  Future<String> processImage(File image) async {
    final input = InputImage.fromFile(image);
    final result = await _recognizer.processImage(input);
    return result.text;
  }

  /// Releases the native recognizer. Call only when fully done — singleton
  /// usage typically lets it live for the app lifetime.
  Future<void> dispose() => _recognizer.close();
}
