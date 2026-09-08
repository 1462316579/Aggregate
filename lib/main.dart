import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'providers/source_provider.dart';
import 'screens/main_page.dart';
import 'services/app_config.dart';
import 'services/app_services.dart';
import 'services/music_player_service.dart';
import 'l10n/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await AppConfig.init().timeout(const Duration(seconds: 5));
    await AppConfig.getSources().timeout(const Duration(seconds: 5));
  } catch (_) {}

  final appServices = AppServices(sourceReader: () => AppConfig.cachedSources);
  runApp(HongXiApp(appServices: appServices));
  Future<void>(() async {
    try {
      await appServices.startBuiltInServices();
    } catch (_) {}
  });
}

class HongXiApp extends StatelessWidget {
  final AppServices appServices;
  const HongXiApp({super.key, required this.appServices});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: AppConfig.themeNotifier,
      builder: (context, theme, _) => ValueListenableBuilder<String>(
        valueListenable: AppConfig.languageNotifier,
        builder: (context, language, _) {
          final strings = AppStrings.of(language);
          return MultiProvider(
            providers: [
              ChangeNotifierProvider<SourceProvider>(create: (_) => SourceProvider()..init()),
              ChangeNotifierProvider<MusicPlayerService>(create: (_) => MusicPlayerService()),
              Provider<AppServices>.value(value: appServices),
            ],
            child: MaterialApp(
              title: '宏曦聚合',
              debugShowCheckedModeBanner: false,
              locale: strings.locale,
              supportedLocales: AppStrings.supportedCodes.map((code) => AppStrings.of(code).locale).toList(),
              localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
                GlobalMaterialLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
              ],
              themeMode: _themeMode(theme),
              theme: _buildTheme(Brightness.light),
              darkTheme: _buildTheme(Brightness.dark),
              home: const MainPage(),
            ),
          );
        },
      ),
    );
  }

  ThemeMode _themeMode(String value) {
    if (value == 'light') return ThemeMode.light;
    if (value == 'dark' || value == 'black') return ThemeMode.dark;
    return ThemeMode.system;
  }

  ThemeData _buildTheme(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorSchemeSeed: const Color(0xff3f51b5),
      scaffoldBackgroundColor: dark ? const Color(0xff17181c) : const Color(0xfff7f7f7),
      appBarTheme: const AppBarTheme(centerTitle: false, elevation: 0),
      cardTheme: CardThemeData(
        elevation: 1,
        color: dark ? const Color(0xff24262b) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
