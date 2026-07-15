import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dashboard_tab.dart';
import 'workout_tab.dart';
import 'nutrition_tab.dart';
import 'progress_tab.dart';
import '../services/api_service.dart';
import '../services/clerk_service.dart';
import '../services/engagement_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_background.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;
  final GlobalKey<DashboardTabState> _dashboardTabKey = GlobalKey<DashboardTabState>();

  late final List<Widget> _tabs = [
    DashboardTab(key: _dashboardTabKey, onOpenWorkout: () => _switchTab(1)),
    const WorkoutTab(),
    const NutritionTab(),
    const ProgressTab(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _bootEngagement();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Si vuelve del background al foreground, reprograma avisos (marca “abrió la app”).
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _bootEngagement();
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      EngagementService.instance.onAppPaused();
    }
  }

  Future<void> _bootEngagement() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('user_name');
    await EngagementService.instance.onAppOpened(userName: name);
    _dashboardTabKey.currentState?.reloadEngagement();
  }

  void _switchTab(int index) {
    setState(() => _currentIndex = index);
  }

  void _handleLogout() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.cardSolid,
          title: const Text('Cerrar sesión'),
          content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () async {
                await EngagementService.instance.clearOnLogout();
                await ApiService.clearToken();
                await ClerkService.clearSession();
                if (mounted) {
                  Navigator.pop(context);
                  Navigator.pushReplacementNamed(context, '/');
                }
              },
              child: const Text('Cerrar sesión', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: IndexedStack(
            index: _currentIndex,
            children: _tabs,
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(
              color: AppColors.border,
              width: 0.5,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex > 3 ? 0 : _currentIndex,
          onTap: (index) {
            if (index == 4) {
              _handleLogout();
            } else {
              setState(() {
                _currentIndex = index;
              });
              if (index == 0) {
                _dashboardTabKey.currentState?.reloadEngagement();
              }
            }
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColors.cardSolid.withOpacity(0.95),
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.mutedForeground,
          selectedLabelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(LucideIcons.layoutDashboard, size: 20),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(LucideIcons.dumbbell, size: 20),
              label: 'Entrenamiento',
            ),
            BottomNavigationBarItem(
              icon: Icon(LucideIcons.apple, size: 20),
              label: 'Nutrición',
            ),
            BottomNavigationBarItem(
              icon: Icon(LucideIcons.trendingUp, size: 20),
              label: 'Progreso',
            ),
            BottomNavigationBarItem(
              icon: Icon(LucideIcons.logOut, size: 20),
              label: 'Salir',
            ),
          ],
        ),
      ),
    );
  }
}
