import 'dart:async';

import 'package:aaravpos/domain/model/customer.dart';
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
    on<CustomerSearchCleared>(_onSearchCleared);
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
    emit(state.copyWith(isLoading: true, errorMessage: null, isCustomerNotFound: false));
    try {
      final results = await _repository.searchCustomers(event.query);
      if (results.isEmpty) {
        // API succeeded but no customers found → spec §4: isCustomerNotFound = true
        emit(state.copyWith(
          isLoading: false,
          results: const [],
          isCustomerNotFound: true,
        ));
      } else {
        emit(state.copyWith(
          isLoading: false,
          results: results,
          isCustomerNotFound: false,
        ));
      }
    } catch (_) {
      // Error / exception → spec §4: clear dropdown, isCustomerNotFound = false
      emit(state.copyWith(
        isLoading: false,
        results: const [],
        isCustomerNotFound: false,
        errorMessage: 'Customer search failed',
      ));
    }
  }

  void _onSearchCleared(
    CustomerSearchCleared event,
    Emitter<CustomerState> emit,
  ) {
    emit(const CustomerState());
  }

  void search(String query) => add(CustomerSearchRequested(query));
  void clear() => add(const CustomerSearchCleared());

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }
}
