import 'package:equatable/equatable.dart';

enum InsightType { warning, observation, achievement, projection }

enum InsightSeverity { info, low, medium, high }

class Insight extends Equatable {
  final String id;
  final InsightType type;
  final InsightSeverity severity;
  final String title;
  final String description;
  final String? actionLabel;
  final String? actionRoute;
  final DateTime generatedAt;

  const Insight({
    required this.id,
    required this.type,
    required this.severity,
    required this.title,
    required this.description,
    this.actionLabel,
    this.actionRoute,
    required this.generatedAt,
  });

  @override
  List<Object?> get props =>
      [id, type, severity, title, description, generatedAt];
}
