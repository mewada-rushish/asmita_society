import 'package:equatable/equatable.dart';

abstract class SearchEvent extends Equatable {
  const SearchEvent();

  @override
  List<Object> get props => [];
}

class SearchInitiated extends SearchEvent {
  final String query;
  final String module;

  const SearchInitiated({required this.query, required this.module});

  @override
  List<Object> get props => [query, module];
}

class SearchCleared extends SearchEvent {}
