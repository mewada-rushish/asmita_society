import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:asmita_society/features/visitor_management/bloc/visitor_bloc.dart';
import 'package:asmita_society/features/visitor_management/bloc/visitor_event.dart';
import 'package:asmita_society/features/visitor_management/bloc/visitor_state.dart';
import 'package:asmita_society/features/visitor_management/data/repositories/visitor_repository.dart';

class MockVisitorRepository extends Mock implements VisitorRepository {}

void main() {
  late VisitorBloc visitorBloc;
  late MockVisitorRepository mockVisitorRepository;

  setUp(() {
    mockVisitorRepository = MockVisitorRepository();
    visitorBloc = VisitorBloc(visitorRepository: mockVisitorRepository);
  });

  tearDown(() {
    visitorBloc.close();
  });

  group('VisitorBloc', () {
    test('initial state is VisitorInitial', () {
      expect(visitorBloc.state, isA<VisitorInitial>());
    });

    blocTest<VisitorBloc, VisitorState>(
      'emits [VisitorLoading, VisitorHistoryLoaded] when LoadMyHistory succeeds',
      build: () {
        when(() => mockVisitorRepository.getMyHistory(residentId: any(named: 'residentId'))).thenAnswer(
          (_) async => [
            {'id': 1, 'visitor_name': 'Test Visitor'}
          ],
        );
        return visitorBloc;
      },
      act: (bloc) => bloc.add(const LoadMyHistory(residentId: 1)),
      expect: () => [
        isA<VisitorLoading>(),
        isA<VisitorHistoryLoaded>().having((state) => state.history.length, 'history length', 1),
      ],
    );

    blocTest<VisitorBloc, VisitorState>(
      'emits [VisitorLoading, VisitorError] when LoadMyHistory fails',
      build: () {
        when(() => mockVisitorRepository.getMyHistory(residentId: any(named: 'residentId'))).thenThrow(Exception('Server unreachable'));
        return visitorBloc;
      },
      act: (bloc) => bloc.add(const LoadMyHistory(residentId: 1)),
      expect: () => [
        isA<VisitorLoading>(),
        isA<VisitorError>().having((state) => state.message, 'message', contains('Server unreachable')),
      ],
    );
  });
}
