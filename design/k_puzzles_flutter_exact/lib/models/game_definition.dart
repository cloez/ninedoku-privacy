import 'package:flutter/material.dart';

@immutable
class GameDefinition {
  const GameDefinition({
    required this.id,
    required this.order,
    required this.title,
    required this.subtitle,
    required this.tagline,
    required this.description,
    required this.rules,
    required this.iconAsset,
    required this.primary,
    required this.secondary,
    required this.surface,
    this.isNew = false,
  });

  final String id;
  final int order;
  final String title;
  final String subtitle;
  final String tagline;
  final String description;
  final List<String> rules;
  final String iconAsset;
  final Color primary;
  final Color secondary;
  final Color surface;
  final bool isNew;
}
