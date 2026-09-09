import 'package:equatable/equatable.dart';

enum GuardGateStatus { initial, loading, loaded, success, error }

class GuardGateState extends Equatable {
  final GuardGateStatus status;
  final List<dynamic> expectedInvites;
  final Map<String, dynamic>? searchResult;
  final String? errorMessage;
  final bool isSubmitting;

  const GuardGateState({
    this.status = GuardGateStatus.initial,
    this.expectedInvites = const [],
    this.searchResult,
    this.errorMessage,
    this.isSubmitting = false,
  });

  GuardGateState copyWith({
    GuardGateStatus? status,
    List<dynamic>? expectedInvites,
    Map<String, dynamic>? searchResult,
    String? errorMessage,
    bool? isSubmitting,
  }) {
    return GuardGateState(
      status: status ?? this.status,
      expectedInvites: expectedInvites ?? this.expectedInvites,
      searchResult: searchResult ?? this.searchResult,
      errorMessage: errorMessage ?? this.errorMessage,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }

  @override
  List<Object?> get props => [
        status,
        expectedInvites,
        searchResult,
        errorMessage,
        isSubmitting,
      ];
}
