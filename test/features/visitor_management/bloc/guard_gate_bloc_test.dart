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
  });
}
