import 'dart:async';

import 'package:arabic_lexicons/change_logs.dart';
import 'package:arabic_lexicons/data.dart';
import 'package:arabic_lexicons/lex/isolate.dart';
import 'package:arabic_lexicons/pages/settings.dart';
import 'package:arabic_lexicons/pages/width_padd.dart';
import 'package:arabic_lexicons/play_rate.dart';
import 'package:arabic_lexicons/reader/settings_class.dart';
import 'package:arabic_lexicons/theme.dart';
import 'package:arabic_lexicons/utils.dart';
import 'package:arabic_lexicons/widgets/change_logs_widget.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

enum AppLang { en, ar }

// app lang
abstract final class L {
  static double? _fontSize;

  static double? get fontSize => _fontSize;

  static const _arUiFont = fontNotoSansArabic;

  static const _uiArTextStyle = TextStyle(fontFamily: _arUiFont);

  static TextStyle get arStyle => _uiArTextStyle;

  static TextStyle get arStyleSized =>
      TextStyle(fontFamily: _arUiFont, fontSize: fontSize);

  static bool _isAr = false;

  static void set(AppLang l) {
    _isAr = l == AppLang.ar; // slight optimization
  }

  // static bool get isAr => _current == AppLang.ar;
  static bool get isAr => _isAr;

  /// Pick
  static T p<T>(T en, T ar) => isAr ? ar : en;

  /// Pick
  static T pr<T>(T ar, T en) => isAr ? ar : en;

  static TextDirection get dir => isAr ? TextDirection.rtl : TextDirection.ltr;

  static Alignment get alignment =>
      isAr ? Alignment.topRight : Alignment.topLeft;

  static Alignment get alignmentCenterLR =>
      isAr ? Alignment.centerRight : Alignment.centerLeft;

  static TextStyle? style(TextStyle? ar, TextStyle? en) => isAr ? ar : en;

  static TextStyle? get arStyleIf => isAr ? _uiArTextStyle : null;

  static TextStyle get arStyleOrNew => isAr ? _uiArTextStyle : TextStyle();

  static String? get arFontIf => isAr ? _arUiFont : null;

  static String get arFont => _arUiFont;
}

extension TextStyleIfAr on TextStyle {
  TextStyle? get arIf => L.isAr ? copyWith(fontFamily: L._arUiFont) : this;

  TextStyle get ar => copyWith(fontFamily: L._arUiFont);
}

class AppSettingsController extends ChangeNotifier {
  static const _playRateKey = 'playRate';
  static const _appVersionKey = 'version';
  static const _firstRunKey = 'firstRun';
  static const _themeKey = 'theme_mode';
  static const _useHansLaneDefStyleKey = 'hl-style';
  static const _readerFontKey = 'ar_font_fam';
  static const _readerFontSizeKey = 'ar_font_size';
  static const _readerFontHeightKey = 'ar_font_hi';
  static const _seedColorKey = 'seedc';
  static const _lastRouteKey = 'route';
  static const _lastBookKey = 'book';
  static const _readerIsOpenLexiconDireclyKey = 'reader_db_pop';
  static const _showSearchSuggKey = 'searchSugg';
  static const _luwColoredKey = 'luwCol';
  static const _useMoreArabicKey = 'dictEn';
  static const _fullScreenKey = 'fscreen';
  static const _hideStatusbarKey = 'hideStatusB';
  static const _maxWidthKey = 'maxW';
  static const _paddingKey = 'padd';
  static const _hideAppbarKey = 'happb';
  static const _scrollLexSelectionKey = 'scroll-lex-sel';
  static const _scrollLexSelectionAutoScKey = 'scroll-lex-sel-auto';
  static const _readerScrollPersentKey = 'reader-sc-p';
  static const _arUiFontSizeKey = 'aruif';

  int _playRate = 0;
  int get playRatelastShown => _playRate;

  String _appVersion = '';

  static const bool _useHansLaneDefStyleDef = false;
  bool _useHansLaneDefStyle = _useHansLaneDefStyleDef;

  static const bool _firstRunDef = true;
  bool _firstRun = _firstRunDef;

  static const bool _fullScreenDef = true;
  bool _fullScreen = _fullScreenDef;

  double? _arUiFontSize;

  static const bool _hideStatusbarDef = false;
  bool _hideStatusbar = _hideStatusbarDef;

  static const int readerScrollPersentDef = 65;
  int _readerScrollPersent = readerScrollPersentDef;

  static const bool _scrollLexSelectionDef = false;
  bool _scrollLexSelection = _scrollLexSelectionDef;

  static const bool _scrollLexSelectionAutoScDef = true;
  bool _scrollLexSelectionAutoSc = _scrollLexSelectionAutoScDef;

  static const bool _hideAppbarDef = true;
  bool _hideAppbar = _hideAppbarDef;

  static const Color _seedColorDef = uiSeedColorDefualt;
  Color _seedColor = _seedColorDef;

  double _padding = ReaderPageSettings.paddingDef;
  double _maxWidth = ReaderPageSettings.maxWidthDef;

  static const String _readerFontDef = defaultReaderArabicFont;
  String _readerFont = _readerFontDef;

  static const double _readerFontSizeDef = defaultReaderArabicFontSize;
  double _readerFontSize = _readerFontSizeDef;

  double _readerFontHeight = defArabicFontHeihgt;

  static const bool _luwColoredDef = true;
  bool _luwColored = _luwColoredDef;

  static const ThemeMode _themeDef = ThemeMode.system;
  ThemeMode _theme = _themeDef;

  static const bool _readerIsOpenLexiconDireclyDef = false;
  bool _readerIsOpenLexiconDirecly = _readerIsOpenLexiconDireclyDef;

  static final String _lastRouteDef = routesToBeSavedInPref.first;
  String _lastRoute = _lastRouteDef;
  String _lastBook = '';

  static const bool _showSearchSuggDef = true;
  bool _showSearchSugg = _showSearchSuggDef;

  // static const bool _showResutlsDireclyDef = true;
  // bool _showResutlsDirecly = _showResutlsDireclyDef;

  // show dict names in the selection in english
  static const bool _useMoreArabicDef = false;
  bool _useMoreArabic = _useMoreArabicDef;

  // TextStyle _arabicts = TextStyle(
  //   fontFamily: fontKitab,
  //   fontSize: defaultArabicFontSize,
  //   height: arabicFontHeihgt,
  // );

  VoidCallback? _refetchLexResults;

  /// Load saved theme & font size from memory
  Future<void> load() async {
    WakelockController.load();

    final prefs = await SharedPreferences.getInstance();

    _theme = ThemeMode.values.firstWhere(
      (e) => e.name == prefs.getString(_themeKey),
      orElse: () => _themeDef,
    );

    final seedColorInt = prefs.getInt(_seedColorKey);
    _seedColor = seedColorInt == null ? _seedColorDef : Color(seedColorInt);

    _playRate = prefs.getInt(_playRateKey) ?? 0;

    _useHansLaneDefStyle =
        prefs.getBool(_useHansLaneDefStyleKey) ?? _useHansLaneDefStyleDef;

    _readerScrollPersent =
        prefs.getInt(_readerScrollPersentKey) ?? readerScrollPersentDef;

    _appVersion = prefs.getString(_appVersionKey) ?? '';

    _firstRun = prefs.getBool(_firstRunKey) ?? _firstRunDef;

    _fullScreen = prefs.getBool(_fullScreenKey) ?? _fullScreenDef;

    _hideStatusbar = prefs.getBool(_hideStatusbarKey) ?? _hideStatusbarDef;

    _scrollLexSelection =
        prefs.getBool(_scrollLexSelectionKey) ?? _scrollLexSelectionDef;

    _scrollLexSelectionAutoSc =
        prefs.getBool(_scrollLexSelectionAutoScKey) ??
        _scrollLexSelectionAutoScDef;

    _hideAppbar = prefs.getBool(_hideAppbarKey) ?? _hideAppbarDef;

    _readerFont = prefs.getString(_readerFontKey) ?? _readerFontDef;
    if (!arabicFonts.contains(_readerFont)) {
      _readerFont = defaultReaderArabicFont;
    }

    _readerFontSize = prefs.getDouble(_readerFontSizeKey) ?? _readerFontSizeDef;
    _readerFontHeight =
        prefs.getDouble(_readerFontHeightKey) ?? defArabicFontHeihgt;
    _maxWidth = prefs.getDouble(_maxWidthKey) ?? ReaderPageSettings.maxWidthDef;
    _padding = prefs.getDouble(_paddingKey) ?? ReaderPageSettings.paddingDef;

    _readerIsOpenLexiconDirecly =
        prefs.getBool(_readerIsOpenLexiconDireclyKey) ??
        _readerIsOpenLexiconDireclyDef;

    _lastRoute = prefs.getString(_lastRouteKey) ?? _lastRouteDef;
    _lastBook = prefs.getString(_lastBookKey) ?? '';

    _showSearchSugg = prefs.getBool(_showSearchSuggKey) ?? _showSearchSuggDef;

    _luwColored = prefs.getBool(_luwColoredKey) ?? _luwColoredDef;

    _arUiFontSize = prefs.getDouble(_arUiFontSizeKey);
    L._fontSize = _arUiFontSize;

    _useMoreArabic = prefs.getBool(_useMoreArabicKey) ?? _useMoreArabic;
    L.set(_useMoreArabic ? AppLang.ar : AppLang.en);

    await WakelockController.load();
  }

  Future<void> reset() async {
    final firstRunPopupState = _firstRun;
    final appVersion = _appVersion;
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    // don't want it to be shown again; if already shown
    _appVersion = appVersion;
    await prefs.setString(_appVersionKey, appVersion);
    await saveFirstRun(firstRunPopupState);

    await load();
    await WakelockController.load();

    touggleFullScreen();
    notify();
  }

  void notify() {
    notifyListeners();
  }

  Future<void> saveTheme(ThemeMode mode) async {
    if (mode == _theme) return;
    _theme = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, _theme.name);
  }

  Future<void> saveFirstRun(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    _firstRun = v;
    await prefs.setBool(_firstRunKey, v);
  }

  bool get firstRun {
    return _firstRun;
  }

  bool _playRatingShonOnce = false;
  Future<void> playRating(BuildContext context) async {
    if (!BuildInfo.isGPlayVersion || _playRatingShonOnce || _playRate == -1) {
      return;
    }
    _playRatingShonOnce = true;

    final pref = await SharedPreferences.getInstance();

    if (_playRate == 0) {
      await pref.setInt(_playRateKey, DateTime.now().millisecondsSinceEpoch);
      return;
    }

    final lastShown = DateTime.fromMillisecondsSinceEpoch(_playRate);

    final daysPassed = DateTime.now().difference(lastShown).inDays;

    if (daysPassed <= 7 || !context.mounted) return;

    final res = await showRatePromptBottomSheet(context);

    if (res == null || RatePromptResult.later == res) {
      await pref.setInt(_playRateKey, DateTime.now().millisecondsSinceEpoch);
      return;
    }

    if (res == RatePromptResult.never || res == RatePromptResult.done) {
      await pref.setInt(_playRateKey, -1);
      return;
    }

    await openRatingFlow();
    await pref.setInt(_playRateKey, -1);
  }

  static final _currentVersion = releases.first.version;
  Future<bool> showChangeChangelog(BuildContext context) async {
    if (_appVersion == _currentVersion) {
      return false;
    }

    await showWhatsNewSheet(context);

    final pref = await SharedPreferences.getInstance();
    _appVersion = _currentVersion;
    await pref.setString(_appVersionKey, _currentVersion);

    return true;
  }

  Future<void> saveUseHansLaneDefStyle(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    _useHansLaneDefStyle = v;
    await prefs.setBool(_useHansLaneDefStyleKey, v);
  }

  bool get useHansLaneDefRDStyle {
    return _useHansLaneDefStyle;
  }

  Future<void> saveReaderScrollPersent(int p) async {
    if (_readerScrollPersent == p) return;
    _readerScrollPersent = p;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_readerScrollPersentKey, p);
  }

  int get readerScrollPersent {
    return _readerScrollPersent;
  }

  Future<void> saveFullScreen(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    _fullScreen = v;
    touggleFullScreen();
    notify();
    await prefs.setBool(_fullScreenKey, v);
  }

  bool get fullScreen {
    return _fullScreen;
  }

  Future<void> saveHideStatusBar(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    _hideStatusbar = v;
    touggleFullScreen();
    notify();
    await prefs.setBool(_hideStatusbarKey, v);
  }

  bool get hideStatusbar {
    return _hideStatusbar;
  }

  Future<void> saveScrollLexSelection(bool v) async {
    _scrollLexSelection = v;
    notify();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_scrollLexSelectionKey, v);
  }

  bool get scrollLexSelection {
    return _scrollLexSelection;
  }

  Future<void> saveScrollLexSelectionAutoSc(bool v) async {
    _scrollLexSelectionAutoSc = v;
    notify();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_scrollLexSelectionAutoScKey, v);
  }

  bool get scrollLexSelectionAutoSc {
    return _scrollLexSelectionAutoSc;
  }

  Future<void> saveHideAppbar(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    _hideAppbar = v;
    notify();
    await prefs.setBool(_hideAppbarKey, v);
  }

  bool get hideAppbar {
    return _hideAppbar;
  }

  Future<void> saveReaderIsOpenLexiconDirecly(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    _readerIsOpenLexiconDirecly = v;
    await prefs.setBool(_readerIsOpenLexiconDireclyKey, v);
  }

  bool get readerIsOpenLexiconDirecly {
    return _readerIsOpenLexiconDirecly;
  }

  Future<void> saveShowSearchSugg(bool v) async {
    if (v == _showSearchSugg) return;
    _showSearchSugg = v;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showSearchSuggKey, v);

    if (v) await Isolates.initSugg();
    tryRefetchLexResults();
  }

  bool get showSearchSugg {
    return _showSearchSugg;
  }

  Future<void> saveLuwColored(bool v) async {
    _luwColored = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_luwColoredKey, v);
  }

  bool get luwColored => _luwColored;

  Future<void> saveUseMoreArabicToggle() async =>
      saveUseMoreArabic(!_useMoreArabic);

  Future<void> saveUseMoreArabic(bool v) async {
    if (v == _useMoreArabic) return;
    _useMoreArabic = v;
    L.set(_useMoreArabic ? AppLang.ar : AppLang.en);

    notify();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_useMoreArabicKey, v);
  }

  // bool get useMoreArabic => _useMoreArabic;

  Future<void> saveRoute(String r, {String bookHash = ''}) async {
    if (_lastRoute == r && _lastBook == bookHash) return;

    final prefs = await SharedPreferences.getInstance();
    if (routesToBeSavedInPref.contains(r)) {
      await prefs.setString(_lastRouteKey, r);
      _lastRoute = r;
    }

    if (bookHash.isEmpty) {
      if (_lastBook.isNotEmpty) await prefs.remove(_lastBookKey);
      _lastBook = '';
    } else {
      _lastBook = bookHash;
      await prefs.setString(_lastBookKey, bookHash);
    }

    if (kDebugMode) debugPrint('saved route: $_lastRoute :?: $_lastBook');
  }

  String get lastBook {
    return _lastBook;
  }

  String get lastRoute {
    if (routesToBeSavedInPref.contains(_lastRoute)) {
      return _lastRoute;
    }
    return routesToBeSavedInPref.first;
  }

  Future<void> setReaderAdjustments(ReaderAdjustData d) async {
    final pref = await SharedPreferences.getInstance();

    if (_readerFont != d.fontFam) {
      _readerFont = d.fontFam;
      pref.setString(_readerFontKey, _readerFont);
    }

    if (_readerFontSize != d.fontSize) {
      _readerFontSize = d.fontSize;
      pref.setDouble(_readerFontSizeKey, _readerFontSize);
    }

    if (_readerFontHeight != d.fontHeight) {
      _readerFontHeight = d.fontHeight;
      pref.setDouble(_readerFontHeightKey, _readerFontHeight);
    }

    if (_maxWidth != d.maxWidth) {
      _maxWidth = d.maxWidth;
      pref.setDouble(_maxWidthKey, _maxWidth);
    }

    if (_padding != d.padding) {
      _padding = d.padding;
      pref.setDouble(_paddingKey, _padding);
    }

    notify();
  }

  Future<void> setArUiFontSize(double? size) async {
    if (_arUiFontSize == size) return;
    _arUiFontSize = size;
    L._fontSize = size;

    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    if (size != null) {
      await prefs.setDouble(_arUiFontSizeKey, size);
    } else {
      await prefs.remove(_arUiFontSizeKey);
    }
  }

  Future<void> setReaderFont(String font) async {
    if (_readerFont == font) return;
    if (!arabicFonts.contains(font)) return;

    _readerFont = font;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_readerFontKey, font);
  }

  Future<void> setReaderFontSize(double size) async {
    if (_readerFontSize == size) return;
    _readerFontSize = size;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_readerFontSizeKey, size);
  }

  double get maxWidth => _maxWidth;

  Future<void> setMaxWidth(double size) async {
    if (_maxWidth == size) return;
    _maxWidth = size;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_maxWidthKey, size);
  }

  double get padding => _padding;
  Future<void> setPadding(double size) async {
    if (_padding == size) return;
    _padding = size;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_paddingKey, size);
  }

  Color get seedColor => _seedColor;

  Future<void> setSeedColor(Color c) async {
    if (c == _seedColor) return;
    _seedColor = c;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_seedColorKey, c.toARGB32());
  }

  String get readerFont {
    return _readerFont;
  }

  double get readerFontSize {
    return _readerFontSize;
  }

  double get readerFontHeight {
    return _readerFontHeight;
  }

  ThemeMode get theme {
    return _theme;
  }

  EdgeInsets readerPadd(BuildContext context) =>
      readerPadding(context, maxWidth: _maxWidth, sidePadd: _padding);

  /// Reader Text Style
  TextStyle readerTS(BuildContext context) => TextStyle(
    fontFamily: _readerFont,
    fontSize: _readerFontSize,
    height: _readerFontHeight,
    color: Theme.of(context).brightness == Brightness.light
        ? readerColorsLight.onSurface
        : readerColorsDark.onSurface,
    fontFamilyFallback: [fontKitab, fontNotoSansArabic],
  );

  /// Reader Surface Color
  Color readerSurface(BuildContext context) =>
      Theme.of(context).brightness == Brightness.light
      ? readerColorsLight.surface
      : readerColorsDark.surface;

  set refetchLexResultsFunc(VoidCallback f) {
    _refetchLexResults = f;
  }

  void rmRefetchLexResultsFunc() {
    _refetchLexResults = null;
  }

  void tryRefetchLexResults() {
    _refetchLexResults?.call();
  }
}

const durationToScreenWake = 7;

class WakelockController {
  static const _wakeLockKey = 'wakeLock';
  static bool _enabled = true;

  static const Duration _timeout = Duration(minutes: durationToScreenWake);
  static Timer? _timer;

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool(_wakeLockKey) ?? true;
    toggle();
  }

  static bool get isEnabled {
    return _enabled;
  }

  static Future<void> saveWakeLock(bool enable) async {
    _enabled = enable;
    toggle();
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool(_wakeLockKey, enable);
    appConf.notify();
  }

  static Future<void> toggle() async {
    if (_enabled) {
      try {
        await WakelockPlus.enable();
      } catch (_) {}
      _resetTimer();
    } else {
      await WakelockPlus.disable();
      _timer?.cancel();
      // _timeRemmingTimer?.cancel();
    }
  }

  static Timer? _bounce;

  // static Future<void> onUserActivity(PointerEvent? _) async {
  static void onUserActivity(PointerEvent? _) {
    _bounce?.cancel();
    _bounce = Timer(const Duration(seconds: 2), _onUserActivity);
  }

  static Future<void> _onUserActivity() async {
    if (!_enabled) return;

    if (!await WakelockPlus.enabled) await WakelockPlus.enable();
    _resetTimer();

    if (kDebugMode) {
      debugPrint('wakelock refreshed, ${await WakelockPlus.enabled}');
    }
  }

  // static int _timeRemming = 0;
  // static Timer? _timeRemmingTimer;

  static void _resetTimer() {
    _timer?.cancel();
    _timer = Timer(_timeout, () {
      WakelockPlus.disable();
    });

    // if (kDebugMode) {
    //   _timeRemmingTimer?.cancel();
    //   _timeRemming = _timeout.inSeconds;
    //   _timeRemmingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
    //     debugPrint("$_timeRemming");
    //     _timeRemming--;
    //   });
    // }
  }
}
