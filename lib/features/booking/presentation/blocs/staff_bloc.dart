import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/booking_repository.dart';
import '../../domain/staff_member.dart';

class StaffState extends Equatable {
  const StaffState({
    this.isLoading = false,
    this.items = const <StaffMember>[],
    this.errorMessage,
  });

  final bool isLoading;
  final List<StaffMember> items;
  final String? errorMessage;

  StaffState copyWith({
    bool? isLoading,
    List<StaffMember>? items,
    String? errorMessage,
  }) {
    return StaffState(
      isLoading: isLoading ?? this.isLoading,
      items: items ?? this.items,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [isLoading, items, errorMessage];
}

class StaffBloc extends Cubit<StaffState> {
  StaffBloc(this._repository) : super(const StaffState());

  final BookingRepository _repository;

  Future<void> fetchStaff() async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      final items = await _repository.fetchStaff();
      emit(state.copyWith(isLoading: false, items: items));
    } catch (_) {
      emit(state.copyWith(isLoading: false, errorMessage: 'Failed to fetch staff'));
    }
  }
}
