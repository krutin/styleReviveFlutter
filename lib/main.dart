import 'package:flutter/material.dart';
import 'screens/landing_screen.dart';

void main() {
  runApp(const StyleReviveApp());
}

class StyleReviveApp extends StatefulWidget {
  const StyleReviveApp({super.key});

  @override
  State<StyleReviveApp> createState() => _StyleReviveAppState();
}

class _StyleReviveAppState extends State<StyleReviveApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void toggleTheme() {
    setState(() {
      _themeMode =
      _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StyleRevive',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      darkTheme: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepPurple, brightness: Brightness.dark),
      ),
      themeMode: _themeMode,
      home: LandingScreen(onToggleTheme: toggleTheme),
      debugShowCheckedModeBanner: false,
    );
  }
}