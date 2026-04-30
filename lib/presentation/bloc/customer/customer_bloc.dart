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
    // Empty query — reset state, no API call
    if (event.query.isEmpty) {
      emit(const CustomerState());
      return;
    }
    emit(state.copyWith(isLoading: true, errorMessage: null, isCustomerNotFound: false));
    try {
      final results = await _repository.searchCustomers(event.query);
      if (results.isEmpty) {
        // API succeeded but no match → new customer path
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
      // Error → clear, isCustomerNotFound stays false
      emit(state.copyWith(
        isLoading: false,
        results: const [],
        isCustomerNotFound: false,
        errorMessage: 'Customer search failed',
      ));
    }
  }

  void search(String query) => add(CustomerSearchRequested(query));

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }
}
