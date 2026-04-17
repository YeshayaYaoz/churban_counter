import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/home_screen.dart';
import 'services/widget_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await WidgetService.initialize();
  runApp(const ChurbanCounterApp());
}

class ChurbanCounterApp extends StatefulWidget {
  const ChurbanCounterApp({super.key});

  @override
  State<ChurbanCounterApp> createState() => _ChurbanCounterAppState();
}

class _ChurbanCounterAppState extends State<ChurbanCounterApp> {
  bool _isHebrew = true; // Default to Hebrew

  @override
  void initState() {
    super.initState();
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isHebrew = prefs.getBool('isHebrew') ?? true;
    });
  }

  Future<void> _toggleLocale() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isHebrew = !_isHebrew;
    });
    await prefs.setBool('isHebrew', _isHebrew);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'זכר לחורבן',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A0A0A),
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFFD4A84B),
          secondary: const Color(0xFF1B3A4B),
          surface: const Color(0xFF0A0A0A),
        ),
      ),
      home: HomeScreen(
        isHebrew: _isHebrew,
        onToggleLocale: _toggleLocale,
      ),
    );
  }
}
