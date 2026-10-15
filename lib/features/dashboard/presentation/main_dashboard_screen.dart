import 'package:flutter/material.dart';

import '../../../core/widgets/asmita_bottom_nav_bar.dart'; 
import '../../../core/widgets/asmita_animated_indexed_stack.dart';
import '../../menu/presentation/screens/menu_screen.dart'; 
import '../../community/presentation/screens/community_screen.dart';
import '../../community/presentation/screens/all_notices_screen.dart';
import '../../visitor_management/presentation/screens/visitor_history_screen.dart';
import '../../services/presentation/screens/services_screen.dart';
import 'screens/view_more_screen.dart';
import 'views/owner_dashboard_view.dart';
import 'views/tenant_dashboard_view.dart';
import 'views/guard_dashboard_view.dart';
import 'screens/guard_history_screen.dart';
import 'screens/guard_checked_in_screen.dart';
import '../../visitor_management/presentation/screens/guard_qr_scanner_screen.dart';
import 'package:asmita_society/features/services/presentation/screens/daily_help_screen.dart';
import 'screens/search_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:asmita_society/features/auth/bloc/auth_bloc.dart';
import 'package:asmita_society/features/auth/bloc/auth_state.dart';
import 'package:asmita_society/features/services/bloc/daily_help_bloc.dart';
import 'package:asmita_society/features/services/bloc/daily_help_event.dart';
import 'package:asmita_society/features/services/data/repositories/daily_help_repository.dart';

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
        builder: (_) => BlocProvider(
          create: (context) => DailyHelpBloc(
            repository: DailyHelpRepository(),
            authBloc: context.read<AuthBloc>(),
          )..add(const FetchDailyHelp()),
          child: DailyHelpScreen(
            onNavigateToSearch: () {
              Navigator.pop(context);
              _navigateToSearch();
            },
            onNavigateToCommunity: () {
              Navigator.pop(context);
              setState(() => _currentIndex = 2);
            },
            onNavigateToTab: (index) {
              Navigator.pop(context);
              setState(() => _currentIndex = index);
            },
          ),
        ),
      ),
    );
  }

  void _navigateToAllNotices() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AllNoticesScreen(
          onNavigateToSearch: () {
            Navigator.pop(context);
            _navigateToSearch();
          },
          onNavigateToCommunity: () {
            Navigator.pop(context);
            setState(() => _currentIndex = 2);
          },
          onNavigateToTab: (index) {
            Navigator.pop(context);
            setState(() => _currentIndex = index);
          },
        ),
      ),
    );
  }

  // Dynamically builds the view list cleanly to keep callback bindings alive on state mutations
  List<Widget> _buildScreens(String activeRole) {
    final isStaff = _isGuardOrReceptionist(activeRole);
    return [
      _resolveRoleBasedHomeView(activeRole), // Index 0: Home view
      isStaff
          ? const SizedBox.shrink()
          : ServicesScreen( // Index 1: Services Grid
              onNavigateToSearch: _navigateToSearch,
              onNavigateToCommunity: () => setState(() => _currentIndex = 2),
            ),
      isStaff
          ? const SizedBox.shrink()
          : CommunityScreen( // Index 2: Society Chat
              onNavigateToSearch: _navigateToSearch,
              onNavigateToCommunity: () => setState(() => _currentIndex = 2),
            ),
      _resolveRoleBasedHistoryView(activeRole),               // Index 3: Gate Records (History)
      MenuScreen(
        userRole: activeRole,
        onNavigateToTab: (index) {
          setState(() => _currentIndex = index);
        },
      ),      // Index 4: Profile Settings
      _resolveRoleBasedQrScanner(activeRole), // Index 5: QR Scanner
      _resolveRoleBasedCheckedInView(activeRole), // Index 6: Checked In (Guard/Receptionist only)
    ];
  }

  bool _isGuardOrReceptionist(String role) {
    final r = role.toLowerCase();
    return r == 'guard' || r.contains('guard') || r.contains('receptionist');
  }

  Widget _resolveRoleBasedCheckedInView(String role) {
    if (_isGuardOrReceptionist(role)) {
      return const GuardCheckedInScreen();
    }
    return const SizedBox.shrink();
  }

  Widget _resolveRoleBasedHomeView(String role) {
    final r = role.toLowerCase();

    // 1. Guards and Receptionists (Desk & Gate scanning)
    if (_isGuardOrReceptionist(role)) {
      return GuardDashboardView(
        onNavigateToMenu: () => setState(() => _currentIndex = 4),
        onNavigateToHistory: () => setState(() => _currentIndex = 3),
        onNavigateToScanner: () => setState(() => _currentIndex = 5),
      );
    }

    // 2. Tenants, Corporate Staff & HR
    if (r == 'tenant' ||
        r.contains('tenant') ||
        r.contains('staff') ||
        r.contains('employee') ||
        r == 'hr') {
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
        onNavigateToAllNotices: _navigateToAllNotices,
        onNavigateToSearch: _navigateToSearch,
      );
    }

    // 3. Owners, Directors, Executives & Residents
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
        }, onNavigateToPosts: _navigateToAllNotices);
      },
      onNavigateToServices: () {
        setState(() {
          _currentIndex = 1; // Natively switches view canvas to Services (Index 1)
        });
      },
      onNavigateToDailyHelp: _navigateToDailyHelp,
      onNavigateToAllNotices: _navigateToAllNotices,
      onNavigateToSearch: _navigateToSearch,
    );
  }

  Widget _resolveRoleBasedQrScanner(String role) {
    if (_isGuardOrReceptionist(role)) {
      return GuardQrScannerScreen(
        isActive: _currentIndex == 5,
        onScanComplete: () => setState(() => _currentIndex = 0),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _resolveRoleBasedHistoryView(String role) {
    if (_isGuardOrReceptionist(role)) {
      return const GuardHistoryScreen();
    }
    return VisitorHistoryScreen(onBack: () => setState(() => _currentIndex = 0));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        String activeRole = widget.userRole;
        if (state is AuthAuthenticated) {
          activeRole = state.sessionRole;
        }

        return Scaffold(
          extendBody: true,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: AsmitaAnimatedIndexedStack(
            index: _currentIndex,
            children: _buildScreens(activeRole),
          ),
          bottomNavigationBar: AsmitaBottomNavBar(
            currentIndex: _currentIndex,
            userRole: activeRole,
            onTap: (index) {
              setState(() => _currentIndex = index);
            },
          ),
        );
      }
    );
  }
}