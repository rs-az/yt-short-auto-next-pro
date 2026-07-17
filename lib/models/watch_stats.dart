class WatchStats {
  const WatchStats({
    this.watchedCount = 0,
    this.skippedCount = 0,
    this.sessionDuration = 0,
    this.averageWatchTime = 0,
    this.totalWatchedSeconds = 0,
    required this.date,
  });

  final int watchedCount;
  final int skippedCount;
  final int sessionDuration;
  final int averageWatchTime;
  final double totalWatchedSeconds;
  final String date;

  static String todayKey() => DateTime.now().toIso8601String().split('T').first;

  static WatchStats empty() => WatchStats(date: todayKey());

  WatchStats copyWith({
    int? watchedCount,
    int? skippedCount,
    int? sessionDuration,
    int? averageWatchTime,
    double? totalWatchedSeconds,
    String? date,
  }) {
    return WatchStats(
      watchedCount: watchedCount ?? this.watchedCount,
      skippedCount: skippedCount ?? this.skippedCount,
      sessionDuration: sessionDuration ?? this.sessionDuration,
      averageWatchTime: averageWatchTime ?? this.averageWatchTime,
      totalWatchedSeconds: totalWatchedSeconds ?? this.totalWatchedSeconds,
      date: date ?? this.date,
    );
  }

  Map<String, dynamic> toJson() => {
        'watchedCount': watchedCount,
        'skippedCount': skippedCount,
        'sessionDuration': sessionDuration,
        'averageWatchTime': averageWatchTime,
        'totalWatchedSeconds': totalWatchedSeconds,
        'date': date,
      };

  factory WatchStats.fromJson(Map<String, dynamic> json) {
    return WatchStats(
      watchedCount: json['watchedCount'] as int? ?? 0,
      skippedCount: json['skippedCount'] as int? ?? 0,
      sessionDuration: json['sessionDuration'] as int? ?? 0,
      averageWatchTime: json['averageWatchTime'] as int? ?? 0,
      totalWatchedSeconds: (json['totalWatchedSeconds'] as num?)?.toDouble() ?? 0,
      date: json['date']?.toString() ?? todayKey(),
    );
  }
}
