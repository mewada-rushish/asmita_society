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
import 'views/director_dashboard_view.dart';
import 'views/employee_dashboard_view.dart';
import 'views/receptionist_dashboard_view.dart';
import 'views/facility_staff_dashboard_view.dart';
import 'screens/guard_history_screen.dart';
import 'screens/guard_checked_in_screen.dart';
import 'screens/industrial_visits_screen.dart';
import 'screens/industrial_directory_screen.dart';
import '../../visitor_management/presentation/screens/guard_qr_scanner_screen.dart';
import '../../visitor_management/presentation/screens/department_delegation_screen.dart';
import 'package:asmita_society/features/services/presentation/screens/daily_help_screen.dart';
import 'screens/search_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/utils/property_role_resolver.dart';
import 'package:asmita_society/features/auth/bloc/auth_bloc.dart';
import 'package:asmita_society/features/auth/bloc/auth_state.dart';
import 'package:asmita_society/features/services/bloc/daily_help_bloc.dart';
import 'package:asmita_society/features/services/bloc/daily_help_event.dart';
import 'package:asmita_society/features/services/data/repositories/daily_help_repository.dart';
import '../../../core/di/injection_container.dart' as di;
import '../../visitor_management/bloc/industrial_visit_bloc.dart';
import '../../visitor_management/data/repositories/industrial_visit_repository.dart';

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
  List<Widget> _buildScreens() {
    final normalized = PropertyRoleResolver.normalizeRole(widget.userRole);
    final isResidential = normalized == 'owner' || normalized == 'tenant';
    return [
      _resolveRoleBasedHomeView(widget.userRole), // Index 0: Home view
      isResidential
          ? ServicesScreen( // Index 1: Services Grid
              onNavigateToSearch: _navigateToSearch,
              onNavigateToCommunity: () => setState(() => _currentIndex = 2),
            )
          : _wrapWithIndustrialBloc(
              context,
              IndustrialVisitsScreen(onBack: () => setState(() => _currentIndex = 0)),
            ),
      isResidential
          ? CommunityScreen( // Index 2: Society Chat
              onNavigateToSearch: _navigateToSearch,
              onNavigateToCommunity: () => setState(() => _currentIndex = 2),
            )
          : IndustrialDirectoryScreen(onBack: () => setState(() => _currentIndex = 0)),
      _resolveRoleBasedHistoryView(widget.userRole),               // Index 3: Gate Records (History)
      MenuScreen(
        userRole: widget.userRole,
        onNavigateToTab: (index) {
          setState(() => _currentIndex = index);
        },
      ),      // Index 4: Profile Settings
      _resolveRoleBasedQrScanner(widget.userRole), // Index 5: QR Scanner
      _resolveRoleBasedCheckedInView(widget.userRole), // Index 6: Checked In (Guard only)
    ];
  }

  Widget _resolveRoleBasedCheckedInView(String role) {
    if (PropertyRoleResolver.normalizeRole(role) == 'guard') {
      return const GuardCheckedInScreen();
    }
    return const SizedBox.shrink();
  }


  Widget _resolveRoleBasedHomeView(String role) {
    final normalized = PropertyRoleResolver.normalizeRole(role);
    switch (normalized) {
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
            }, onNavigateToPosts: _navigateToAllNotices);
          },
          onNavigateToServices: () {
            setState(() {
              _currentIndex = 1; // FIXED: Natively switches view canvas to Services (Index 1)
            });
          },
          onNavigateToDailyHelp: _navigateToDailyHelp,
          onNavigateToAllNotices: _navigateToAllNotices,
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
          onNavigateToAllNotices: _navigateToAllNotices,
          onNavigateToSearch: _navigateToSearch,
        );
      case 'guard':
        return _wrapWithIndustrialBloc(
          context,
          GuardDashboardView(
            onNavigateToMenu: () => setState(() => _currentIndex = 4),
            onNavigateToHistory: () => setState(() => _currentIndex = 3),
            onNavigateToScanner: () => setState(() => _currentIndex = 5),
          ),
        );
      case 'director':
        return _wrapWithIndustrialBloc(
          context,
          const DirectorDashboardView(),
        );
      case 'employee':
        final authState = context.watch<AuthBloc>().state;
        final user = authState is AuthAuthenticated ? authState.user : null;
        return _wrapWithIndustrialBloc(
          context,
          EmployeeDashboardView(
            employeeName: (user != null && user.fullName.isNotEmpty) ? user.fullName : 'Aditi Sharma',
            onOpenDelegation: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DepartmentDelegationScreen()),
              );
            },
          ),
        );
      case 'receptionist':
        return _wrapWithIndustrialBloc(context, const ReceptionistDashboardView());
      case 'facility':
        return _wrapWithIndustrialBloc(context, const FacilityStaffDashboardView());
      default:
        return Center(child: Text('Role Architecture: $role'));
    }
  }

  Widget _wrapWithIndustrialBloc(BuildContext context, Widget child) {
    di.registerIndustrialDependencies();
    try {
      context.read<IndustrialVisitBloc>();
      return child;
    } catch (_) {
      return BlocProvider<IndustrialVisitBloc>(
        create: (_) => IndustrialVisitBloc(
          repository: di.sl<IndustrialVisitRepository>(),
        ),
        child: child,
      );
    }
  }


  Widget _resolveRoleBasedQrScanner(String role) {
    if (PropertyRoleResolver.normalizeRole(role) == 'guard') {
      return GuardQrScannerScreen(
        isActive: _currentIndex == 5,
        onScanComplete: () => setState(() => _currentIndex = 0),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _resolveRoleBasedHistoryView(String role) {
    final normalized = PropertyRoleResolver.normalizeRole(role);
    if (normalized == 'guard' ||
        normalized == 'director' ||
        normalized == 'employee' ||
        normalized == 'receptionist' ||
        normalized == 'facility') {
      return const GuardHistoryScreen();
    }
    return VisitorHistoryScreen(onBack: () => setState(() => _currentIndex = 0));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: AsmitaAnimatedIndexedStack(
        index: _currentIndex,
        children: _buildScreens(),
      ),
      bottomNavigationBar: AsmitaBottomNavBar(
        currentIndex: _currentIndex,
        userRole: widget.userRole,
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
      ),
    );
  }
}