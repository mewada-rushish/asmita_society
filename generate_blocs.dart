import 'dart:io';

void main() async {
  final blocDir = Directory('lib/features/menu/bloc');
  if (!await blocDir.exists()) {
    await blocDir.create(recursive: true);
  }

  final models = [
    {'name': 'Family', 'model': 'FamilyMemberModel', 'repo': 'FamilyRepository', 'repo_file': 'family_repository.dart', 'model_file': 'family_member_model.dart'},
    {'name': 'Pets', 'model': 'PetModel', 'repo': 'PetsRepository', 'repo_file': 'pets_repository.dart', 'model_file': 'pet_model.dart'},
    {'name': 'Vehicles', 'model': 'VehicleModel', 'repo': 'VehiclesRepository', 'repo_file': 'vehicles_repository.dart', 'model_file': 'vehicle_model.dart'},
    {'name': 'Tenant', 'model': 'TenantModel', 'repo': 'TenantRepository', 'repo_file': 'tenant_repository.dart', 'model_file': 'tenant_model.dart'},
  ];

  for (final m in models) {
    final name = m['name']!;
    final lowerName = name.toLowerCase();
    final model = m['model']!;
    final repo = m['repo']!;
    final repoFile = m['repo_file']!;
    final modelFile = m['model_file']!;

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
  final List<$model> items;
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
      final items = await repository.get${name}();
      emit(${name}Loaded(items));
    } catch (e) {
      emit(${name}Error(e.toString()));
    }
  }
}
''');
  }

  print('Generated basic BLoC templates.');
}
