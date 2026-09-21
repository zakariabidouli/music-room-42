import 'package:flutter/material.dart';
import 'config.dart';

void main() => runApp(const App());

// Bonus: responsive layout (VI.1 web), nearby banner (VI.2),
// mock tier badge (VI.3 free-only), offline note (VI.4).
class App extends StatelessWidget {
  const App({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Music Room',
      home: Scaffold(
        appBar: AppBar(title: const Text('Music Room (free school demo)')),
        body: LayoutBuilder(builder: (ctx, c) {
          final wide = c.maxWidth >= 1024;
          final col = Column(children: const [
            Text('Backend URL (configurable for tests)'),
            Text('Tier: free (mock upgrade in Settings)'),
            Text('Screens: Auth / Vote queue / Playlist editor / Nearby / Sync status.'),
          ]);
          if (wide) {
            return Row(children: [Expanded(child: col), const Expanded(child: Text('Wide pane: queue + editor side by side'))]);
          }
          return Padding(padding: const EdgeInsets.all(16), child: col);
        }),
      ),
    );
  }
}
