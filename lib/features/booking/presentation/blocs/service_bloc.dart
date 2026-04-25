import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/booking_repository.dart';
import '../../domain/service_item.dart';

class ServiceState extends Equatable {
  const ServiceState({
    this.isLoading = false,
    this.items = const <ServiceItem>[],
    this.errorMessage,
  });

  final bool isLoading;
  final List<ServiceItem> items;
  final String? errorMessage;

  ServiceState copyWith({
    bool? isLoading,
    List<ServiceItem>? items,
    String? errorMessage,
  }) {
    return ServiceState(
      isLoading: isLoading ?? this.isLoading,
      items: items ?? this.items,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [isLoading, items, errorMessage];
}

class ServiceBloc extends Cubit<ServiceState> {
  ServiceBloc(this._repository) : super(const ServiceState());

  final BookingRepository _repository;

  Future<void> fetchServices() async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      final items = await _repository.fetchServices();
      emit(state.copyWith(isLoading: false, items: items));
    } catch (_) {
      emit(state.copyWith(isLoading: false, errorMessage: 'Failed to fetch services'));
    }
  }
}
