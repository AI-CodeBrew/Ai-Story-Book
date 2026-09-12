import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Lightweight on-device error log. No external crash-reporting account is
/// wired up (Firebase Crashlytics / Sentry would need project credentials
/// this app doesn't have yet) — this keeps the last few crashes in local
/// storage so they're at least visible from Settings after the fact.
class CrashLogService {
  static const _key = 'crash_log_entries';
  static const _maxEntries = 50;

  static void init() {
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      _record(details.exceptionAsString(), details.stack);
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      _record(error.toString(), stack);
      return true;
    };
  }

  /// For errors caught outside the Flutter/platform-dispatcher hooks above,
  /// e.g. a runZonedGuarded handler around runApp.
  static void recordError(String message, StackTrace? stack) => _record(message, stack);

  static void _record(String message, StackTrace? stack) {
    // Fire-and-forget: logging itself must never throw or block the app.
    () async {
      try {
        final prefs = await SharedPreferences.getInstance();
        final entries = prefs.getStringList(_key) ?? [];
        final trimmedStack = (stack?.toString().split('\n') ?? const []).take(6).join('\n');
        entries.insert(0, '${DateTime.now().toIso8601String()} | $message\n$trimmedStack');
        if (entries.length > _maxEntries) {
          entries.removeRange(_maxEntries, entries.length);
        }
        await prefs.setStringList(_key, entries);
      } catch (_) {}
    }();
  }

  static Future<List<String>> getEntries() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key) ?? [];
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
