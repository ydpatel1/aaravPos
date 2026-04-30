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
    this.signedConsents = const [],
  });

  final dynamic session; // SessionState
  final String firstName;
  final String lastName;
  final String email;
  final String phone;

  /// All consents signed in this session — submitted after appointment is created.
  final List<SignedConsentData> signedConsents;

  @override
  List<Object?> get props => [firstName, lastName, email, phone, signedConsents];
}
