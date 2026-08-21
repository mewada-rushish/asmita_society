import 'package:equatable/equatable.dart';

abstract class SearchState extends Equatable {
  const SearchState();
  
  @override
  List<Object> get props => [];
}

class SearchInitial extends SearchState {}

class SearchLoading extends SearchState {}

class SearchLoaded extends SearchState {
  final List<dynamic> results;
  final String query;
  final String module;

  const SearchLoaded({
    required this.results,
    required this.query,
    required this.module,
  });

  @override
  List<Object> get props => [results, query, module];
}

class SearchError extends SearchState {
  final String message;

  const SearchError({required this.message});

  @override
  List<Object> get props => [message];
}
