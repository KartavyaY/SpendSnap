import 'dart:io';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:spendsnap/features/scan/data/groq_receipt_parser.dart';
import 'package:spendsnap/features/scan/data/ocr_service.dart';
import 'package:spendsnap/features/scan/data/receipt_capture_service.dart';
import 'package:spendsnap/features/scan/domain/parsed_receipt.dart';
import 'package:spendsnap/features/scan/presentation/bloc/scan_bloc.dart';
import 'package:spendsnap/features/scan/presentation/bloc/scan_event.dart';
import 'package:spendsnap/features/scan/presentation/bloc/scan_state.dart';

class _MockCapture extends Mock implements ReceiptCaptureService {}
class _MockOcr extends Mock implements OcrService {}
class _MockParser extends Mock implements GroqReceiptParser {}

class _MockFile extends Mock implements File {
  @override
  String get path => '/fake/path/image.jpg';

  @override
  Future<File> delete({bool recursive = false}) async {
    return this;
  }
}

void main() {
  late _MockCapture capture;
  late _MockOcr ocr;
  late _MockParser parser;

  setUpAll(() {
    registerFallbackValue(CaptureSource.camera);
  });

  setUp(() {
    capture = _MockCapture();
    ocr = _MockOcr();
    parser = _MockParser();
  });

  group('ScanBloc — initial state', () {
    test('initial state is ScanIdle', () {
      final bloc = ScanBloc(capture, ocr, parser);
      expect(bloc.state, isA<ScanIdle>());
      bloc.close();
    });
  });

  group('ScanBloc — RetakeRequested', () {
    blocTest<ScanBloc, ScanState>(
      'emits ScanIdle when RetakeRequested is added',
      build: () => ScanBloc(capture, ocr, parser),
      // To show it changes to Idle, start with something else? 
      // Actually BLoC doesn't have a way to seed state easily without using emit, 
      // but since it just emits Idle, we can expect it.
      act: (bloc) => bloc.add(const RetakeRequested()),
      expect: () => [isA<ScanIdle>()],
    );
  });

  group('ScanBloc — CaptureRequested', () {
    final mockFile = _MockFile();
    final parsedResult = ParsedReceipt(
      amount: 10.0,
      date: DateTime(2024, 1, 1),
      merchant: 'Store',
      categoryHint: 'food',
      rawText: 'Store 10.00',
      confidence: 1.0,
    );

    blocTest<ScanBloc, ScanState>(
      'emits ScanIdle when capture returns null (cancelled)',
      setUp: () {
        when(() => capture.capture(any())).thenAnswer((_) async => null);
      },
      build: () => ScanBloc(capture, ocr, parser),
      act: (bloc) => bloc.add(const CaptureRequested(CaptureSource.camera)),
      expect: () => [isA<ScanIdle>()],
    );

    blocTest<ScanBloc, ScanState>(
      'emits [ScanProcessing, ScanParsed] on full success',
      setUp: () {
        when(() => capture.capture(any())).thenAnswer((_) async => mockFile);
        when(() => ocr.processImage(mockFile)).thenAnswer((_) async => 'Store 10.00');
        when(() => parser.parse('Store 10.00')).thenAnswer((_) async => parsedResult);
      },
      build: () => ScanBloc(capture, ocr, parser),
      act: (bloc) => bloc.add(const CaptureRequested(CaptureSource.gallery)),
      wait: const Duration(milliseconds: 1600), // Account for _kMinDisplayMs
      expect: () => [
        isA<ScanProcessing>(),
        isA<ScanParsed>().having((s) => s.result.amount, 'amount', 10.0),
      ],
    );

    blocTest<ScanBloc, ScanState>(
      'emits [ScanProcessing, ScanError] when OCR throws PlatformException',
      setUp: () {
        when(() => capture.capture(any())).thenAnswer((_) async => mockFile);
        when(() => ocr.processImage(mockFile))
            .thenThrow(PlatformException(code: 'OCR_FAILED'));
      },
      build: () => ScanBloc(capture, ocr, parser),
      act: (bloc) => bloc.add(const CaptureRequested(CaptureSource.camera)),
      expect: () => [
        isA<ScanProcessing>(),
        isA<ScanError>().having((s) => s.message, 'message',
            contains('Couldn\'t read this image')),
      ],
    );

    blocTest<ScanBloc, ScanState>(
      'emits [ScanProcessing, ScanError] when generic exception occurs',
      setUp: () {
        when(() => capture.capture(any())).thenAnswer((_) async => mockFile);
        when(() => ocr.processImage(mockFile))
            .thenAnswer((_) async => throw Exception('Network error'));
      },
      build: () => ScanBloc(capture, ocr, parser),
      act: (bloc) => bloc.add(const CaptureRequested(CaptureSource.camera)),
      expect: () => [
        isA<ScanProcessing>(),
        isA<ScanError>().having(
            (s) => s.message, 'message', contains('Something went wrong:')),
      ],
    );
  });
}
