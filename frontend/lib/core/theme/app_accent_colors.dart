import 'package:flutter/material.dart';

class AppAccentColor {
  final String id;
  final String label;
  final Color color;
  final Color subtle;
  final Color subtleDark;

  const AppAccentColor({
    required this.id,
    required this.label,
    required this.color,
    required this.subtle,
    required this.subtleDark,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppAccentColor &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

const AppAccentColor kDefaultAccent = AppAccentColor(
  id: 'indigo',
  label: 'Indigo Blue',
  color: Color(0xFF4F6EF7),
  subtle: Color(0x1A4F6EF7),
  subtleDark: Color(0x264F6EF7),
);

const List<AppAccentColor> kAccentPresets = [
  kDefaultAccent,
  AppAccentColor(
    id: 'violet',
    label: 'Violet',
    color: Color(0xFF7C3AED),
    subtle: Color(0x1A7C3AED),
    subtleDark: Color(0x267C3AED),
  ),
  AppAccentColor(
    id: 'teal',
    label: 'Teal',
    color: Color(0xFF0D9488),
    subtle: Color(0x1A0D9488),
    subtleDark: Color(0x260D9488),
  ),
  AppAccentColor(
    id: 'rose',
    label: 'Rose',
    color: Color(0xFFE11D48),
    subtle: Color(0x1AE11D48),
    subtleDark: Color(0x26E11D48),
  ),
  AppAccentColor(
    id: 'amber',
    label: 'Amber Gold',
    color: Color(0xFFD97706),
    subtle: Color(0x1AD97706),
    subtleDark: Color(0x26D97706),
  ),
  AppAccentColor(
    id: 'orange',
    label: 'Vibrant Orange',
    color: Color(0xFFFF6B00),
    subtle: Color(0x1AFF6B00),
    subtleDark: Color(0x26FF6B00),
  ),
];
