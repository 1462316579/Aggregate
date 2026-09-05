import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/source_provider.dart';
import 'screens/home/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SourceProvider()..init(),
      child: MaterialApp(
        title: '宏曦聚合',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true, brightness: Brightness.light,
          primaryColor: const Color(0xFF2196F3),
          scaffoldBackgroundColor: const Color(0xFFF5F5F5),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white, elevation: 0, centerTitle: true,
            iconTheme: IconThemeData(color: Color(0xFF333333)),
            titleTextStyle: TextStyle(color: Color(0xFF333333), fontSize: 17, fontWeight: FontWeight.w600)),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
