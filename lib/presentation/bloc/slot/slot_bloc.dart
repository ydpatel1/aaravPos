import 'package:aaravpos/domain/repo/booking_repository.dart';
import 'package:aaravpos/domain/model/slot_item.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';



part 'slot_event.dart';
part 'slot_state.dart';

class SlotBloc extends Bloc<SlotEvent, SlotState> {
  SlotBloc(this._repository) : super(const SlotState()) {
    on<SlotsFetched>(_onSlotsFetched);
  }

  final BookingRepository _repository;

  Future<void> _onSlotsFetched(
    SlotsFetched event,
    Emitter<SlotState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      final items = await _repository.fetchSlots(event.selectedDate);
      emit(state.copyWith(isLoading: false, items: items));
    } catch (_) {
      emit(state.copyWith(isLoading: false, errorMessage: 'No slots available'));
    }
  }

  Future<void> fetchSlots(DateTime? selectedDate) async =>
      add(SlotsFetched(selectedDate));
}
