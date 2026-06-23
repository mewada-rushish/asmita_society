import 'package:flutter/material.dart';
import '../../../core/widgets/asmita_bottom_nav_bar.dart'; 
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
  int _previousIndex = 0; // To track screen before search

  void _navigateToSearch() {
    setState(() {
      _previousIndex = _currentIndex;
      _currentIndex = 7; // Index of Search Screen
    });
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
      ViewMoreScreen(
        // FIXED: Gracefully rewires the back navigation pipeline to jump back to Home
        onBack: () {
          setState(() {
            _currentIndex = 0; // Natively slides user view focus safely back onto the main dashboard canvas!
          });
        },
      ),                                          // Index 5: Deep Service Directory
      DailyHelpScreen( // Index 6: FOR DAILY HELP
        onNavigateToSearch: _navigateToSearch,
        onNavigateToCommunity: () => setState(() => _currentIndex = 2),
      ),
      AsmitaSearchScreen(
        onBack: () => setState(() => _currentIndex = _previousIndex), // Steps back to the previous view
        onQuickRedirect: (targetIndex) {
          setState(() {
            _currentIndex = targetIndex; // Natively jumps directly to the screen within the global bar structure
          });
        },
      ),
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
            setState(() {
              _currentIndex = 5; // Deep Directory
            });
          },
          onNavigateToServices: () {
            setState(() {
              _currentIndex = 1; // FIXED: Natively switches view canvas to Services (Index 1)
            });
          },
          onNavigateToDailyHelp: () => setState(() => _currentIndex = 6),
          onNavigateToSearch: _navigateToSearch,
        );
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