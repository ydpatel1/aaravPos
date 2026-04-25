import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/booking_repository.dart';
import '../../domain/service_item.dart';

part 'service_event.dart';
part 'service_state.dart';

class ServiceBloc extends Bloc<ServiceEvent, ServiceState> {
  ServiceBloc(this._repository) : super(const ServiceState()) {
    on<ServicesFetched>(_onServicesFetched);
  }

  final BookingRepository _repository;

  Future<void> _onServicesFetched(
    ServicesFetched event,
    Emitter<ServiceState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      final items = await _repository.fetchServices();
      emit(state.copyWith(isLoading: false, items: items));
    } catch (_) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: 'Failed to fetch services',
        ),
      );
    }
  }

  Future<void> fetchServices() async => add(const ServicesFetched());
}

