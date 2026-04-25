part of 'service_bloc.dart';

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
