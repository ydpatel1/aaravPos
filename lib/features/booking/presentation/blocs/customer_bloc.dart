import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_constants.dart';
import '../../domain/booking_repository.dart';

class CustomerState extends Equatable {
  const CustomerState({
    this.isLoading = false,
    this.results = const <String>[],
    this.errorMessage,
  });

  final bool isLoading;
  final List<String> results;
  final String? errorMessage;

  CustomerState copyWith({
    bool? isLoading,
    List<String>? results,
    String? errorMessage,
  }) {
    return CustomerState(
      isLoading: isLoading ?? this.isLoading,
      results: results ?? this.results,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [isLoading, results, errorMessage];
}

class CustomerBloc extends Cubit<CustomerState> {
  CustomerBloc(this._repository) : super(const CustomerState());

  final BookingRepository _repository;
  Timer? _debounce;

  void search(String query) {
    _debounce?.cancel();
    _debounce = Timer(AppConstants.searchDebounce, () async {
      emit(state.copyWith(isLoading: true, errorMessage: null));
      try {
        final results = await _repository.searchCustomers(query);
        emit(state.copyWith(isLoading: false, results: results));
      } catch (_) {
        emit(state.copyWith(isLoading: false, errorMessage: 'Customer not found'));
      }
    });
  }

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }
}
