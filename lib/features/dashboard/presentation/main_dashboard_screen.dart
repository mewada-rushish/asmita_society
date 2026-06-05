import 'package:flutter/material.dart';
import '../../../core/widgets/asmita_bottom_nav_bar.dart'; 
import '../../menu/presentation/screens/menu_screen.dart'; 
import '../../community/presentation/screens/community_screen.dart';
import '../../visitor_management/presentation/screens/visitor_history_screen.dart';
import '../../services/presentation/screens/services_screen.dart';
import 'views/owner_dashboard_view.dart';
import 'views/tenant_dashboard_view.dart';

class MainDashboardScreen extends StatefulWidget {
  final String userRole;

  const MainDashboardScreen({super.key, required this.userRole});

  @override
  State<MainDashboardScreen> createState() => _MainDashboardScreenState();
}

class _MainDashboardScreenState extends State<MainDashboardScreen> {
  int _currentIndex = 0;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      _resolveRoleBasedHomeView(widget.userRole), // Index 0: Home View
      const ServicesScreen(),                     // Index 1: Services Grid
      const CommunityScreen(),                    // Index 2: Society Chat
      const VisitorHistoryScreen(),               // Index 3: Gate Records
      MenuScreen(userRole: widget.userRole),      // Index 4: Settings Profile
    ];
  }

  Widget _resolveRoleBasedHomeView(String role) {
    switch (role.toLowerCase()) {
      case 'owner':
        return const OwnerDashboardView();
      case 'tenant':
        return const TenantDashboardView();
      default:
        return Center(child: Text('Role Architecture: $role'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: AsmitaBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
      ),
    );
  }
}