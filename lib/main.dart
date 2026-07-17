import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/home_screen.dart';
import 'services/app_state.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.instance.initialize();
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(prefs),
      child: const ShortsAutoNextApp(),
    ),
  );
}

class ShortsAutoNextApp extends StatelessWidget {
  const ShortsAutoNextApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeSetting = context.watch<AppState>().settings.theme;

    return MaterialApp(
      title: 'YouTube Shorts Auto Next Pro',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: AppTheme.themeModeFromSetting(themeSetting),
      home: const HomeScreen(),
    );
  }
}
