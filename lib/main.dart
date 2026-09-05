import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:media_kit/media_kit.dart';
import 'providers/source_provider.dart';
import 'providers/player_provider.dart';
import 'services/app_config.dart';
import 'services/music_player_service.dart';
import 'screens/home/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  await AppConfig.init();
  runApp(const AllPlayApp());
}

class AllPlayApp extends StatelessWidget {
  const AllPlayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SourceProvider()..init()),
        ChangeNotifierProvider(create: (_) => PlayerProvider()),
        ChangeNotifierProvider(create: (_) => MusicPlayerService()),
      ],
      child: MaterialApp(
        title: '聚合影视',
        debugShowCheckedModeBanner: false,
        // 亦搜风格 — 浅色主题
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.light,
          primaryColor: const Color(0xFF2196F3),
          scaffoldBackgroundColor: const Color(0xFFF5F5F5),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
            iconTheme: IconThemeData(color: Color(0xFF333333)),
            titleTextStyle: TextStyle(
              color: Color(0xFF333333),
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          cardTheme: CardTheme(
            color: Colors.white,
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          bottomNavigationBarTheme: const BottomNavigationBarThemeData(
            backgroundColor: Colors.white,
            selectedItemColor: Color(0xFF2196F3),
            unselectedItemColor: Colors.grey,
            type: BottomNavigationBarType.fixed,
            elevation: 8,
          ),
          dividerTheme: const DividerThemeData(
            color: Color(0xFFEEEEEE),
            thickness: 0.5,
          ),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
