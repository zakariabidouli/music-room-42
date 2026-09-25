import 'package:flutter/material.dart';

import 'config.dart';
import 'screens_auth.dart';
import 'screens_more.dart';
import 'screens_playlist.dart';
import 'screens_vote.dart';
import 'session.dart';
import 'ui/shell.dart';
import 'ui/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppConfig.load();
  final session = Session();
  await session.load();
  runApp(App(session: session));
}

class App extends StatefulWidget {
  final Session session;

  const App({required this.session, super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Music Room',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.dark,
      home: ListenableBuilder(
        listenable: widget.session,
        builder: (context, _) {
          final labels = [
            'Home',
            'Playlists',
            'Discover',
            widget.session.isAuthed ? 'Account' : 'Sign in',
            'Settings',
          ];
          final icons = [
            Icons.home_outlined,
            Icons.queue_music_outlined,
            Icons.explore_outlined,
            Icons.person_outline,
            Icons.settings_outlined,
          ];
          final selectedIcons = [
            Icons.home_rounded,
            Icons.queue_music_rounded,
            Icons.explore_rounded,
            Icons.person_rounded,
            Icons.settings_rounded,
          ];
          final pages = [
            VoteScreen(widget.session),
            PlaylistScreen(widget.session),
            MoreScreen(widget.session),
            AuthScreen(widget.session),
            SettingsScreen(
              widget.session,
              onUrlChanged: () => setState(() {}),
            ),
          ];
          final items = [
            for (var index = 0; index < labels.length; index++)
              AppNavigationItem(
                label: labels[index],
                icon: icons[index],
                selectedIcon: selectedIcons[index],
              ),
          ];

          return LayoutBuilder(
            builder: (context, constraints) {
              final useRail = constraints.maxWidth >= 700;
              final useSidebar = constraints.maxWidth >= 1120;
              final content = IndexedStack(
                index: _selectedIndex,
                children: pages,
              );

              Widget navigation;
              if (useSidebar) {
                navigation = AppSidebar(
                  items: items,
                  selectedIndex: _selectedIndex,
                  onSelected: (index) =>
                      setState(() => _selectedIndex = index),
                );
              } else if (useRail) {
                navigation = AppNavigationRail(
                  items: items,
                  selectedIndex: _selectedIndex,
                  onSelected: (index) =>
                      setState(() => _selectedIndex = index),
                );
              } else {
                navigation = NavigationBar(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: (index) =>
                      setState(() => _selectedIndex = index),
                  destinations: [
                    for (var index = 0; index < items.length; index++)
                      NavigationDestination(
                        icon: Icon(items[index].icon),
                        selectedIcon: Icon(items[index].selectedIcon),
                        label: items[index].label,
                      ),
                  ],
                );
              }

              return Scaffold(
                body: SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      if (useSidebar || useRail) navigation,
                      if (useSidebar || useRail)
                        const VerticalDivider(width: 1),
                      Expanded(
                        child: Column(
                          children: [
                            Expanded(child: content),
                            const MiniPlayer(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                bottomNavigationBar:
                    useSidebar || useRail ? null : navigation,
              );
            },
          );
        },
      ),
    );
  }
}