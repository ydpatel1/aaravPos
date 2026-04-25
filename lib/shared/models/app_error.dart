import 'package:equatable/equatable.dart';

class AppError extends Equatable {
  const AppError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
