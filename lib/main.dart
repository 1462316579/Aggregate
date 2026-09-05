import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '宏曦聚合',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        primaryColor: const Color(0xFF2196F3),
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentTab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _currentTab == 0 ? _buildHomePage() : _buildMinePage(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentTab,
        onTap: (i) => setState(() => _currentTab = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: '首页'),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: '我的'),
        ],
      ),
    );
  }

  Widget _buildHomePage() {
    return Column(
      children: [
        // 搜索栏
        Container(
          margin: const EdgeInsets.fromLTRB(16, 48, 16, 0),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Row(
            children: [
              Icon(Icons.search, color: Colors.grey),
              SizedBox(width: 8),
              Expanded(child: Text('搜索影视、漫画、小说、音乐...',
                  style: TextStyle(color: Colors.grey))),
            ],
          ),
        ),
        // 分类标签
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            children: ['🔥精选', '📖漫画', '📚小说', '🎵音乐', '📺直播', '📂书架']
                .map((s) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: s.startsWith('🔥') ? const Color(0xFF2196F3) : Colors.grey[100],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  alignment: Alignment.center,
                  child: Text(s, style: TextStyle(
                    color: s.startsWith('🔥') ? Colors.white : Colors.grey[700],
                    fontSize: 13,
                  )),
                ))
                .toList(),
          ),
        ),
        // 内容
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.movie_filter, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text('宏曦聚合', style: TextStyle(
                    fontSize: 24, fontWeight: FontWeight.bold, color: Colors.grey[700])),
                const SizedBox(height: 8),
                Text('全平台影视聚合播放器', style: TextStyle(
                    fontSize: 14, color: Colors.grey[500])),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2196F3),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                  onPressed: () {},
                  child: const Text('开始使用'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMinePage() {
    return ListView(
      children: [
        const SizedBox(height: 48),
        // 用户信息
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: const Color(0xFF2196F3).withOpacity(0.1),
                child: const Icon(Icons.person, color: Color(0xFF2196F3), size: 36),
              ),
              const SizedBox(width: 14),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('宏曦聚合用户', style: TextStyle(
                      fontSize: 17, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text('包名: juhe.2026.homes', style: TextStyle(
                      fontSize: 13, color: Colors.grey)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // 功能列表
        Container(
          color: Colors.white,
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.settings, color: Colors.grey),
                title: const Text('设置'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.info, color: Colors.grey),
                title: const Text('关于'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Center(
          child: Text('v1.0.0 · 包名 juhe.2026.homes',
              style: TextStyle(fontSize: 12, color: Colors.grey[400])),
        ),
      ],
    );
  }
}
