import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Sombre par défaut.
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.dark);
final localeProvider = StateProvider<Locale>((ref) => const Locale('fr'));
