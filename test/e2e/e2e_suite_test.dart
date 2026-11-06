import 'package:flutter_test/flutter_test.dart';

import 'r1_employee_creation_and_auth_test.dart' as r1_tests;
import 'r2_role_screens_and_themes_test.dart' as r2_tests;
import 'r3_delegation_flow_test.dart' as r3_tests;
import 'r4_theme_switching_persistence_test.dart' as r4_tests;
import 'r5_admin_portal_realtime_sync_test.dart' as r5_tests;
import 'r6_secrets_scrubbing_and_leak_prevention_test.dart' as r6_tests;
import 'tier3_cross_feature_interactions_test.dart' as tier3_tests;
import 'tier4_industrial_scenarios_test.dart' as tier4_tests;

/// Master Unified E2E Test Suite Runner for Asmita Industrial Property Roles
///
/// Executes 100% of opaque-box E2E tests across all 4 tiers and all 6 requirements:
/// - R1: Employee Creation Flow across 5 Industrial Roles & Auth Linking
/// - R2: Role Screens, Feature Functionality, and UI Theme Consistency
/// - R3: Delegation Flow Colleague List Resolution & Transitive Visit Status
/// - R4: Immediate Theme Switching & Synchronous Cold-Start Persistence
/// - R5: Real-Time App State Refresh on Admin Portal Updates
/// - R6: Secrets Scrubbing, Git History Purging & Leak Prevention
/// - Tier 3: Cross-Feature Interactions (Pairwise combinations)
/// - Tier 4: Real-World Industrial Property Scenarios
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('=== ASMITA INDUSTRIAL PROPERTY COMPLETE E2E TEST SUITE ===', () {
    r1_tests.main();
    r2_tests.main();
    r3_tests.main();
    r4_tests.main();
    r5_tests.main();
    r6_tests.main();
    tier3_tests.main();
    tier4_tests.main();
  });
}
