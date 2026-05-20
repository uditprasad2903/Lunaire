import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'themes/theme_provider.dart';
import 'services/auth_service.dart';
import 'services/diary_service.dart';
import 'services/settings_service.dart';
import 'services/sound_service.dart';
import 'services/haptic_service.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Initialize Firebase (uncomment after running `flutterfire configure`)
  // await Firebase.initializeApp();

  await Hive.initFlutter();
  await DiaryService.init();

  // Settings first — sound/haptic services need it.
  final settings = SettingsService();
  await settings.load();
  SoundService.attachSettings(settings);
  HapticService.attachSettings(settings);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settings),
        ChangeNotifierProvider(create: (_) => ThemeProvider()..loadTheme()),
        ChangeNotifierProvider(create: (_) => AuthService()),
      ],
      child: const LunaireApp(),
    ),
  );
}

class LunaireApp extends StatelessWidget {
  const LunaireApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return MaterialApp(
          title: 'Lunaire',
          debugShowCheckedModeBanner: false,
          navigatorKey: SoundService.navigatorKey,
          theme: themeProvider.currentTheme,
          home: const SplashScreen(),
        );
      },
    );
  }
}
