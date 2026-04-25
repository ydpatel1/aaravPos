import 'package:aaravpos/domain/repo/booking_repository.dart';
import 'package:aaravpos/domain/model/staff_member.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';



part 'staff_event.dart';
part 'staff_state.dart';

class StaffBloc extends Bloc<StaffEvent, StaffState> {
  StaffBloc(this._repository) : super(const StaffState()) {
    on<StaffFetched>(_onStaffFetched);
  }

  final BookingRepository _repository;

  Future<void> _onStaffFetched(
    StaffFetched event,
    Emitter<StaffState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      final items = await _repository.fetchStaff();
      emit(state.copyWith(isLoading: false, items: items));
    } catch (_) {
      emit(
        state.copyWith(isLoading: false, errorMessage: 'Failed to fetch staff'),
      );
    }
  }

  Future<void> fetchStaff() async => add(const StaffFetched());
}