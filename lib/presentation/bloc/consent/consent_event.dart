part of 'consent_bloc.dart';

abstract class ConsentEvent extends Equatable {
  const ConsentEvent();

  @override
  List<Object?> get props => [];
}

/// Triggered from Review screen "Continue" — checks all consent-required services
class ConsentCheckRequested extends ConsentEvent {
  const ConsentCheckRequested({
    required this.customerId,
    required this.services,
  });

  final String customerId;
  final List<ServiceItem> services;

  @override
  List<Object?> get props => [customerId, services];
}

/// User submits signature / checkbox / typed name
class ConsentSignRequested extends ConsentEvent {
  const ConsentSignRequested({
    required this.signatureType,
    this.imageUrl,
    this.typedName,
  });

  final String signatureType;
  final String? imageUrl; // base64 data URI for SIGNATURE_IMAGE
  final String? typedName; // for TYPED_NAME

  @override
  List<Object?> get props => [signatureType, imageUrl, typedName];
}

class ConsentReset extends ConsentEvent {
  const ConsentReset();
}
