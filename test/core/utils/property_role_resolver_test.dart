import 'package:flutter_test/flutter_test.dart';
import 'package:asmita_society/core/utils/property_role_resolver.dart';

void main() {
  group('PropertyRoleResolver Tests', () {
    test('normalizes guard and security variants to "guard"', () {
      expect(PropertyRoleResolver.normalizeRole('guard'), 'guard');
      expect(PropertyRoleResolver.normalizeRole('Security Guard'), 'guard');
      expect(PropertyRoleResolver.normalizeRole('security'), 'guard');
      expect(PropertyRoleResolver.normalizeRole('Gate Security Officer'), 'guard');
      expect(PropertyRoleResolver.normalizeRole('Main Gate Guard'), 'guard');
      expect(PropertyRoleResolver.normalizeRole('Valet Guard'), 'guard');
    });

    test('normalizes director and executive variants to "director"', () {
      expect(PropertyRoleResolver.normalizeRole('director'), 'director');
      expect(PropertyRoleResolver.normalizeRole('Director'), 'director');
      expect(PropertyRoleResolver.normalizeRole('Executive Director'), 'director');
      expect(PropertyRoleResolver.normalizeRole('Managing Director'), 'director');
      expect(PropertyRoleResolver.normalizeRole('MD'), 'director');
      expect(PropertyRoleResolver.normalizeRole('Plant Manager', scope: 'management', power: 85), 'director');
    });

    test('normalizes receptionist and front desk variants to "receptionist"', () {
      expect(PropertyRoleResolver.normalizeRole('receptionist'), 'receptionist');
      expect(PropertyRoleResolver.normalizeRole('Floor Receptionist'), 'receptionist');
      expect(PropertyRoleResolver.normalizeRole('Gate Receptionist'), 'receptionist');
      expect(PropertyRoleResolver.normalizeRole('Lobby Concierge'), 'receptionist');
      expect(PropertyRoleResolver.normalizeRole('Front Desk Executive'), 'receptionist');
    });

    test('normalizes employee, HOD, and team lead variants to "employee"', () {
      expect(PropertyRoleResolver.normalizeRole('employee'), 'employee');
      expect(PropertyRoleResolver.normalizeRole('Employee'), 'employee');
      expect(PropertyRoleResolver.normalizeRole('Head of Department (HOD)'), 'employee');
      expect(PropertyRoleResolver.normalizeRole('Team Lead (TL)'), 'employee');
      expect(PropertyRoleResolver.normalizeRole('Host'), 'employee');
      expect(PropertyRoleResolver.normalizeRole('Senior Engineer'), 'employee');
    });

    test('normalizes facility and support staff variants to "facility"', () {
      expect(PropertyRoleResolver.normalizeRole('facility'), 'facility');
      expect(PropertyRoleResolver.normalizeRole('facility_staff'), 'facility');
      expect(PropertyRoleResolver.normalizeRole('Support Staff'), 'facility');
      expect(PropertyRoleResolver.normalizeRole('Maintenance Technician'), 'facility');
      expect(PropertyRoleResolver.normalizeRole('Loading Bay Supervisor'), 'facility');
      expect(PropertyRoleResolver.normalizeRole('Logistics Coordinator'), 'facility');
    });

    test('normalizes owner and committee variants to "owner"', () {
      expect(PropertyRoleResolver.normalizeRole('owner'), 'owner');
      expect(PropertyRoleResolver.normalizeRole('Owner'), 'owner');
      expect(PropertyRoleResolver.normalizeRole('Commercial Owner'), 'owner');
      expect(PropertyRoleResolver.normalizeRole('Chairman'), 'owner');
      expect(PropertyRoleResolver.normalizeRole('Secretary'), 'owner');
      expect(PropertyRoleResolver.normalizeRole('Treasurer'), 'owner');
      expect(PropertyRoleResolver.normalizeRole('Committee Member'), 'owner');
    });

    test('normalizes tenant variants to "tenant"', () {
      expect(PropertyRoleResolver.normalizeRole('tenant'), 'tenant');
      expect(PropertyRoleResolver.normalizeRole('Tenant'), 'tenant');
      expect(PropertyRoleResolver.normalizeRole('Commercial Tenant'), 'tenant');
      expect(PropertyRoleResolver.normalizeRole('Office Lessee'), 'tenant');
    });

    test('safely falls back for null or empty role', () {
      expect(PropertyRoleResolver.normalizeRole(null), 'owner');
      expect(PropertyRoleResolver.normalizeRole(''), 'owner');
      expect(PropertyRoleResolver.normalizeRole('   '), 'owner');
    });

    test('correctly parses property types', () {
      expect(PropertyRoleResolver.parsePropertyType('INDUSTRIAL'), AsmitaPropertyType.industrial);
      expect(PropertyRoleResolver.parsePropertyType('Industrial Park'), AsmitaPropertyType.industrial);
      expect(PropertyRoleResolver.parsePropertyType('COMMERCIAL'), AsmitaPropertyType.commercial);
      expect(PropertyRoleResolver.parsePropertyType('Commercial Shops'), AsmitaPropertyType.commercial);
      expect(PropertyRoleResolver.parsePropertyType('VILLA_COMMUNITY'), AsmitaPropertyType.villaCommunity);
      expect(PropertyRoleResolver.parsePropertyType('CO_WORKING'), AsmitaPropertyType.coWorking);
      expect(PropertyRoleResolver.parsePropertyType('RETAIL_MALL'), AsmitaPropertyType.retailMall);
      expect(PropertyRoleResolver.parsePropertyType('RESIDENTIAL'), AsmitaPropertyType.residential);
      expect(PropertyRoleResolver.parsePropertyType(null), AsmitaPropertyType.residential);
    });
  });
}
