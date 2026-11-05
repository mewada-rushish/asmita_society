import '../../features/auth/data/models/user_model.dart';

/// Universal Property & Role Resolver for AsmitA
/// 
/// Maps arbitrary database role strings (e.g. "Security Guard", "Plant Manager",
/// "Head of Department (HOD)", "Floor Receptionist", "Support Staff") into
/// the 6 foundational dashboard archetypes, guaranteeing zero unhandled
/// default fallback screens.
enum DashboardArchetype {
  guard,
  director,
  receptionist,
  employee,
  facility,
  owner,
  tenant,
}

enum AsmitaPropertyType {
  residential,
  commercial,
  industrial,
  villaCommunity,
  coWorking,
  retailMall,
}

class PropertyRoleResolver {
  /// Normalizes incoming database role strings into one of the canonical dashboard keys.
  static String normalizeRole(
    String? rawRole, {
    String? scope,
    int? power,
    bool? isIndustrial,
    String? propertyType,
  }) {
    if (rawRole == null || rawRole.trim().isEmpty) {
      return 'owner'; // Default fallback
    }

    final r = rawRole.toLowerCase().trim();
    final s = (scope ?? '').toLowerCase().trim();
    final p = power ?? 50;

    final bool industrial = isIndustrial == true ||
        (propertyType != null &&
            parsePropertyType(propertyType) == AsmitaPropertyType.industrial) ||
        s == 'industrial' ||
        s == 'corporate' ||
        r.contains('industrial') ||
        r.contains('corporate');

    // 1. Receptionist / Front Desk Archetype (Check before guard so 'Gate Receptionist' resolves to receptionist)
    if (r.contains('reception') || r.contains('concierge') || r.contains('front desk') || r.contains('lobby')) {
      return 'receptionist';
    }

    // 2. Guard / Security Checkpoint Archetype
    if (r.contains('guard') || r.contains('security') || r.contains('gate') || (s == 'operations' && r.contains('entry'))) {
      return 'guard';
    }

    // 3. Executive / Director Archetype
    // Map Admin and Property Manager in industrial properties so they do not fall through to 'owner'
    if (r.contains('director') ||
        r == 'md' ||
        r.contains('managing director') ||
        (industrial && (r.contains('admin') || r.contains('property manager') || r.contains('campus manager'))) ||
        (s == 'management' && p >= 75)) {
      return 'director';
    }

    // Plant Manager: check as manager / employee before generic 'plant' check
    if (r.contains('plant manager')) {
      if (industrial || (s == 'management' && p >= 75)) {
        return 'director';
      }
      return 'employee';
    }

    // 4. Logistics / Facility / Plant Support Archetype
    if (r.contains('facility') || r.contains('support') || r.contains('maintenance') || r.contains('logistics') || r.contains('bay') || r.contains('warehouse') || r.contains('plant')) {
      return 'facility';
    }

    // 5. Tenant Archetype (Only in residential settings)
    if (!industrial && (r.contains('tenant') || r.contains('lessee'))) {
      return 'tenant';
    }

    // 6. Corporate Host / Employee Archetype (HOD, Team Lead, Employee, Staff, Executive, Associate, Analyst)
    if (r.contains('employee') ||
        r.contains('staff') ||
        r.contains('executive') ||
        r.contains('host') ||
        r.contains('hod') ||
        r.contains('head') ||
        r.contains('lead') ||
        r.contains('engineer') ||
        r.contains('developer') ||
        r.contains('officer') ||
        r.contains('associate') ||
        r.contains('analyst') ||
        r.contains('manager') ||
        s == 'corporate' ||
        (industrial && !r.contains('director') && !r.contains('security') && !r.contains('guard') && !r.contains('reception'))) {
      return 'employee';
    }

    // 7. Owner Archetype (Residential)
    if (r.contains('owner') || r.contains('chairman') || r.contains('secretary') || r.contains('treasurer') || r.contains('committee') || s == 'resident') {
      return 'owner';
    }

    // Safe fallback based on scope and property context
    if (s == 'operations') return 'facility';
    if (industrial) return 'director';
    if (s == 'corporate' || s == 'management') return 'employee';
    return 'owner';
  }

  /// Normalizes property type string from DB
  static AsmitaPropertyType parsePropertyType(String? rawType) {
    if (rawType == null || rawType.trim().isEmpty) {
      return AsmitaPropertyType.residential;
    }

    final t = rawType.toUpperCase().trim();
    if (t.contains('INDUSTRIAL') || t.contains('CAMPUS') || t.contains('PARK')) {
      return AsmitaPropertyType.industrial;
    }
    if (t.contains('COMMERCIAL') || t.contains('OFFICE') || t.contains('TOWER')) {
      return AsmitaPropertyType.commercial;
    }
    if (t.contains('VILLA') || t.contains('ESTATE') || t.contains('TOWNSHIP')) {
      return AsmitaPropertyType.villaCommunity;
    }
    if (t.contains('CO_WORKING') || t.contains('COWORKING') || t.contains('SHARED')) {
      return AsmitaPropertyType.coWorking;
    }
    if (t.contains('MALL') || t.contains('RETAIL')) {
      return AsmitaPropertyType.retailMall;
    }
    return AsmitaPropertyType.residential;
  }

  /// Determines if current context or user belongs to an Industrial / Corporate campus
  static bool isIndustrialContext(UserModel? user, {String? propertyType}) {
    if (propertyType != null && propertyType.isNotEmpty) {
      if (parsePropertyType(propertyType) == AsmitaPropertyType.industrial) return true;
    }
    if (user == null) return false;
    if (user.propertyType != null && user.propertyType!.isNotEmpty) {
      if (parsePropertyType(user.propertyType) == AsmitaPropertyType.industrial) return true;
    }
    final s = (user.roleScope ?? '').toLowerCase();
    if (s == 'corporate' || s == 'industrial' || s == 'operations' || s == 'management') {
      return true;
    }
    final society = (user.societyName ?? '').toLowerCase();
    if (society.contains('corporate') || society.contains('industrial') || society.contains('campus') || society.contains('tech park')) {
      return true;
    }
    final r = normalizeRole(
      user.primaryRole,
      scope: user.roleScope,
      power: user.rolePower,
      isIndustrial: s == 'industrial' || s == 'corporate',
    );
    if (r == 'director' || r == 'employee' || r == 'receptionist' || r == 'facility') {
      return true;
    }
    return false;
  }

  /// Human-friendly display title for the role
  static String formatRoleTitle(String? rawRole) {
    if (rawRole == null || rawRole.trim().isEmpty) return 'Member';
    final normalized = normalizeRole(rawRole);
    switch (normalized) {
      case 'guard':
        return 'Security Guard';
      case 'director':
        return 'Executive Director';
      case 'receptionist':
        return 'Front Desk Receptionist';
      case 'employee':
        return 'Host / Employee';
      case 'facility':
        return 'Facility & Operations';
      case 'owner':
        return 'Property Owner';
      case 'tenant':
        return 'Resident Tenant';
      default:
        return rawRole;
    }
  }

  // ─────────────────────────────────────────────────────────
  // DYNAMIC CAPABILITY RESOLVERS (PORTAL APP_SETTINGS AWARE)
  // ─────────────────────────────────────────────────────────

  /// Checks whether a user has permission to manage visitors / issue passes.
  /// Dynamically consults portal-configured permissions if loaded;
  /// gracefully falls back to role heuristic when permissions are not present.
  static bool canIssuePasses(UserModel? user, {String? role}) {
    if (user != null && user.permissions.isNotEmpty) {
      return user.canIssuePasses;
    }
    final normalized = normalizeRole(role ?? user?.primaryRole);
    return normalized != 'guard';
  }

  /// Checks whether a user has permission to approve or reject gate visitor requests.
  static bool canApproveVisits(UserModel? user, {String? role}) {
    if (user != null && user.permissions.isNotEmpty) {
      return user.canManageVisitors;
    }
    final normalized = normalizeRole(role ?? user?.primaryRole);
    return normalized == 'owner' ||
        normalized == 'tenant' ||
        normalized == 'director' ||
        normalized == 'employee';
  }

  /// Checks whether a user can manage facility / maintenance operations.
  static bool canManageFacilityTasks(UserModel? user, {String? role}) {
    if (user != null && user.permissions.isNotEmpty) {
      return user.hasPermission('canManageFacilityTasks') ||
          user.canManageServiceBookings;
    }
    final normalized = normalizeRole(role ?? user?.primaryRole);
    return normalized == 'facility' || normalized == 'director';
  }

  /// Checks whether a user has member/resident management privileges.
  static bool canManageMembers(UserModel? user, {String? role}) {
    if (user != null && user.permissions.isNotEmpty) {
      return user.canManageMembers || user.canManageUsers;
    }
    final normalized = normalizeRole(role ?? user?.primaryRole);
    return normalized == 'director' || normalized == 'owner';
  }

  /// Checks whether a user can manage domestic staff / helpers.
  static bool canManageDomesticStaff(UserModel? user, {String? role}) {
    if (user != null && user.permissions.isNotEmpty) {
      return user.canManageDomesticStaff;
    }
    final normalized = normalizeRole(role ?? user?.primaryRole);
    return normalized == 'owner' ||
        normalized == 'tenant' ||
        normalized == 'director';
  }

  /// Checks whether a user can manage vehicle tracking & parking.
  static bool canManageVehicles(UserModel? user, {String? role}) {
    if (user != null && user.permissions.isNotEmpty) {
      return user.canManageVehicleTracking;
    }
    final normalized = normalizeRole(role ?? user?.primaryRole);
    return normalized != 'receptionist';
  }

  /// Checks whether a user can manage society notices and announcements.
  static bool canManageNotices(UserModel? user, {String? role}) {
    if (user != null && user.permissions.isNotEmpty) {
      return user.canManageNotices;
    }
    final normalized = normalizeRole(role ?? user?.primaryRole);
    return normalized == 'director' || normalized == 'owner';
  }

  /// Checks whether a user can manage society payments / dues.
  static bool canManagePayments(UserModel? user, {String? role}) {
    if (user != null && user.permissions.isNotEmpty) {
      return user.canManagePayments;
    }
    final normalized = normalizeRole(role ?? user?.primaryRole);
    return normalized != 'guard';
  }

  /// Checks whether a user can book services / amenities.
  static bool canManageServiceBookings(UserModel? user, {String? role}) {
    if (user != null && user.permissions.isNotEmpty) {
      return user.canManageServiceBookings;
    }
    final normalized = normalizeRole(role ?? user?.primaryRole);
    return normalized != 'guard';
  }

  /// Checks whether an employee/corporate user has authority to delegate approvals.
  /// Dynamically consults portal-configured permissions if loaded (canDelegate);
  /// gracefully falls back to corporate hierarchy heuristic when permissions are not present.
  static bool canDelegate(UserModel? user, {String? designation, String? role}) {
    if (user != null && user.permissions.isNotEmpty) {
      if (user.permissions.containsKey('canDelegate')) {
        return user.canDelegate;
      }
    }

    final normalized = normalizeRole(role ?? user?.primaryRole);
    // Security guards, visitors, front desk receptionists, and facility staff cannot delegate visitor approvals
    if (normalized == 'guard' ||
        normalized == 'visitor' ||
        normalized == 'receptionist' ||
        normalized == 'facility') {
      return false;
    }

    // Corporate leadership and employee hosts can delegate
    return normalized == 'director' ||
        normalized == 'employee' ||
        normalized == 'owner' ||
        normalized == 'tenant';
  }
  /// Checks whether an employee/corporate user has authority to invite team members.
  static bool canInviteTeamMembers(UserModel? user, {String? designation, String? role}) {
    if (user != null && user.permissions.isNotEmpty) {
      if (user.permissions.containsKey('canManageUsers')) {
        return user.canManageUsers;
      }
      if (user.permissions.containsKey('canManageMembers')) {
        return user.canManageMembers;
      }
    }

    final normalized = normalizeRole(role ?? user?.primaryRole);
    if (normalized == 'director') return true;

    if (user != null) {
      final roleLower = user.primaryRole.toLowerCase();
      final desigLower = (designation ?? user.designation).toLowerCase();
      final isHod = user.roleDetails?['is_hod'] == true ||
          roleLower.contains('hod') ||
          desigLower.contains('hod') ||
          desigLower.contains('head');
      final isTL = roleLower.contains('team leader') ||
          roleLower.contains('lead') ||
          desigLower.contains('lead') ||
          desigLower.contains('tl');
      final isDirector = (user.rolePower ?? 0) >= 500 ||
          roleLower.contains('director') ||
          desigLower.contains('director');
      if (isHod || isTL || isDirector) return true;
    }

    return normalized == 'director' || normalized == 'employee';
  }
}
