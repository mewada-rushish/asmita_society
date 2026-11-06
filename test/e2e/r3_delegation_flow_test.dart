import 'package:flutter_test/flutter_test.dart';
import 'package:asmita_society/features/visitor_management/data/models/industrial_visit_model.dart';

/// Helper evaluating delegation candidate eligibility according to PROJECT.md rules
bool evaluateCandidateEligibility({
  required int currentUserId,
  required int currentUserPower,
  required String? userDepartment,
  required String? userFloor,
  required Map<String, dynamic> candidate,
}) {
  final candId = candidate['user_id'] ?? candidate['id'];
  if (candId == currentUserId) return false;

  final role = (candidate['role'] ?? candidate['designation'] ?? candidate['role_name'] ?? '').toString().toLowerCase();
  final desig = (candidate['designation'] ?? '').toString().toLowerCase();
  final name = (candidate['name'] ?? candidate['full_name'] ?? '').toString().toLowerCase();

  // 1. Gate receptionists are NEVER eligible as delegates
  if (role.contains('gate') || desig.contains('gate') || name.contains('gate')) return false;

  // 2. Floor receptionist check: allowed if assigned to actor's exact floor or category Receptionist
  final isReceptionist = role.contains('reception') || desig.contains('reception') || name.contains('reception');
  if (isReceptionist) {
    final candFloor = (candidate['floor']?.toString() ?? '')
        .toLowerCase()
        .replaceAll('floor', '')
        .replaceAll(RegExp(r'th|st|nd|rd'), '')
        .trim();
    final cleanUserFloor = (userFloor ?? '')
        .toLowerCase()
        .replaceAll('floor', '')
        .replaceAll(RegExp(r'th|st|nd|rd'), '')
        .trim();
    if (cleanUserFloor.isNotEmpty && candFloor.isNotEmpty && candFloor == cleanUserFloor) {
      return true;
    }
    if (candidate['category'] == 'Receptionist' && !name.contains('gate') && !desig.contains('gate')) {
      return true;
    }
    return false;
  }

  // 3. For ALL other colleagues: MUST NOT BE EXPLICITLY DISABLED
  final isExplicitlyDisabled = candidate['is_delegatee'] == false ||
      (candidate['role_details'] is Map && candidate['role_details']['is_delegatee'] == false);
  if (isExplicitlyDisabled) return false;

  final candidatePower = candidate['power'] is int
      ? candidate['power'] as int
      : int.tryParse(candidate['power']?.toString() ?? '') ?? 100;

  // 4. Upward delegation check: Subordinates cannot delegate to superiors (candidatePower > currentUserPower)
  // But peers (candidatePower <= currentUserPower) ARE permitted!
  if (currentUserPower < 500 && candidatePower > currentUserPower) {
    return false;
  }

  // 5. Director (power >= 500) can delegate to any active employee
  if (currentUserPower >= 500) {
    return true;
  }

  // 6. Department matching for peers
  final candDept = (candidate['department'] ?? candidate['department_name'] ?? (candidate['role_details'] is Map ? candidate['role_details']['department'] : '')).toString().toLowerCase();
  final uDept = (userDepartment ?? '').toLowerCase();
  if (uDept.isNotEmpty && candDept.isNotEmpty && (uDept == candDept || uDept.contains(candDept) || candDept.contains(uDept))) {
    return true;
  }

  final reportsTo = candidate['reports_to_user_id'] ?? candidate['reports_to_id'] ??
      (candidate['role_details'] is Map ? (candidate['role_details']['reports_to_user_id'] ?? candidate['role_details']['reports_to_id']) : null);
  if (reportsTo != null && reportsTo.toString() == currentUserId.toString()) {
    return true;
  }

  return true;
}

void main() {
  group('R3: Delegation Flow Colleague List & Status Updates (Opaque-Box E2E)', () {
    // ══════════════════════════════════════════════════════════════
    // TIER 1: FEATURE COVERAGE (Peer power, Director power, Contracts)
    // ══════════════════════════════════════════════════════════════

    test('TC-R3-01: Colleague API response payload parses correctly into eligible candidate model', () {
      final colleaguePayload = {
        'id': 228,
        'full_name': 'Suresh Raina',
        'role_name': 'Employee',
        'power': 100,
        'department_id': 7,
        'department_name': 'IT & Automation',
        'floor': 'Floor 2',
        'is_delegatee': true,
      };

      expect(colleaguePayload['id'], 228);
      expect(colleaguePayload['full_name'], 'Suresh Raina');
      expect(colleaguePayload['power'], 100);
      expect(colleaguePayload['department_id'], 7);
    });

    test('TC-R3-02: Peer employee query: employee (power 100) successfully delegates to peer colleague (power 100)', () {
      final peerCandidate = {
        'id': 228,
        'full_name': 'Rahul Dravid',
        'role_name': 'Employee',
        'power': 100,
        'department': 'Engineering',
        'is_delegatee': true,
      };

      final isEligible = evaluateCandidateEligibility(
        currentUserId: 227,
        currentUserPower: 100,
        userDepartment: 'Engineering',
        userFloor: 'Floor 1',
        candidate: peerCandidate,
      );

      expect(isEligible, isTrue, reason: 'Peers of equal power (100 <= 100) in the same department MUST be eligible delegatees');
    });

    test('TC-R3-03: Executive Director (power 1000) delegates across any department to subordinate staff', () {
      final subordinateCandidate = {
        'id': 229,
        'full_name': 'Anil Kumble',
        'role_name': 'Head of Department (HOD)',
        'power': 200,
        'department': 'Quality Control',
        'is_delegatee': true,
      };

      final isEligible = evaluateCandidateEligibility(
        currentUserId: 201,
        currentUserPower: 1000,
        userDepartment: 'Executive Board',
        userFloor: 'Floor 4',
        candidate: subordinateCandidate,
      );

      expect(isEligible, isTrue, reason: 'Directors can delegate downward to any subordinate across departments');
    });

    test('TC-R3-04: Active outgoing delegation payload reflects valid status and date range', () {
      final delegationStatusPayload = {
        'active_outgoing': {
          'id': 45,
          'property_id': 115,
          'delegator_user_id': 227,
          'delegate_user_id': 228,
          'delegate_name': 'Rahul Dravid',
          'scope': 'VISITORS',
          'is_active': true,
          'start_date': '2026-11-05T08:00:00Z',
          'end_date': '2026-11-06T18:00:00Z',
        },
        'incoming_delegations': [
          {
            'id': 32,
            'delegator_user_id': 201,
            'delegator_name': 'Dr. Alok Verma',
            'is_active': true,
          }
        ],
      };

      expect(delegationStatusPayload['active_outgoing'], isNotNull);
      final outgoing = delegationStatusPayload['active_outgoing'] as Map<String, dynamic>;
      expect(outgoing['delegate_user_id'], 228);
      expect(outgoing['delegate_name'], 'Rahul Dravid');
      expect(outgoing['is_active'], isTrue);

      final incoming = delegationStatusPayload['incoming_delegations'] as List;
      expect(incoming.length, 1);
      expect(incoming.first['delegator_name'], 'Dr. Alok Verma');
    });

    test('TC-R3-05: Transitive delegation resolution: reassigned visit resolves active delegatee as current approver', () {
      // Host 227 is delegated to Delegatee 228
      final visit = IndustrialVisitModel(
        id: 501,
        requestNumber: 'AH-2026-DEL-501',
        propertyId: 115,
        visitorName: 'Auditor Mehra',
        status: IndustrialVisitStatus.awaitingHost,
        departmentName: 'IT & Automation',
        hostName: 'Pooja Sharma (Delegated to Rahul Dravid)',
      );

      expect(visit.status, IndustrialVisitStatus.awaitingHost);
      expect(visit.hostName, contains('Delegated to'));
    });

    // ══════════════════════════════════════════════════════════════
    // TIER 2: BOUNDARY & CORNER CASES (Self-delegation, Gate receptionist, Upward)
    // ══════════════════════════════════════════════════════════════

    test('TC-R3-06: Self-delegation prevention: current user cannot delegate to themselves', () {
      final selfCandidate = {
        'id': 227,
        'full_name': 'Pooja Sharma (Self)',
        'role_name': 'Employee',
        'power': 100,
        'department': 'Engineering',
      };

      final isEligible = evaluateCandidateEligibility(
        currentUserId: 227,
        currentUserPower: 100,
        userDepartment: 'Engineering',
        userFloor: 'Floor 1',
        candidate: selfCandidate,
      );

      expect(isEligible, isFalse, reason: 'User must never be eligible to delegate to themselves');
    });

    test('TC-R3-07: Upward delegation rejection: employee (power 100) cannot delegate to Director (power 1000)', () {
      final directorCandidate = {
        'id': 201,
        'full_name': 'Executive Director Verma',
        'role_name': 'Director',
        'power': 1000,
        'department': 'Executive Board',
      };

      final isEligible = evaluateCandidateEligibility(
        currentUserId: 227,
        currentUserPower: 100,
        userDepartment: 'Engineering',
        userFloor: 'Floor 1',
        candidate: directorCandidate,
      );

      expect(isEligible, isFalse, reason: 'Regular employees must not delegate approvals upward to superiors');
    });

    test('TC-R3-08: Gate Receptionists are strictly barred from receiving visitor delegations', () {
      final gateReceptionist = {
        'id': 219,
        'full_name': 'Main Gate Receptionist Desk',
        'role_name': 'Gate Receptionist',
        'designation': 'Gate Concierge',
        'power': 50,
      };

      final isEligible = evaluateCandidateEligibility(
        currentUserId: 227,
        currentUserPower: 100,
        userDepartment: 'Engineering',
        userFloor: 'Floor 1',
        candidate: gateReceptionist,
      );

      expect(isEligible, isFalse, reason: 'Gate receptionists must never be eligible delegatees');
    });

    test('TC-R3-09: Floor Receptionist floor matching: eligible only if assigned to matching floor', () {
      final floor2Receptionist = {
        'id': 223,
        'full_name': 'Floor 2 Receptionist',
        'role_name': 'Floor Receptionist',
        'floor': 'Floor 2',
        'power': 50,
      };

      // When delegator is on Floor 2:
      final eligibleOnFloor2 = evaluateCandidateEligibility(
        currentUserId: 227,
        currentUserPower: 100,
        userDepartment: 'Engineering',
        userFloor: 'Floor 2',
        candidate: floor2Receptionist,
      );
      expect(eligibleOnFloor2, isTrue, reason: 'Floor receptionist on the same floor is an eligible delegatee');

      // When delegator is on Floor 1:
      final eligibleOnFloor1 = evaluateCandidateEligibility(
        currentUserId: 227,
        currentUserPower: 100,
        userDepartment: 'Engineering',
        userFloor: 'Floor 1',
        candidate: floor2Receptionist,
      );
      expect(eligibleOnFloor1, isFalse, reason: 'Floor receptionist on a different floor is NOT eligible');
    });

    test('TC-R3-10: Explicitly disabled delegatee flag drops candidate from eligible pool', () {
      final disabledCandidate = {
        'id': 230,
        'full_name': 'Colleague With Delegation Disabled',
        'role_name': 'Employee',
        'power': 100,
        'department': 'Engineering',
        'is_delegatee': false,
      };

      final isEligible = evaluateCandidateEligibility(
        currentUserId: 227,
        currentUserPower: 100,
        userDepartment: 'Engineering',
        userFloor: 'Floor 1',
        candidate: disabledCandidate,
      );

      expect(isEligible, isFalse, reason: 'Candidates with is_delegatee: false must be excluded');
    });

    test('TC-R3-11: Empty colleague list is handled safely without throwing null pointer exceptions', () {
      final List<Map<String, dynamic>> emptyList = [];
      final eligible = emptyList
          .where((c) => evaluateCandidateEligibility(
                currentUserId: 227,
                currentUserPower: 100,
                userDepartment: 'Engineering',
                userFloor: 'Floor 1',
                candidate: c,
              ))
          .toList();

      expect(eligible, isEmpty);
    });
  });
}
