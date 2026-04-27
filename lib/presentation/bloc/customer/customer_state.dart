part of 'customer_bloc.dart';

class CustomerState extends Equatable {
  const CustomerState({
    this.isLoading = false,
    this.results = const <Customer>[],
    this.errorMessage,
  });

  final bool isLoading;
  final List<Customer> results;
  final String? errorMessage;

  CustomerState copyWith({
    bool? isLoading,
    List<Customer>? results,
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
