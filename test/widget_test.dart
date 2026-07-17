import 'package:flutter_test/flutter_test.dart';
import 'package:youtube_shorts_auto_next/models/app_settings.dart';
import 'package:youtube_shorts_auto_next/models/watch_stats.dart';

void main() {
  test('AppSettings round-trip json', () {
    const settings = AppSettings(
      enabled: false,
      delay: 'custom',
      customDelay: 2.5,
      skipLongVideos: '60',
      randomDelay: true,
      navigationPriority: ['scroll', 'keyboard', 'button'],
      maxRetries: 5,
      notificationsEnabled: true,
      theme: 'dark',
    );

    final restored = AppSettings.fromJson(settings.toJson());
    expect(restored.enabled, false);
    expect(restored.delay, 'custom');
    expect(restored.customDelay, 2.5);
    expect(restored.navigationPriority, ['scroll', 'keyboard', 'button']);
    expect(restored.theme, 'dark');
  });

  test('WatchStats defaults to today', () {
    final stats = WatchStats.empty();
    expect(stats.date, WatchStats.todayKey());
    expect(stats.watchedCount, 0);
  });
}
