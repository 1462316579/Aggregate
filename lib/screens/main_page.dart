import 'package:flutter/material.dart';
import 'home_page.dart';
import 'plugin/plugin_page.dart';
import 'settings/settings_page.dart';
import '../l10n/app_localizations.dart';
import '../services/app_config.dart';

/// Main application shell with responsive navigation and runtime localization.
class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _index = 0;

  static const _pages = <Widget>[
    HomePage(),
    PluginPage(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: AppConfig.languageNotifier,
      builder: (context, language, _) {
        final s = AppStrings.of(language);
        final destinations = <NavigationDestination>[
          NavigationDestination(icon: const Icon(Icons.home_outlined), selectedIcon: const Icon(Icons.home), label: s.t('home')),
          NavigationDestination(icon: const Icon(Icons.extension_outlined), selectedIcon: const Icon(Icons.extension), label: s.t('plugin')),
          NavigationDestination(icon: const Icon(Icons.settings_outlined), selectedIcon: const Icon(Icons.settings), label: s.t('settings')),
        ];
        return LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 900;
            if (!wide) {
              return Scaffold(
                body: IndexedStack(index: _index, children: _pages),
                bottomNavigationBar: NavigationBar(
                  selectedIndex: _index,
                  onDestinationSelected: (value) => setState(() => _index = value),
                  destinations: destinations,
                ),
              );
            }

            return Scaffold(
              body: Row(
                children: <Widget>[
                  NavigationRail(
                    selectedIndex: _index,
                    onDestinationSelected: (value) => setState(() => _index = value),
                    labelType: NavigationRailLabelType.all,
                    leading: Padding(
                      padding: const EdgeInsets.fromLTRB(8, 16, 8, 28),
                      child: Column(
                        children: <Widget>[
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                            child: Icon(Icons.play_arrow_rounded, color: Theme.of(context).colorScheme.primary),
                          ),
                          const SizedBox(height: 8),
                          const Text('宏曦聚合', style: TextStyle(fontSize: 11)),
                        ],
                      ),
                    ),
                    destinations: <NavigationRailDestination>[
                      NavigationRailDestination(icon: const Icon(Icons.home_outlined), selectedIcon: const Icon(Icons.home), label: Text(s.t('home'))),
                      NavigationRailDestination(icon: const Icon(Icons.extension_outlined), selectedIcon: const Icon(Icons.extension), label: Text(s.t('plugin'))),
                      NavigationRailDestination(icon: const Icon(Icons.settings_outlined), selectedIcon: const Icon(Icons.settings), label: Text(s.t('settings'))),
                    ],
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(child: IndexedStack(index: _index, children: _pages)),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
