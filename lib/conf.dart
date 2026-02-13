import 'dart:async';
import 'package:ara_dict/data.dart';
import 'package:ara_dict/theme.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class AppSettingsController extends ChangeNotifier {
  static const _themeKey = 'theme_mode';
  static const _fontKey = 'ar_font_size';

  late double fontSize;
  late ThemeMode theme;
  final wake = _WakelockController();

  /// Load saved theme & font size from memory
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    final mode = prefs.getString(_themeKey);
    theme = mode == 'dark' ? ThemeMode.dark : ThemeMode.light;

    fontSize = prefs.getDouble(_fontKey) ?? defaultArabicFontSize;

    await wake.load();
  }

  Future<void> saveTheme(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    theme = mode;
    notifyListeners();
    prefs.setString(_themeKey, mode == ThemeMode.dark ? 'dark' : 'light');
  }

  Future<void> setFontSize(double size) async {
    fontSize = size;
    final prefs = await SharedPreferences.getInstance();
    notifyListeners();
    prefs.setDouble(_fontKey, size);
  }

  TextStyle getArabicTextStyle(BuildContext context) {
    return Theme.of(context).textTheme.bodyMedium!.copyWith(
      fontFamily: fontKitab,
      fontSize: fontSize,
      height: 1.5,
    );
  }
}

class _WakelockController {
  static const _wakeLockKey = 'wakeLock_enabled';
  static bool _enabled = true;

  static const Duration _timeout = Duration(minutes: 7);
  static Timer? _timer;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    tougle(enable: prefs.getBool(_wakeLockKey) ?? true);
  }

  bool isEnabled() {
    return _enabled;
  }

  void tougle({bool? enable}) async {
    _enabled = enable ?? !_enabled;

    final prefs = await SharedPreferences.getInstance();
    if (_enabled) {
      try {
        await WakelockPlus.enable();
      } catch (_) {
        _enabled = false;
      }
      _resetTimer();
      await prefs.setBool(_wakeLockKey, true);
    } else {
      await WakelockPlus.disable();
      _timer?.cancel();
      await prefs.setBool(_wakeLockKey, false);
    }
  }

  Future<void> onUserActivity(PointerEvent? _) async {
    if (_enabled) {
      await WakelockPlus.enable();
      _resetTimer();
    }
  }

  static void _resetTimer() {
    _timer?.cancel();
    _timer = Timer(_timeout, () {
      WakelockPlus.disable();
    });
  }
}
