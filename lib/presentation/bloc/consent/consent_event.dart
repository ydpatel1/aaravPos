part of 'consent_bloc.dart';

abstract class ConsentEvent extends Equatable {
  const ConsentEvent();

  @override
  List<Object?> get props => [];
}

/// Triggered when a customer is selected — checks ONCE_PER_CUSTOMER services via API.
/// Also handles EVERY_VISIT services locally (no API call needed).
class ConsentCheckRequested extends ConsentEvent {
  const ConsentCheckRequested({
    required this.customerId,
    required this.services,
    this.isNewCustomer = false,
  });

  final String customerId;
  final List<ServiceItem> services;

  /// True when no customer was found (isCustomerNotFound == true).
  /// Triggers local evaluation instead of API calls.
  final bool isNewCustomer;

  @override
  List<Object?> get props => [customerId, services, isNewCustomer];
}

/// User confirmed the consent dialog for a specific service.
class ConsentSigned extends ConsentEvent {
  const ConsentSigned({required this.data});

  final SignedConsentData data;

  @override
  List<Object?> get props => [data];
}

/// Resets all consent state (called after successful booking or on cancel).
class ConsentReset extends ConsentEvent {
  const ConsentReset();
}
