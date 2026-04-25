import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/booking_repository.dart';
import '../../domain/slot_item.dart';

class SlotState extends Equatable {
  const SlotState({
    this.isLoading = false,
    this.items = const <SlotItem>[],
    this.errorMessage,
  });

  final bool isLoading;
  final List<SlotItem> items;
  final String? errorMessage;

  SlotState copyWith({
    bool? isLoading,
    List<SlotItem>? items,
    String? errorMessage,
  }) {
    return SlotState(
      isLoading: isLoading ?? this.isLoading,
      items: items ?? this.items,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [isLoading, items, errorMessage];
}

class SlotBloc extends Cubit<SlotState> {
  SlotBloc(this._repository) : super(const SlotState());

  final BookingRepository _repository;

  Future<void> fetchSlots(DateTime? selectedDate) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      final items = await _repository.fetchSlots(selectedDate);
      emit(state.copyWith(isLoading: false, items: items));
    } catch (_) {
      emit(state.copyWith(isLoading: false, errorMessage: 'No slots available'));
    }
  }
}
