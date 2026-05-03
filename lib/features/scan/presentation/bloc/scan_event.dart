import 'package:equatable/equatable.dart';
import '../../data/receipt_capture_service.dart';

abstract class ScanEvent extends Equatable {
  const ScanEvent();
  @override
  List<Object?> get props => [];
}

/// Open camera or gallery, run OCR, parse, transition to ScanParsed.
class CaptureRequested extends ScanEvent {
  final CaptureSource source;
  const CaptureRequested(this.source);
  @override
  List<Object?> get props => [source];
}

/// Reset back to idle (used by "Retake" button).
class RetakeRequested extends ScanEvent {
  const RetakeRequested();
}
