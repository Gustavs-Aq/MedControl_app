// ============================================================
//  main.dart  –  MedControl
//
//  Arquitetura combinada de:
//  • darthave/main.dart     → AuthGate, MainNavigation, placeholders
//  • medcontrol_full main   → integração com ApiService
//  • medcontrol_flutter     → UI, modal animado, enum de telas
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'database/database_helper.dart';
import 'providers/auth_controller.dart';
import 'theme/app_theme.dart';
import 'widgets/shared_widgets.dart';

import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/medications_screen.dart';
import 'screens/history_screen.dart';
import 'screens/reports_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/add_medication_modal.dart';

// ── Bootstrap ────────────────────────────────────────────────
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar banco SQLite (cria tabelas se não existirem)
  await DatabaseHelper.instance.database;

  // Orientação apenas portrait
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  runApp(const MedControlApp());
}

// ── App root ─────────────────────────────────────────────────
class MedControlApp extends StatelessWidget {
  const MedControlApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MedControl',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const AuthGate(),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  AUTH GATE  –  define se vai pro login ou app
//  (estrutura base do darthave/main.dart)
// ══════════════════════════════════════════════════════════════
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    // Verifica sessão ativa no AuthController (singleton)
    final isLogged = AuthController.instance.isLogged;

    return isLogged ? const MainNavigation() : const MainNavigator();
  }
}

// ══════════════════════════════════════════════════════════════
//  ENUM DE TELAS  (upgrade do darthave/main.dart)
// ══════════════════════════════════════════════════════════════
enum AppScreen {
  splash,
  login,
  register,
  home,
  medications,
  history,
  reports,
  profile,
}

// ══════════════════════════════════════════════════════════════
//  MAIN NAVIGATOR  –  fluxo pré-autenticação (splash → login)
// ══════════════════════════════════════════════════════════════
class MainNavigator extends StatefulWidget {
  const MainNavigator({super.key});

  @override
  State<MainNavigator> createState() => _MainNavigatorState();
}

class _MainNavigatorState extends State<MainNavigator> {
  AppScreen _screen = AppScreen.splash;
  bool _showAddMed = false;

  @override
  void initState() {
    super.initState();
    // Splash por 2 segundos → login
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && _screen == AppScreen.splash) {
        setState(() => _screen = AppScreen.login);
      }
    });
  }

  void _navigate(String screen) {
    final s = AppScreen.values.firstWhere(
      (e) => e.name == screen,
      orElse: () => AppScreen.login,
    );
    // Se navegou para home, vai para a MainNavigation completa
    if (s == AppScreen.home) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainNavigation()),
      );
      return;
    }
    setState(() => _screen = s);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildScreen(),
          if (_showAddMed)
            AddMedicationModal(
              onClose: () => setState(() => _showAddMed = false),
            ),
        ],
      ),
    );
  }

  Widget _buildScreen() {
    switch (_screen) {
      case AppScreen.splash:
        return const SplashScreen();
      case AppScreen.login:
        return LoginScreen(onNavigate: _navigate);
      case AppScreen.register:
        return RegisterScreen(onNavigate: _navigate);
      default:
        return const SplashScreen();
    }
  }
}

// ══════════════════════════════════════════════════════════════
//  MAIN NAVIGATION  –  bottom nav pós-autenticação
//  (expandido do darthave/main.dart MainNavigation)
// ══════════════════════════════════════════════════════════════
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  bool _showAddMed = false;

  void _navigate(String screen) {
    final tabMap = {
      'home': 0,
      'medications': 1,
      'history': 2,
      'reports': 3,
      'profile': 4,
    };

    if (screen == 'login') {
      AuthController.instance.logout();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainNavigator()),
      );
      return;
    }

    final idx = tabMap[screen];
    if (idx != null) setState(() => _currentIndex = idx);
  }

  void _openAddMed() => setState(() => _showAddMed = true);
  void _closeAddMed() => setState(() => _showAddMed = false);

  // Rebuild tab ao salvar medicamento
  void _onMedSaved() {
    _closeAddMed();
    setState(() {}); // force rebuild
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: [
              HomePage(onNavigate: _navigate, onOpenAddMed: _openAddMed),
              MedicationsPage(
                  onNavigate: _navigate, onOpenAddMed: _openAddMed),
              HistoryPage(onNavigate: _navigate),
              ReportsPage(onNavigate: _navigate),
              ProfilePage(onNavigate: _navigate),
            ],
          ),
          if (_showAddMed)
            AddMedicationModal(
              onClose: _onMedSaved,
            ),
        ],
      ),
    );
  }
}
