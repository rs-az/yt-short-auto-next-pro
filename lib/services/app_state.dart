import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_settings.dart';
import '../models/watch_stats.dart';
import 'notification_service.dart';

class AppState extends ChangeNotifier {
  AppState(this._prefs) {
    _settings = _loadSettings();
    _stats = _loadStats();
    _sessionStart = DateTime.now();
  }

  final SharedPreferences _prefs;
  static const _settingsKey = 'sync_settings';
  static const _statsKey = 'local_stats';

  late AppSettings _settings;
  late WatchStats _stats;
  late DateTime _sessionStart;

  AppSettings get settings => _settings;
  WatchStats get stats => _stats;

  AppSettings _loadSettings() {
    final raw = _prefs.getString(_settingsKey);
    if (raw == null) return AppSettings.defaultSettings;
    try {
      return AppSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return AppSettings.defaultSettings;
    }
  }

  WatchStats _loadStats() {
    final raw = _prefs.getString(_statsKey);
    if (raw == null) return WatchStats.empty();
    try {
      final stats = WatchStats.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      if (stats.date != WatchStats.todayKey()) {
        return WatchStats.empty();
      }
      return stats;
    } catch (_) {
      return WatchStats.empty();
    }
  }

  Future<void> _persistSettings() async {
    await _prefs.setString(_settingsKey, jsonEncode(_settings.toJson()));
    notifyListeners();
  }

  Future<void> _persistStats() async {
    await _prefs.setString(_statsKey, jsonEncode(_stats.toJson()));
    notifyListeners();
  }

  Future<void> updateSettings(AppSettings newSettings) async {
    _settings = newSettings;
    await _persistSettings();
  }

  Future<void> patchSettings(AppSettings Function(AppSettings current) patch) async {
    _settings = patch(_settings);
    await _persistSettings();
  }

  Future<void> resetStats() async {
    _stats = WatchStats.empty();
    _sessionStart = DateTime.now();
    await _persistStats();
  }

  Future<void> applyStatsFromBridge(Map<String, dynamic> payload) async {
    final today = WatchStats.todayKey();
    var stats = _stats.date == today ? _stats : WatchStats.empty();

    final type = payload['type']?.toString();
    if (type == 'watch') {
      final newWatchedCount = stats.watchedCount + 1;
      final seconds = (payload['secondsPlayed'] as num?)?.toDouble() ?? 0;
      final totalSeconds = stats.totalWatchedSeconds + seconds;
      stats = stats.copyWith(
        watchedCount: newWatchedCount,
        totalWatchedSeconds: totalSeconds,
        averageWatchTime: (totalSeconds / newWatchedCount).round(),
      );
    } else if (type == 'skip') {
      stats = stats.copyWith(skippedCount: stats.skippedCount + 1);
    }

    final sessionMinutes =
        DateTime.now().difference(_sessionStart).inMinutes;
    stats = stats.copyWith(sessionDuration: sessionMinutes);

    _stats = stats;
    await _persistStats();
  }

  Future<void> handleBridgeMessage(String rawMessage) async {
    try {
      final message = jsonDecode(rawMessage) as Map<String, dynamic>;
      switch (message['type']) {
        case 'UPDATE_STATS':
          await applyStatsFromBridge(
            message['payload'] as Map<String, dynamic>,
          );
        case 'SHOW_NOTIFICATION':
          if (_settings.notificationsEnabled) {
            await NotificationService.instance.showAdvanceNotification(
              message['text']?.toString() ??
                  'Playback finished. Advancing to next Short.',
            );
          }
        case 'LOG':
          if (_settings.loggingEnabled && kDebugMode) {
            debugPrint('[Auto Next Pro] ${message['text']}');
          }
      }
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Bridge message error: $error');
      }
    }
  }

  Future<Map<String, dynamic>> exportBackup() async {
    return {
      'sync': _settings.toJson(),
      'local': _stats.toJson(),
      'exportedAt': DateTime.now().toIso8601String(),
    };
  }

  Future<void> importBackup(Map<String, dynamic> backup) async {
    final sync = backup['sync'];
    if (sync is Map<String, dynamic>) {
      _settings = AppSettings.fromJson(sync);
      await _persistSettings();
    }

    final local = backup['local'];
    if (local is Map<String, dynamic>) {
      _stats = WatchStats.fromJson(local);
      await _persistStats();
    }
  }

  Future<void> factoryReset() async {
    _settings = AppSettings.defaultSettings;
    _stats = WatchStats.empty();
    _sessionStart = DateTime.now();
    await _prefs.remove(_settingsKey);
    await _prefs.remove(_statsKey);
    notifyListeners();
  }
}
