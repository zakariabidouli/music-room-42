import 'package:flutter/material.dart';
import 'config.dart';

void main() => runApp(const App());

class App extends StatelessWidget {
  const App({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Music Room',
      home: Scaffold(
        appBar: AppBar(title: const Text('Music Room')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            const Text('Backend URL (configurable for tests):'),
            TextField(
              decoration: InputDecoration(hintText: AppConfig.backendUrl),
              onSubmitted: (v) => AppConfig.backendUrl = v,
            ),
            const SizedBox(height: 16),
            const Text('Screens: Auth / Vote queue / Playlist editor (remote-control only).'),
          ]),
        ),
      ),
    );
  }
}
