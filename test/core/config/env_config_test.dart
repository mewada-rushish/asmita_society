import 'package:flutter_test/flutter_test.dart';
import 'package:asmita_society/core/config/env_config.dart';

void main() {
  group('EnvConfig', () {
    test('currentEnvironment returns production', () {
      expect(EnvConfig.currentEnvironment, AppEnvironment.production);
    });

    test('baseUrl returns expected URL', () {
      expect(EnvConfig.baseUrl.isNotEmpty, true);
    });

    test('login endpoints are properly constructed', () {
      expect(EnvConfig.loginInitiate, endsWith('/app-api/auth/otp/initiate'));
      expect(EnvConfig.loginVerify, endsWith('/app-api/auth/otp/verify'));
      expect(EnvConfig.loginStatus, endsWith('/app-api/auth/otp/status'));
      expect(EnvConfig.register, endsWith('/app-api/auth/otp/register'));
      expect(EnvConfig.logout, endsWith('/app-api/auth/logout'));
    });

    test('visitor management endpoints are properly constructed', () {
      expect(EnvConfig.preApprovedInvites, endsWith('/app-api/pre-approved-invites'));
      expect(EnvConfig.myPreApprovedInvites, endsWith('/app-api/pre-approved-invites/my'));
      expect(EnvConfig.residentVisitorRequests, endsWith('/app-api/resident/visitor-requests'));
      expect(EnvConfig.usersMe, endsWith('/app-api/users/me'));
    });

    test('guard endpoints are properly constructed', () {
      expect(EnvConfig.gateSearchInvite, endsWith('/app-api/gate/pre-approved-invites/search'));
      expect(EnvConfig.gateExpectedInvites, endsWith('/app-api/gate/pre-approved-invites/expected'));
      expect(EnvConfig.gateCheckInInvite('123'), endsWith('/app-api/gate/pre-approved-invites/123/check-in'));
      expect(EnvConfig.guardVisitorEntries, endsWith('/app-api/guard/visitor-entries'));
      expect(EnvConfig.createVisitorEntry, endsWith('/app-api/visitor-entries'));
    });

    test('global search endpoint is properly constructed', () {
      expect(EnvConfig.globalSearch, endsWith('/app-api/search'));
    });

    test('community endpoints are properly constructed', () {
      expect(EnvConfig.communityMessages, endsWith('/app-api/community/messages'));
      expect(EnvConfig.communityUpload, endsWith('/app-api/community/upload'));
    });

    test('properties endpoints are properly constructed', () {
      expect(EnvConfig.societies, endsWith('/app-api/properties/societies'));
      expect(EnvConfig.towers, endsWith('/app-api/properties/towers'));
      expect(EnvConfig.floors, endsWith('/app-api/properties/floors'));
      expect(EnvConfig.flats, endsWith('/app-api/properties/flats'));
      expect(EnvConfig.linkFlat, endsWith('/app-api/properties/link-flat'));
    });

    test('menu sub-pages endpoints are properly constructed', () {
      expect(EnvConfig.familyMembers, endsWith('/app-api/family-members'));
      expect(EnvConfig.userVehicles, endsWith('/app-api/vehicles'));
      expect(EnvConfig.userPets, endsWith('/app-api/pets'));
      expect(EnvConfig.parkingSlots, endsWith('/app-api/parking-slots'));
      expect(EnvConfig.committeeMembers, endsWith('/app-api/society/committee-members'));
      expect(EnvConfig.societyRules, endsWith('/app-api/society/rules'));
      expect(EnvConfig.societyDocuments, endsWith('/app-api/society/documents'));
      expect(EnvConfig.supportTickets, endsWith('/app-api/support-tickets'));
      expect(EnvConfig.userPreferences, endsWith('/app-api/preferences'));
    });

    test('industrial endpoints are properly constructed', () {
      expect(EnvConfig.industrialVisits, endsWith('/app-api/industrial/visits'));
      expect(EnvConfig.industrialGuardDraft, endsWith('/app-api/industrial/guard/draft'));
      expect(EnvConfig.industrialGuardDrafts, endsWith('/app-api/industrial/guard/drafts'));
      expect(EnvConfig.industrialDelivery, endsWith('/app-api/industrial/visits/delivery'));
      expect(EnvConfig.industrialHandover(42), endsWith('/app-api/industrial/visits/42/confirm-handover'));
      expect(EnvConfig.industrialAction(42), endsWith('/app-api/industrial/visits/42/action'));
      expect(EnvConfig.industrialAcknowledge(42), endsWith('/app-api/industrial/visits/42/acknowledge'));
      expect(EnvConfig.industrialOverride(42), endsWith('/app-api/industrial/visits/42/override'));
      expect(EnvConfig.industrialCheckIn(42), endsWith('/app-api/industrial/visits/42/check-in'));
      expect(EnvConfig.industrialCheckOut(42), endsWith('/app-api/industrial/visits/42/check-out'));
      expect(EnvConfig.industrialGuardClockIn, endsWith('/app-api/industrial/guard/duty/clock-in'));
      expect(EnvConfig.industrialGuardClockOut, endsWith('/app-api/industrial/guard/duty/clock-out'));
      expect(EnvConfig.industrialSettings, endsWith('/app-api/industrial/settings'));
      expect(EnvConfig.industrialOutageMode, endsWith('/app-api/industrial/outage-mode'));
    });
  });
}
