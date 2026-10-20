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
  }) {
    if (rawRole == null || rawRole.trim().isEmpty) {
      return 'owner'; // Default fallback
    }

    final r = rawRole.toLowerCase().trim();
    final s = (scope ?? '').toLowerCase().trim();
    final p = power ?? 50;

    // 1. Receptionist / Front Desk Archetype (Check before guard so 'Gate Receptionist' resolves to receptionist)
    if (r.contains('reception') || r.contains('concierge') || r.contains('front desk') || r.contains('lobby')) {
      return 'receptionist';
    }

    // 2. Guard / Security Checkpoint Archetype
    if (r.contains('guard') || r.contains('security') || r.contains('gate') || (s == 'operations' && r.contains('entry'))) {
      return 'guard';
    }

    // 3. Executive / Director Archetype
    if (r.contains('director') || r == 'md' || r.contains('managing director') || (s == 'management' && p >= 75)) {
      return 'director';
    }

    // 4. Logistics / Facility / Plant Support Archetype
    if (r.contains('facility') || r.contains('support') || r.contains('maintenance') || r.contains('logistics') || r.contains('bay') || r.contains('warehouse') || r.contains('plant')) {
      return 'facility';
    }

    // 5. Tenant Archetype
    if (r.contains('tenant') || r.contains('lessee')) {
      return 'tenant';
    }

    // 6. Owner Archetype
    if (r.contains('owner') || r.contains('chairman') || r.contains('secretary') || r.contains('treasurer') || r.contains('committee') || s == 'resident') {
      return 'owner';
    }

    // 7. Corporate Host / Employee Archetype (HOD, Team Lead, Employee, Staff)
    if (r.contains('employee') || r.contains('staff') || r.contains('host') || r.contains('hod') || r.contains('head') || r.contains('lead') || r.contains('engineer') || r.contains('manager') || s == 'corporate') {
      return 'employee';
    }

    // Safe fallback based on scope
    if (s == 'operations') return 'facility';
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
}
