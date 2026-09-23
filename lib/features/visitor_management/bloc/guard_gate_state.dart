import 'package:equatable/equatable.dart';

enum GuardGateStatus { initial, loading, loaded, success, error }

class GuardGateState extends Equatable {
  final GuardGateStatus status;
  final List<dynamic> expectedInvites;
  final List<dynamic> historyRecords;
  final List<dynamic> checkedInVisitors;
  final Map<String, dynamic>? searchResult;
  final String? errorMessage;
  final String? successMessage;
  final bool isSubmitting;
  final String? submittingVisitorId;

  const GuardGateState({
    this.status = GuardGateStatus.initial,
    this.expectedInvites = const [],
    this.historyRecords = const [],
    this.checkedInVisitors = const [],
    this.searchResult,
    this.errorMessage,
    this.successMessage,
    this.isSubmitting = false,
    this.submittingVisitorId,
  });

  GuardGateState copyWith({
    GuardGateStatus? status,
    List<dynamic>? expectedInvites,
    List<dynamic>? historyRecords,
    List<dynamic>? checkedInVisitors,
    Map<String, dynamic>? searchResult,
    String? errorMessage,
    String? successMessage,
    bool? isSubmitting,
    String? submittingVisitorId,
    bool clearMessages = false,
  }) {
    return GuardGateState(
      status: status ?? this.status,
      expectedInvites: expectedInvites ?? this.expectedInvites,
      historyRecords: historyRecords ?? this.historyRecords,
      checkedInVisitors: checkedInVisitors ?? this.checkedInVisitors,
      searchResult: clearMessages && searchResult == null ? null : (searchResult ?? this.searchResult),
      errorMessage: clearMessages && errorMessage == null ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearMessages && successMessage == null ? null : (successMessage ?? this.successMessage),
      isSubmitting: isSubmitting ?? this.isSubmitting,
      submittingVisitorId: clearMessages && submittingVisitorId == null ? null : (submittingVisitorId ?? this.submittingVisitorId),
    );
  }

  @override
  List<Object?> get props => [
        status,
        expectedInvites,
        historyRecords,
        checkedInVisitors,
        searchResult,
        errorMessage,
        successMessage,
        isSubmitting,
        submittingVisitorId,
      ];
}
