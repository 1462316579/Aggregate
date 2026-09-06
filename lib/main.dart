import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/source_provider.dart';
import 'screens/main_page.dart';
import 'services/app_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppConfig.init();
  runApp(const HongXiApp());
}

class HongXiApp extends StatelessWidget {
  const HongXiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: AppConfig.themeNotifier,
      builder: (context, theme, _) => ChangeNotifierProvider(
        create: (_) => SourceProvider()..init(),
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
