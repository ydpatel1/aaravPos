part of 'consent_bloc.dart';

abstract class ConsentEvent extends Equatable {
  const ConsentEvent();

  @override
  List<Object?> get props => [];
}

/// Triggered from Review screen "Continue" button.
/// Runs the full decision tree for all consent-required services.
class ConsentCheckRequested extends ConsentEvent {
  const ConsentCheckRequested({
    required this.customerId,
    required this.services,
    this.isNewCustomer = false,
  });

  /// Empty string when no customer is selected / customer not found.
  final String customerId;

  final List<ServiceItem> services;

  /// True when phone was typed but no matching customer was found in the API.
  /// Skips the concent/check API call — treats all ONCE_PER_CUSTOMER as mandatory.
  final bool isNewCustomer;

  @override
  List<Object?> get props => [customerId, services, isNewCustomer];
}

/// User submits signature / checkbox / typed name in the consent dialog.
class ConsentSignRequested extends ConsentEvent {
  const ConsentSignRequested({
    required this.signatureType,
    this.imageUrl,
    this.typedName,
    this.isChecked = false,
  });

  final String signatureType;
  final String? imageUrl;
  final String? typedName;
  final bool isChecked;

  @override
  List<Object?> get props => [signatureType, imageUrl, typedName, isChecked];
}

class ConsentReset extends ConsentEvent {
  const ConsentReset();
}
