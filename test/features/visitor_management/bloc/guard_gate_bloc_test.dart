import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:asmita_society/features/visitor_management/bloc/guard_gate_bloc.dart';
import 'package:asmita_society/features/visitor_management/bloc/guard_gate_event.dart';
import 'package:asmita_society/features/visitor_management/bloc/guard_gate_state.dart';
import 'package:asmita_society/features/visitor_management/data/repositories/guard_gate_repository.dart';

class MockGuardGateRepository extends Mock implements GuardGateRepository {}

void main() {
  late MockGuardGateRepository mockRepository;

  setUp(() {
    mockRepository = MockGuardGateRepository();
  });

  group('GuardGateBloc', () {
    blocTest<GuardGateBloc, GuardGateState>(
      'emits [loading, loaded] when LoadExpectedInvites is successful',
      build: () {
        when(() => mockRepository.getExpectedInvites()).thenAnswer((_) async => []);
        return GuardGateBloc(repository: mockRepository);
      },
      act: (bloc) => bloc.add(LoadExpectedInvites()),
      expect: () => [
        const GuardGateState(status: GuardGateStatus.loading),
        const GuardGateState(status: GuardGateStatus.loaded, expectedInvites: []),
      ],
      verify: (_) {
        verify(() => mockRepository.getExpectedInvites()).called(1);
      },
    );

    blocTest<GuardGateBloc, GuardGateState>(
      'emits [loading, error] when LoadExpectedInvites fails',
      build: () {
        when(() => mockRepository.getExpectedInvites()).thenThrow(Exception('API error'));
        return GuardGateBloc(repository: mockRepository);
      },
      act: (bloc) => bloc.add(LoadExpectedInvites()),
      expect: () => [
        const GuardGateState(status: GuardGateStatus.loading),
        const GuardGateState(status: GuardGateStatus.error, errorMessage: 'Exception: API error'),
      ],
    );

    blocTest<GuardGateBloc, GuardGateState>(
      'emits [isSubmitting, success] when CheckInPreApprovedVisitor is successful',
      build: () {
        when(() => mockRepository.checkInPreApproved('123')).thenAnswer((_) async {});
        // Also mock the follow-up call to LoadExpectedInvites
        when(() => mockRepository.getExpectedInvites()).thenAnswer((_) async => []);
        return GuardGateBloc(repository: mockRepository);
      },
      act: (bloc) => bloc.add(const CheckInPreApprovedVisitor('123')),
      expect: () => [
        const GuardGateState(isSubmitting: true),
        const GuardGateState(status: GuardGateStatus.success, isSubmitting: false, searchResult: null),
        const GuardGateState(status: GuardGateStatus.loading, isSubmitting: false, searchResult: null),
        const GuardGateState(status: GuardGateStatus.loaded, expectedInvites: [], isSubmitting: false, searchResult: null),
      ],
    );

    blocTest<GuardGateBloc, GuardGateState>(
      'emits [isSubmitting, error] when CheckInPreApprovedVisitor fails',
      build: () {
        when(() => mockRepository.checkInPreApproved('123')).thenThrow(Exception('Check in failed'));
        return GuardGateBloc(repository: mockRepository);
      },
      act: (bloc) => bloc.add(const CheckInPreApprovedVisitor('123')),
      expect: () => [
        const GuardGateState(isSubmitting: true),
        const GuardGateState(status: GuardGateStatus.error, isSubmitting: false, errorMessage: 'Exception: Check in failed'),
      ],
    );

    blocTest<GuardGateBloc, GuardGateState>(
      'emits [loading, loaded] when LoadGuardHistory is successful',
      build: () {
        when(() => mockRepository.getGuardHistory()).thenAnswer((_) async => [{'id': 1}]);
        return GuardGateBloc(repository: mockRepository);
      },
      act: (bloc) => bloc.add(LoadGuardHistory()),
      expect: () => [
        const GuardGateState(status: GuardGateStatus.loading),
        const GuardGateState(status: GuardGateStatus.loaded, historyRecords: [{'id': 1}]),
      ],
    );

    blocTest<GuardGateBloc, GuardGateState>(
      'emits [loading, error] when LoadGuardHistory fails',
      build: () {
        when(() => mockRepository.getGuardHistory()).thenThrow(Exception('History failed'));
        return GuardGateBloc(repository: mockRepository);
      },
      act: (bloc) => bloc.add(LoadGuardHistory()),
      expect: () => [
        const GuardGateState(status: GuardGateStatus.loading),
        const GuardGateState(status: GuardGateStatus.error, errorMessage: 'Exception: History failed'),
      ],
    );

    blocTest<GuardGateBloc, GuardGateState>(
      'emits [isSubmitting, success] when SearchInviteByCode is successful',
      build: () {
        when(() => mockRepository.searchInvite('123456')).thenAnswer((_) async => {'id': 1});
        return GuardGateBloc(repository: mockRepository);
      },
      act: (bloc) => bloc.add(const SearchInviteByCode('123456')),
      expect: () => [
        const GuardGateState(isSubmitting: true, searchResult: null),
        const GuardGateState(status: GuardGateStatus.success, isSubmitting: false, searchResult: {'id': 1}),
      ],
    );

    blocTest<GuardGateBloc, GuardGateState>(
      'emits [isSubmitting, error] when SearchInviteByCode fails',
      build: () {
        when(() => mockRepository.searchInvite('123456')).thenThrow(Exception('Search failed'));
        return GuardGateBloc(repository: mockRepository);
      },
      act: (bloc) => bloc.add(const SearchInviteByCode('123456')),
      expect: () => [
        const GuardGateState(isSubmitting: true, searchResult: null),
        const GuardGateState(status: GuardGateStatus.error, isSubmitting: false, errorMessage: 'Exception: Search failed'),
      ],
    );

    blocTest<GuardGateBloc, GuardGateState>(
      'emits [isSubmitting, success] when SubmitWalkInVisitor is successful',
      build: () {
        when(() => mockRepository.submitWalkInVisitor(any())).thenAnswer((_) async => {'id': 1});
        return GuardGateBloc(repository: mockRepository);
      },
      act: (bloc) => bloc.add(SubmitWalkInVisitor(const [{'name': 'John'}])),
      expect: () => [
        const GuardGateState(isSubmitting: true),
        const GuardGateState(status: GuardGateStatus.success, isSubmitting: false),
      ],
    );

    blocTest<GuardGateBloc, GuardGateState>(
      'emits [isSubmitting, error] when SubmitWalkInVisitor fails',
      build: () {
        when(() => mockRepository.submitWalkInVisitor(any())).thenThrow(Exception('Submit failed'));
        return GuardGateBloc(repository: mockRepository);
      },
      act: (bloc) => bloc.add(SubmitWalkInVisitor(const [{'name': 'John'}])),
      expect: () => [
        const GuardGateState(isSubmitting: true),
        const GuardGateState(status: GuardGateStatus.error, isSubmitting: false, errorMessage: 'Exception: Submit failed'),
      ],
    );
  });
}
