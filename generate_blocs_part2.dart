import 'dart:io';

void main() async {
  final blocDir = Directory('lib/features/menu/bloc');

  final models = [
    {'name': 'Preferences', 'model': 'UserPreferencesModel', 'repo': 'PreferencesRepository', 'repo_file': 'preferences_repository.dart', 'model_file': 'user_preferences_model.dart', 'is_list': false},
    {'name': 'Society', 'model': 'SocietyModel', 'repo': 'SocietyRepository', 'repo_file': 'society_repository.dart', 'model_file': 'society_model.dart', 'is_list': false},
    {'name': 'Support', 'model': 'TicketModel', 'repo': 'SupportRepository', 'repo_file': 'support_repository.dart', 'model_file': 'ticket_model.dart', 'is_list': true},
    {'name': 'HistoryRequest', 'model': 'HistoryRequestModel', 'repo': 'HistoryRequestRepository', 'repo_file': 'history_request_repository.dart', 'model_file': 'history_request_model.dart', 'is_list': true},
  ];

  for (final m in models) {
    final name = m['name'] as String;
    final lowerName = name.toLowerCase();
    final model = m['model'] as String;
    final repo = m['repo'] as String;
    final repoFile = m['repo_file'] as String;
    final modelFile = m['model_file'] as String;
    final isList = m['is_list'] == true;
    final itemType = isList ? 'List<$model>' : '$model?';

    final blocFile = File('${blocDir.path}/${lowerName}_bloc.dart');
    final eventFile = File('${blocDir.path}/${lowerName}_event.dart');
    final stateFile = File('${blocDir.path}/${lowerName}_state.dart');

    await eventFile.writeAsString('''
import 'package:equatable/equatable.dart';

abstract class ${name}Event extends Equatable {
  const ${name}Event();
  @override
  List<Object?> get props => [];
}

class Load${name} extends ${name}Event {
  final bool showLoading;
  const Load${name}({this.showLoading = true});
  @override
  List<Object?> get props => [showLoading];
}
''');

    await stateFile.writeAsString('''
import 'package:equatable/equatable.dart';
import '../../data/models/$modelFile';

abstract class ${name}State extends Equatable {
  const ${name}State();
  @override
  List<Object?> get props => [];
}

class ${name}Initial extends ${name}State {}

class ${name}Loading extends ${name}State {}

class ${name}Loaded extends ${name}State {
  final $itemType items;
  const ${name}Loaded(this.items);
  @override
  List<Object?> get props => [items];
}

class ${name}Error extends ${name}State {
  final String message;
  const ${name}Error(this.message);
  @override
  List<Object?> get props => [message];
}
''');

    await blocFile.writeAsString('''
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/$repoFile';
import '${lowerName}_event.dart';
import '${lowerName}_state.dart';

class ${name}Bloc extends Bloc<${name}Event, ${name}State> {
  final $repo repository;

  ${name}Bloc({required this.repository}) : super(${name}Initial()) {
    on<Load${name}>(_onLoad${name});
  }

  Future<void> _onLoad${name}(Load${name} event, Emitter<${name}State> emit) async {
    if (event.showLoading) emit(${name}Loading());
    try {
      final items = await repository.get${name == 'HistoryRequest' ? 'HistoryRequests' : name == 'Support' ? 'Tickets' : name}();
      emit(${name}Loaded(items));
    } catch (e) {
      emit(${name}Error(e.toString()));
    }
  }
}
''');
  }

  print('Generated remaining BLoC templates.');
}
