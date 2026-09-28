import 'package:equatable/equatable.dart';

enum GuardGateStatus { initial, loading, loaded, success, error }

class GuardGateState extends Equatable {
  final GuardGateStatus status;
  final List<dynamic> expectedInvites;
<<<<<<< HEAD
  final Map<String, dynamic>? searchResult;
  final String? errorMessage;
  final bool isSubmitting;
=======
  final List<dynamic> historyRecords;
  final List<dynamic> checkedInVisitors;
  final Map<String, dynamic>? searchResult;
  final String? errorMessage;
  final String? successMessage;
  final bool isSubmitting;
  final String? submittingVisitorId;
  final bool isLoadingExpected;
>>>>>>> 8e14b7ab5ec9ba6ee223925910b776c044e433df

  const GuardGateState({
    this.status = GuardGateStatus.initial,
    this.expectedInvites = const [],
<<<<<<< HEAD
    this.searchResult,
    this.errorMessage,
    this.isSubmitting = false,
=======
    this.historyRecords = const [],
    this.checkedInVisitors = const [],
    this.searchResult,
    this.errorMessage,
    this.successMessage,
    this.isSubmitting = false,
    this.submittingVisitorId,
    this.isLoadingExpected = false,
>>>>>>> 8e14b7ab5ec9ba6ee223925910b776c044e433df
  });

  GuardGateState copyWith({
    GuardGateStatus? status,
    List<dynamic>? expectedInvites,
<<<<<<< HEAD
    Map<String, dynamic>? searchResult,
    String? errorMessage,
    bool? isSubmitting,
=======
    List<dynamic>? historyRecords,
    List<dynamic>? checkedInVisitors,
    Map<String, dynamic>? searchResult,
    String? errorMessage,
    String? successMessage,
    bool? isSubmitting,
    String? submittingVisitorId,
    bool? isLoadingExpected,
    bool clearMessages = false,
>>>>>>> 8e14b7ab5ec9ba6ee223925910b776c044e433df
  }) {
    return GuardGateState(
      status: status ?? this.status,
      expectedInvites: expectedInvites ?? this.expectedInvites,
<<<<<<< HEAD
      searchResult: searchResult ?? this.searchResult,
      errorMessage: errorMessage ?? this.errorMessage,
      isSubmitting: isSubmitting ?? this.isSubmitting,
=======
      historyRecords: historyRecords ?? this.historyRecords,
      checkedInVisitors: checkedInVisitors ?? this.checkedInVisitors,
      searchResult: clearMessages && searchResult == null ? null : (searchResult ?? this.searchResult),
      errorMessage: clearMessages && errorMessage == null ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearMessages && successMessage == null ? null : (successMessage ?? this.successMessage),
      isSubmitting: isSubmitting ?? this.isSubmitting,
      submittingVisitorId: clearMessages && submittingVisitorId == null ? null : (submittingVisitorId ?? this.submittingVisitorId),
      isLoadingExpected: isLoadingExpected ?? this.isLoadingExpected,
>>>>>>> 8e14b7ab5ec9ba6ee223925910b776c044e433df
    );
  }

  @override
  List<Object?> get props => [
        status,
        expectedInvites,
<<<<<<< HEAD
        searchResult,
        errorMessage,
        isSubmitting,
=======
        historyRecords,
        checkedInVisitors,
        searchResult,
        errorMessage,
        successMessage,
        isSubmitting,
        submittingVisitorId,
        isLoadingExpected,
>>>>>>> 8e14b7ab5ec9ba6ee223925910b776c044e433df
      ];
}
