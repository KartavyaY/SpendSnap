import 'dart:io';
import 'package:equatable/equatable.dart';
import '../../domain/parsed_receipt.dart';

abstract class ScanState extends Equatable {
  const ScanState();
  @override
  List<Object?> get props => [];
}

class ScanIdle extends ScanState {
  /// Optional message (e.g. "Camera access needed").
  final String? message;
  const ScanIdle({this.message});
  @override
  List<Object?> get props => [message];
}

class ScanProcessing extends ScanState {
  final File image;
  const ScanProcessing(this.image);
  @override
  List<Object?> get props => [image.path];
}

class ScanParsed extends ScanState {
  final ParsedReceipt result;
  final File image;
  const ScanParsed(this.result, this.image);
  @override
  List<Object?> get props => [result, image.path];
}

class ScanError extends ScanState {
  final String message;
  const ScanError(this.message);
  @override
  List<Object?> get props => [message];
}
