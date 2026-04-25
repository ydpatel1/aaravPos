import 'package:equatable/equatable.dart';

class StaffMember extends Equatable {
  const StaffMember({required this.id, required this.name});

  final String id;
  final String name;

  @override
  List<Object?> get props => [id, name];
}
