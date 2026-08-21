import 'package:flutter_bloc/flutter_bloc.dart';
import 'search_event.dart';
import 'search_state.dart';
import '../../data/repositories/search_repository.dart';

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  final SearchRepository searchRepository;

  SearchBloc({required this.searchRepository})
      : super(SearchInitial()) {
    on<SearchInitiated>(_onSearchInitiated);
    on<SearchCleared>(_onSearchCleared);
  }

  Future<void> _onSearchInitiated(
    SearchInitiated event,
    Emitter<SearchState> emit,
  ) async {
    if (event.query.trim().isEmpty) {
      emit(SearchInitial());
      return;
    }

    emit(SearchLoading());
    try {
      final results = await searchRepository.searchInModule(
        module: event.module,
        query: event.query,
      );
      emit(SearchLoaded(
        results: results,
        query: event.query,
        module: event.module,
      ));
    } catch (e) {
      emit(SearchError(message: e.toString()));
    }
  }

  void _onSearchCleared(
    SearchCleared event,
    Emitter<SearchState> emit,
  ) {
    emit(SearchInitial());
  }
}
