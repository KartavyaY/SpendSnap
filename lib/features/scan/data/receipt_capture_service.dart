import 'dart:io';
import 'package:image_picker/image_picker.dart';

enum CaptureSource { camera, gallery }

/// Wraps `image_picker` for camera/gallery capture. Returns null if the
/// user cancels or denies permission.
class ReceiptCaptureService {
  final ImagePicker _picker;

  ReceiptCaptureService(this._picker);

  /// Capture a receipt photo. Image quality and max width tuned to keep
  /// memory usage low while preserving OCR accuracy.
  Future<File?> capture(CaptureSource source) async {
    final XFile? file = await _picker.pickImage(
      source: source == CaptureSource.camera
          ? ImageSource.camera
          : ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1920,
    );
    if (file == null) return null;
    return File(file.path);
  }
}
