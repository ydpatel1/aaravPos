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
    // Consent fields — only set when consent dialog was completed
    this.consentFormId,
    this.signatureType,
    this.imageUrl,
    this.typedName,
    this.isChecked = false,
  });

  final dynamic session; // SessionState
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String? consentFormId;
  final String? signatureType;
  final String? imageUrl;
  final String? typedName;
  final bool isChecked;

  @override
  List<Object?> get props => [
    firstName,
    lastName,
    email,
    phone,
    consentFormId,
    signatureType,
  ];
}
