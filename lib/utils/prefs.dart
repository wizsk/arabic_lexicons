import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

/// Thrown when a stored value is read as the wrong type.
class PrefsTypeException implements Exception {
  final String key;
  final Type expected;
  final Type actual;

  const PrefsTypeException(this.key, this.expected, this.actual);

  @override
  String toString() =>
      'PrefsTypeException: "$key" is a $actual, requested as $expected';
}

/// File-backed JSON preferences. Load once, read synchronously from memory,
/// and persist every write atomically (temp file + rename) in order.
class Prefs {
  final File _file;
  final Map<String, Object> _values = {};

  Future<void> _writeQueue = Future<void>.value();
  Future<void>? _loading;
  bool _loaded = false;

  Prefs._(this._file);

  factory Prefs(String filePath) => Prefs._(File(filePath));

  /// Creates and loads the app's default preferences file.
  static Future<Prefs> al({
    final String fileName = ".arabic_lexcions_prefs.json",
  }) async {
    final dir = await getApplicationDocumentsDirectory();
    final prefs = Prefs(path.join(dir.path, fileName));
    await prefs.load();
    return prefs;
  }

  // ---------------------------------------------------------------- loading

  /// Reads the file into memory. Idempotent: concurrent and repeated calls
  /// share one load. A missing file yields empty prefs; a corrupt file is
  /// moved to `<name>.corrupt` and prefs start empty. An unreadable file
  /// (I/O error) rethrows, so a later write can't clobber data we failed
  /// to read; calling load() again retries.
  Future<void> load() {
    return _loading ??= _load().catchError((Object e, StackTrace s) {
      _loading = null; // allow retry
      Error.throwWithStackTrace(e, s);
    });
  }

  Future<void> _load() async {
    final loaded = <String, Object>{};
    try {
      if (await _file.exists()) {
        final raw = await _file.readAsString();
        if (raw.trim().isNotEmpty) {
          final decoded = jsonDecode(raw);
          if (decoded is! Map) {
            throw const FormatException('Root is not a JSON object');
          }
          for (final e in decoded.entries) {
            final v = _sanitize(e.value);
            if (e.key is String && v != null) loaded[e.key as String] = v;
          }
        }
      }
    } on FormatException {
      await _quarantine();
    }
    _values
      ..clear()
      ..addAll(loaded);
    _loaded = true;
  }

  Future<void> _quarantine() async {
    try {
      await _file.rename('${_file.path}.corrupt');
    } catch (_) {}
  }

  static Object? _sanitize(Object? v) {
    if (v is String || v is bool || v is int) return v;
    if (v is double) return v.isFinite ? v : null;
    if (v is List && v.every((e) => e is String)) {
      return List<String>.from(v);
    }
    return null; // unsupported type, dropped
  }

  void _ensureLoaded() {
    if (!_loaded) {
      throw StateError('Prefs not loaded. Call load() or use Prefs.al().');
    }
  }

  // ------------------------------------------------------------------ reads

  bool containsKey(String key) {
    _ensureLoaded();
    return _values.containsKey(key);
  }

  Set<String> get keys {
    _ensureLoaded();
    return Set.unmodifiable(_values.keys);
  }

  /// Raw value, or null if absent. Lists are returned unmodifiable.
  Object? get(String key) {
    _ensureLoaded();
    final v = _values[key];
    return v is List<String> ? List<String>.unmodifiable(v) : v;
  }

  /// Returns null if [key] is absent; throws [PrefsTypeException] if the
  /// stored value is not a [T].
  T? _typed<T>(String key) {
    final v = get(key);
    if (v == null) return null;
    if (v is T) return v as T;
    throw PrefsTypeException(key, T, v.runtimeType);
  }

  String? getString(String key) => _typed<String>(key);

  bool? getBool(String key) => _typed<bool>(key);

  int? getInt(String key) => _typed<int>(key);

  /// Accepts stored doubles and ints (an int widens to double).
  double? getDouble(String key) {
    final v = get(key);
    if (v == null) return null;
    if (v is num) return v.toDouble();
    throw PrefsTypeException(key, double, v.runtimeType);
  }

  List<String>? getStringList(String key) => _typed<List<String>>(key);

  // ----------------------------------------------------------------- writes

  Future<void> setString(String key, String? value) => _set(key, value);

  Future<void> setBool(String key, bool? value) => _set(key, value);

  Future<void> setInt(String key, int? value) => _set(key, value);

  Future<void> setDouble(String key, double? value) {
    if (value != null && !value.isFinite) {
      throw ArgumentError.value(value, 'value', 'Must be finite');
    }
    return _set(key, value);
  }

  Future<void> setStringList(String key, List<String>? value) =>
      _set(key, value == null ? null : List<String>.of(value));

  Future<void> remove(String key) => _set(key, null);

  Future<void> clear() {
    _ensureLoaded();
    if (_values.isEmpty) return _writeQueue;
    _values.clear();
    return _persist();
  }

  Future<void> _set(String key, Object? value) {
    _ensureLoaded();
    if (value == null) {
      if (_values.remove(key) == null) return _writeQueue; // nothing to remove
    } else {
      if (_same(_values[key], value)) return _writeQueue; // unchanged
      _values[key] = value;
    }
    return _persist();
  }

  /// Value equality that also compares type (Dart says `1 == 1.0`) and
  /// list contents.
  static bool _same(Object? a, Object? b) {
    if (a is List && b is List) {
      if (a.length != b.length) return false;
      for (var i = 0; i < a.length; i++) {
        if (a[i] != b[i]) return false;
      }
      return true;
    }
    return a.runtimeType == b.runtimeType && a == b;
  }

  /// Completes when all queued writes have hit disk. Never throws; await the
  /// future returned by a setter if you need to observe its error.
  Future<void> flush() => _writeQueue;

  // ------------------------------------------------------------ persistence

  Future<void> _persist() {
    final snapshot = jsonEncode(_values); // snapshot now, write in order
    final next = _writeQueue.then((_) => _writeAtomically(snapshot));
    _writeQueue = next.catchError(
      (_) {},
    ); // a failure must not block later writes
    return next; // caller still sees the error
  }

  Future<void> _writeAtomically(String contents) async {
    await _file.parent.create(recursive: true);
    final tmp = File('${_file.path}.tmp');
    await tmp.writeAsString(contents, flush: true);
    await tmp.rename(_file.path); // atomic replace on Android/Linux/iOS/macOS
  }
}
