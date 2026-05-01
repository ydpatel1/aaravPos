part of 'booking_bloc.dart';

abstract class BookingEvent extends Equatable {
  const BookingEvent();

  @override
  List<Object?> get props => [];
}

class BookingSubmitted extends BookingEvent {
  const BookingSubmitted({
    required this.session,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    this.signedConsents = const {},
  });

  final dynamic session; // SessionState
  final String firstName;
  final String lastName;
  final String email;
  final String phone;

  /// Per-service signed data — key = serviceId.
  /// Each entry triggers one POST concent/customer-sign after appointment is created.
  final Map<String, SignedConsentData> signedConsents;

  @override
  List<Object?> get props => [firstName, lastName, email, phone, signedConsents];
}
