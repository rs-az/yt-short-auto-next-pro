class AppSettings {
  const AppSettings({
    this.enabled = true,
    this.delay = 0,
    this.customDelay = 0,
    this.skipLongVideos = 'disabled',
    this.randomDelay = false,
    this.navigationPriority = const ['keyboard', 'button', 'scroll'],
    this.maxRetries = 3,
    this.loggingEnabled = true,
    this.animationEnabled = true,
    this.notificationsEnabled = false,
    this.theme = 'system',
  });

  final bool enabled;
  final dynamic delay;
  final double customDelay;
  final String skipLongVideos;
  final bool randomDelay;
  final List<String> navigationPriority;
  final int maxRetries;
  final bool loggingEnabled;
  final bool animationEnabled;
  final bool notificationsEnabled;
  final String theme;

  static const defaultSettings = AppSettings();

  AppSettings copyWith({
    bool? enabled,
    dynamic delay,
    double? customDelay,
    String? skipLongVideos,
    bool? randomDelay,
    List<String>? navigationPriority,
    int? maxRetries,
    bool? loggingEnabled,
    bool? animationEnabled,
    bool? notificationsEnabled,
    String? theme,
  }) {
    return AppSettings(
      enabled: enabled ?? this.enabled,
      delay: delay ?? this.delay,
      customDelay: customDelay ?? this.customDelay,
      skipLongVideos: skipLongVideos ?? this.skipLongVideos,
      randomDelay: randomDelay ?? this.randomDelay,
      navigationPriority: navigationPriority ?? this.navigationPriority,
      maxRetries: maxRetries ?? this.maxRetries,
      loggingEnabled: loggingEnabled ?? this.loggingEnabled,
      animationEnabled: animationEnabled ?? this.animationEnabled,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      theme: theme ?? this.theme,
    );
  }

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'delay': delay is num ? delay : delay.toString(),
        'customDelay': customDelay,
        'skipLongVideos': skipLongVideos,
        'randomDelay': randomDelay,
        'navigationPriority': navigationPriority,
        'maxRetries': maxRetries,
        'loggingEnabled': loggingEnabled,
        'animationEnabled': animationEnabled,
        'notificationsEnabled': notificationsEnabled,
        'theme': theme,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    final priority = json['navigationPriority'];
    return AppSettings(
      enabled: json['enabled'] as bool? ?? true,
      delay: json['delay'] ?? 0,
      customDelay: (json['customDelay'] as num?)?.toDouble() ?? 0,
      skipLongVideos: json['skipLongVideos']?.toString() ?? 'disabled',
      randomDelay: json['randomDelay'] as bool? ?? false,
      navigationPriority: priority is List
          ? priority.map((e) => e.toString()).toList()
          : const ['keyboard', 'button', 'scroll'],
      maxRetries: json['maxRetries'] as int? ?? 3,
      loggingEnabled: json['loggingEnabled'] as bool? ?? true,
      animationEnabled: json['animationEnabled'] as bool? ?? true,
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? false,
      theme: json['theme']?.toString() ?? 'system',
    );
  }
}
