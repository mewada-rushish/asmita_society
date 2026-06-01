import 'package:flutter/material.dart';
import '../../../core/widgets/asmita_bottom_nav_bar.dart'; 
import '../../menu/presentation/screens/menu_screen.dart'; 
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
      _resolveRoleBasedHomeView(widget.userRole),
      _buildPlaceholderView('Community & Notice Board'),
      _buildPlaceholderView('Visitor Gate Management'),
      MenuScreen(userRole: widget.userRole),
    ];
  }

  Widget _resolveRoleBasedHomeView(String role) {
    switch (role.toLowerCase()) {
      case 'owner':
        return const OwnerDashboardView();
      case 'tenant':
        return const TenantDashboardView();
      default:
        return _buildPlaceholderView('Generic Home Hub\nRole: $role');
    }
  }

  Widget _buildPlaceholderView(String moduleName) {
    return Center(
      child: Text(
        moduleName,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 16,
          color: Colors.black54,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // FIXED: Set to pure white to eliminate color mismatch/bleed behind bottom nav bar lines
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