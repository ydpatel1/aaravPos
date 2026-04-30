part of 'customer_bloc.dart';

abstract class CustomerEvent extends Equatable {
  const CustomerEvent();

  @override
  List<Object?> get props => [];
}

class CustomerSearchRequested extends CustomerEvent {
  const CustomerSearchRequested(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}

class CustomerSearchDebounced extends CustomerEvent {
  const CustomerSearchDebounced(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}

/// Clears the customer search results and resets isCustomerNotFound.
class CustomerSearchCleared extends CustomerEvent {
  const CustomerSearchCleared();
}
