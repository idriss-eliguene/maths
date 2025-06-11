// lib/main.dart
import 'package:flutter/material.dart';

// N’oublie pas d’avoir ces deux fichiers dans lib/pages/
import 'pages/solve_page.dart';
import 'pages/study_page.dart';

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int _index = 0;

  // Chaque élément est un widget instancié (et const si possible)
  final List<Widget> _pages = const [
    SolvePage(),
    StudyPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Math Assistant',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: Text(
            _index == 0 ? 'Résolution pas-à-pas' : 'Étude de fonction',
          ),
        ),
        body: _pages[_index],
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.calculate),
              label: 'Résoudre',
            ),
            NavigationDestination(
              icon: Icon(Icons.functions),
              label: 'Étude f(x)',
            ),
          ],
        ),
      ),
    );
  }
}
