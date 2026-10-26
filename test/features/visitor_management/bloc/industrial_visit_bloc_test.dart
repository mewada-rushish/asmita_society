import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:asmita_society/features/visitor_management/bloc/industrial_visit_bloc.dart';
import 'package:asmita_society/features/visitor_management/bloc/industrial_visit_event.dart';
import 'package:asmita_society/features/visitor_management/bloc/industrial_visit_state.dart';
import 'package:asmita_society/features/visitor_management/data/models/industrial_visit_model.dart';
import 'package:asmita_society/features/visitor_management/data/repositories/industrial_visit_repository.dart';

class MockIndustrialVisitRepository extends Mock implements IndustrialVisitRepository {}

void main() {
  late MockIndustrialVisitRepository mockRepository;

  setUp(() {
    mockRepository = MockIndustrialVisitRepository();
  });

  group('IndustrialVisitBloc Tests', () {
    const testVisit = IndustrialVisitModel(
      id: 10,
      requestNumber: 'AH-2026-0010',
      propertyId: 114,
      visitorName: 'Rajesh Sharma',
      status: IndustrialVisitStatus.awaitingHost,
    );

    blocTest<IndustrialVisitBloc, IndustrialVisitState>(
      'emits [loading, loaded] when LoadIndustrialVisits succeeds',
      build: () {
        when(() => mockRepository.getVisits(
              status: any(named: 'status'),
              arrivalMode: any(named: 'arrivalMode'),
              departmentId: any(named: 'departmentId'),
              hostUserId: any(named: 'hostUserId'),
            )).thenAnswer((_) async => [testVisit]);
        return IndustrialVisitBloc(repository: mockRepository);
      },
      act: (bloc) => bloc.add(const LoadIndustrialVisits()),
      expect: () => [
        const IndustrialVisitState(status: IndustrialVisitBlocStatus.loading),
        const IndustrialVisitState(
          status: IndustrialVisitBlocStatus.loaded,
          visits: [testVisit],
        ),
      ],
    );

    blocTest<IndustrialVisitBloc, IndustrialVisitState>(
      'emits [loading, actionSuccess] when DecideVisitEvent approves visit',
      build: () {
        when(() => mockRepository.handleVisitAction(
              10,
              action: 'APPROVE',
              assignedUserId: any(named: 'assignedUserId'),
              cabinId: any(named: 'cabinId'),
              deskId: any(named: 'deskId'),
              rejectionReason: any(named: 'rejectionReason'),
            )).thenAnswer((_) async => {'success': true, 'message': 'Approved'});
        when(() => mockRepository.getVisits()).thenAnswer((_) async => [
              const IndustrialVisitModel(
                id: 10,
                requestNumber: 'AH-2026-0010',
                propertyId: 114,
                visitorName: 'Rajesh Sharma',
                status: IndustrialVisitStatus.approved,
              )
            ]);
        return IndustrialVisitBloc(repository: mockRepository);
      },
      act: (bloc) => bloc.add(const DecideVisitEvent(visitId: 10, action: 'APPROVE')),
      expect: () => [
        const IndustrialVisitState(status: IndustrialVisitBlocStatus.loading),
        const IndustrialVisitState(
          status: IndustrialVisitBlocStatus.actionSuccess,
          successMessage: 'Approved',
          visits: [
            IndustrialVisitModel(
              id: 10,
              requestNumber: 'AH-2026-0010',
              propertyId: 114,
              visitorName: 'Rajesh Sharma',
              status: IndustrialVisitStatus.approved,
            ),
          ],
        ),
      ],
    );

    blocTest<IndustrialVisitBloc, IndustrialVisitState>(
      'emits [loading, actionSuccess] on ClockInDutyEvent',
      build: () {
        when(() => mockRepository.clockInDuty(gateId: 1)).thenAnswer((_) async => {'success': true});
        return IndustrialVisitBloc(repository: mockRepository);
      },
      act: (bloc) => bloc.add(const ClockInDutyEvent(1)),
      expect: () => [
        const IndustrialVisitState(status: IndustrialVisitBlocStatus.loading),
        const IndustrialVisitState(
          status: IndustrialVisitBlocStatus.actionSuccess,
          activeGateId: 1,
          isDutyActive: true,
          successMessage: 'Clocked in at Gate 1.',
        ),
      ],
    );
  });
}
