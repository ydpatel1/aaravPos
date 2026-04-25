import 'dart:async';

import 'package:aaravpos/domain/repo/booking_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_constants.dart';

part 'customer_event.dart';
part 'customer_state.dart';

class CustomerBloc extends Bloc<CustomerEvent, CustomerState> {
  CustomerBloc(this._repository) : super(const CustomerState()) {
    on<CustomerSearchRequested>(_onSearchRequested);
    on<CustomerSearchDebounced>(_onSearchDebounced);
  }

  final BookingRepository _repository;
  Timer? _debounce;

  void _onSearchRequested(
    CustomerSearchRequested event,
    Emitter<CustomerState> emit,
  ) {
    _debounce?.cancel();
    _debounce = Timer(AppConstants.searchDebounce, () {
      add(CustomerSearchDebounced(event.query));
    });
  }

  Future<void> _onSearchDebounced(
    CustomerSearchDebounced event,
    Emitter<CustomerState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      final results = await _repository.searchCustomers(event.query);
      emit(state.copyWith(isLoading: false, results: results));
    } catch (_) {
      emit(
        state.copyWith(isLoading: false, errorMessage: 'Customer not found'),
      );
    }
  }

  void search(String query) => add(CustomerSearchRequested(query));

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }
}

