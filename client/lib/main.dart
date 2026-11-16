import 'package:flutter/material.dart';
import 'reports/parent_report_models.dart';
import 'reports/parent_report_screen.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/parent_settings_screen.dart';
import 'widgets/letter_tracing.dart';

void main() {
  runApp(const LeoParvulosApp());
}

class LeoParvulosApp extends StatelessWidget {
  const LeoParvulosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LeoPárvulos - Minijuegos de Lectura',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFBF360C),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF0F4F8),
      ),
      home: const TracingGameScreen(),
      routes: {
        HomeScreen.routeName: (_) => const HomeScreen(),
        '/minigame': (_) => const TracingGameScreen(),
        ParentReportScreen.routeName: (ctx) {
          final args = ModalRoute.of(ctx)?.settings.arguments;
          final report = args is ParentReport ? args : ParentReport.mock();
          return ParentReportScreen(report: report);
        },
        ParentSettingsScreen.routeName: (_) => const ParentSettingsScreen(),
        OnboardingScreen.routeName: (_) => const OnboardingScreen(),
      },
    );
  }
}

class TracingGameScreen extends StatefulWidget {
  const TracingGameScreen({super.key});

  @override
  State<TracingGameScreen> createState() => _TracingGameScreenState();
}

class _TracingGameScreenState extends State<TracingGameScreen> {
  int _completedCount = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.auto_stories_rounded, color: Colors.white),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Trazado Fonético',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFBF360C), // Contraste 5.6:1 sobre blanco (WCAG AA)
        actions: [
          IconButton(
            key: const Key('open_parent_report'),
            tooltip: 'Panel de padres y docentes',
            icon: const Icon(Icons.insights_rounded, color: Colors.white),
            onPressed: () =>
                Navigator.of(context).pushNamed(ParentReportScreen.routeName),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.star_rounded, color: Colors.amber, size: 28),
                const SizedBox(width: 4),
                Text(
                  '$_completedCount',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            children: [
              LetterTracing(
                letter: 'm',
                onComplete: () {
                  setState(() {
                    _completedCount++;
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
