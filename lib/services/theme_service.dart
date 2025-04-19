import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});

class ThemeNotifier extends StateNotifier<ThemeMode> {
  static const _key = 'theme_mode';
  ThemeNotifier() : super(ThemeMode.light) {  // Start with light theme by default
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeIndex = prefs.getInt(_key);
      if (themeIndex != null) {
        state = ThemeMode.values[themeIndex];
      }
    } catch (e) {
      debugPrint('Error loading theme: $e');
    }
  }

  Future<void> toggleTheme() async {
    try {
      final newState = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
      state = newState;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_key, newState.index);
    } catch (e) {
      debugPrint('Error saving theme: $e');
    }
  }
} 