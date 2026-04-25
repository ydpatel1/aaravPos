part of 'consent_bloc.dart';

abstract class ConsentEvent extends Equatable {
  const ConsentEvent();

  @override
  List<Object?> get props => [];
}

class ConsentCheckRequested extends ConsentEvent {
  const ConsentCheckRequested(this.customerName);

  final String customerName;

  @override
  List<Object?> get props => [customerName];
}
