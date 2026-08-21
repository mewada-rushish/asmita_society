import 'package:equatable/equatable.dart';
import '../data/models/daily_help_model.dart';

enum DailyHelpStatus { initial, loading, loaded, error }

class DailyHelpState extends Equatable {
  final DailyHelpStatus status;
  final List<DailyHelpModel> dailyHelpList;
  final String? errorMessage;

  const DailyHelpState({
    this.status = DailyHelpStatus.initial,
    this.dailyHelpList = const [],
    this.errorMessage,
  });

  DailyHelpState copyWith({
    DailyHelpStatus? status,
    List<DailyHelpModel>? dailyHelpList,
    String? errorMessage,
  }) {
    return DailyHelpState(
      status: status ?? this.status,
      dailyHelpList: dailyHelpList ?? this.dailyHelpList,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, dailyHelpList, errorMessage];
}
