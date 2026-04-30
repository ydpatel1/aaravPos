part of 'customer_bloc.dart';

class CustomerState extends Equatable {
  const CustomerState({
    this.isLoading = false,
    this.results = const <Customer>[],
    this.isCustomerNotFound = false,
    this.errorMessage,
  });

  final bool isLoading;
  final List<Customer> results;

  /// True when the search API returned success but zero results.
  /// Used to trigger the new-customer consent evaluation path.
  final bool isCustomerNotFound;

  final String? errorMessage;

  CustomerState copyWith({
    bool? isLoading,
    List<Customer>? results,
    bool? isCustomerNotFound,
    String? errorMessage,
  }) {
    return CustomerState(
      isLoading: isLoading ?? this.isLoading,
      results: results ?? this.results,
      isCustomerNotFound: isCustomerNotFound ?? this.isCustomerNotFound,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [isLoading, results, isCustomerNotFound, errorMessage];
}
