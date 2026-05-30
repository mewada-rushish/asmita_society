import 'package:flutter/material.dart';
import '../../../core/widgets/asmita_bottom_nav_bar.dart'; 
import 'views/owner_dashboard_view.dart';
import 'views/tenant_dashboard_view.dart';
import '../../menu/presentation/screens/menu_screen.dart';

/// The root application shell containing the persistent global navigation bar 
/// and role-based view resolution.
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

  /// Resolves the primary dashboard view based on the authenticated user's role.
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
      backgroundColor: const Color(0xFFF8F8FB),
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