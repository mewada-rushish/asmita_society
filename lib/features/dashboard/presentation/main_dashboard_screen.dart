import 'package:flutter/material.dart';
import '../../../core/widgets/asmita_bottom_nav_bar.dart'; 
import '../../../core/widgets/asmita_animated_indexed_stack.dart';
import '../../menu/presentation/screens/menu_screen.dart'; 
import '../../community/presentation/screens/community_screen.dart';
import '../../visitor_management/presentation/screens/visitor_history_screen.dart';
import '../../services/presentation/screens/services_screen.dart';
import 'screens/view_more_screen.dart';
import 'views/owner_dashboard_view.dart';
import 'views/tenant_dashboard_view.dart';
import 'package:asmita_society/features/services/presentation/screens/daily_help_screen.dart';
import 'screens/search_screen.dart';

class MainDashboardScreen extends StatefulWidget {
  final String userRole;

  const MainDashboardScreen({super.key, required this.userRole});

  @override
  State<MainDashboardScreen> createState() => _MainDashboardScreenState();
}

class _MainDashboardScreenState extends State<MainDashboardScreen> {
  int _currentIndex = 0;

  void _navigateToSearch() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AsmitaSearchScreen(
          onBack: () => Navigator.pop(context),
          onQuickRedirect: (targetIndex) {
            Navigator.pop(context);
            setState(() {
              _currentIndex = targetIndex;
            });
          },
        ),
      ),
    );
  }

  void _navigateToDailyHelp() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DailyHelpScreen(
          onNavigateToSearch: () {
            Navigator.pop(context);
            _navigateToSearch();
          },
          onNavigateToCommunity: () {
            Navigator.pop(context);
            setState(() => _currentIndex = 2);
          },
        ),
      ),
    );
  }

  // Dynamically builds the view list cleanly to keep callback bindings alive on state mutations
  List<Widget> _buildScreens() {
    return [
      _resolveRoleBasedHomeView(widget.userRole), // Index 0: Home view
      ServicesScreen( // Index 1: Services Grid
        onNavigateToSearch: _navigateToSearch,
        onNavigateToCommunity: () => setState(() => _currentIndex = 2),
      ),
      CommunityScreen( // Index 2: Society Chat
        onNavigateToSearch: _navigateToSearch,
        onNavigateToCommunity: () => setState(() => _currentIndex = 2),
      ),
      const VisitorHistoryScreen(),               // Index 3: Gate Records (History)
      MenuScreen(userRole: widget.userRole),      // Index 4: Profile Settings
    ];
  }


  Widget _resolveRoleBasedHomeView(String role) {
    switch (role.toLowerCase()) {
      case 'owner':
        return OwnerDashboardView(
          onNavigateToCommunity: () {
            setState(() {
              _currentIndex = 2; // Society Chat
            });
          },
          onNavigateToHistory: () {
            setState(() {
              _currentIndex = 3; // Gate Records
            });
          },
          onNavigateToViewMore: () {
            showViewMoreSheet(context, onNavigationItemSelected: (index) {
              setState(() => _currentIndex = index);
            });
          },
          onNavigateToServices: () {
            setState(() {
              _currentIndex = 1; // FIXED: Natively switches view canvas to Services (Index 1)
            });
          },
          onNavigateToDailyHelp: _navigateToDailyHelp,
          onNavigateToSearch: _navigateToSearch,
        );
      case 'tenant':
        return TenantDashboardView(
          onNavigateToCommunity: () {
            setState(() {
              _currentIndex = 2; // Society Chat
            });
          },
          onNavigateToHistory: () {
            setState(() {
              _currentIndex = 3; // Gate Records
            });
          },
          onNavigateToViewMore: () {
            setState(() {
              _currentIndex = 4; // View More/Menu
            });
          },
          onNavigateToServices: () => setState(() => _currentIndex = 1),
          onNavigateToDailyHelp: _navigateToDailyHelp,
          onNavigateToSearch: _navigateToSearch,
        );
      default:
        return Center(child: Text('Role Architecture: $role'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: AsmitaAnimatedIndexedStack(
        index: _currentIndex,
        children: _buildScreens(),
      ),
      bottomNavigationBar: AsmitaBottomNavBar(
        // Clamps down indices greater than 4 so the "Services" icon (Index 1) 
        // remains active when viewing the deep ViewMore screen
        currentIndex: _currentIndex > 4 ? 1 : _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
      ),
    );
  }
}