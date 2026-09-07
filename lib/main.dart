import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/source_provider.dart';
import 'screens/main_page.dart';
import 'services/app_config.dart';
import 'services/app_services.dart';
import 'services/music_player_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppConfig.init();
  await AppConfig.getSources();
  final appServices = AppServices(sourceReader: () => AppConfig.cachedSources);
  await appServices.startBuiltInServices();
  runApp(HongXiApp(appServices: appServices));
}

class HongXiApp extends StatelessWidget {
  final AppServices appServices;

  const HongXiApp({
    super.key,
    required this.appServices,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: AppConfig.themeNotifier,
      builder: (context, theme, _) => MultiProvider(
        providers: [
          ChangeNotifierProvider<SourceProvider>(create: (_) => SourceProvider()..init()),
          ChangeNotifierProvider<MusicPlayerService>(create: (_) => MusicPlayerService()),
          Provider<AppServices>.value(value: appServices),
        ],
        child: MaterialApp(
          title: '宏曦聚合',
          debugShowCheckedModeBanner: false,
          themeMode: _themeMode(theme),
          theme: _buildTheme(Brightness.light),
          darkTheme: _buildTheme(Brightness.dark),
          home: const MainPage(),
        ),
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
