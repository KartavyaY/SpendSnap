import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/groq_receipt_parser.dart';
import '../../data/ocr_service.dart';
import '../../data/receipt_capture_service.dart';
import 'scan_event.dart';
import 'scan_state.dart';

class ScanBloc extends Bloc<ScanEvent, ScanState> {
  final ReceiptCaptureService _capture;
  final OcrService _ocr;
  final GroqReceiptParser _parser;

  ScanBloc(this._capture, this._ocr, this._parser)
      : super(const ScanIdle()) {
    on<CaptureRequested>(_onCapture);
    on<RetakeRequested>((_, emit) => emit(const ScanIdle()));
  }

  // Minimum time to show the print animation — long enough to see it,
  // short enough not to feel sluggish. Work runs at full speed; we only
  // pad if it finishes early.
  static const _kMinDisplayMs = 1500;

  Future<void> _onCapture(
    CaptureRequested event,
    Emitter<ScanState> emit,
  ) async {
    File? file;
    try {
      file = await _capture.capture(event.source);
      if (file == null) {
        emit(const ScanIdle());
        return;
      }

      emit(ScanProcessing(file));
      final sw = Stopwatch()..start();

      String rawText;
      try {
        rawText = await _ocr.processImage(file);
      } on PlatformException catch (e) {
        await file.delete().catchError((_) {});
        emit(ScanError(
            "Couldn't read this image. Try again with better lighting. (${e.code})"));
        return;
      }

      final result = await _parser.parse(rawText);

      final remaining = _kMinDisplayMs - sw.elapsedMilliseconds;
      if (remaining > 0) {
        await Future.delayed(Duration(milliseconds: remaining));
      }

      // file held by ReceiptReviewCard until widget disposes
      emit(ScanParsed(result, file));
    } catch (e) {
      await file?.delete().catchError((_) {});
      emit(ScanError('Something went wrong: $e'));
    }
  }
}
