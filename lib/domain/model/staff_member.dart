import 'package:equatable/equatable.dart';

class StaffMember extends Equatable {
  const StaffMember({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.role,
  });

  final String id;
  final String firstName;
  final String lastName;
  final String role;

  String get fullName => '$firstName $lastName';

  factory StaffMember.fromJson(Map<String, dynamic> json) {
    return StaffMember(
      id: json['id'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      role: json['role'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [id, firstName, lastName, role];
}
