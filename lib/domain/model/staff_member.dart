import 'package:equatable/equatable.dart';

class StaffMember extends Equatable {
  const StaffMember({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.role,
    this.color,
    this.image,
  });

  final String id;
  final String firstName;
  final String lastName;
  final String role;
  final String? color; // HSL color from API, e.g., "hsl(353.41, 30%, 78.04%)"
  final String?
  image; // Image filename from API, e.g., "1771567512822-d654c42bacb6a411.webp"

  String get fullName => '$firstName $lastName';

  /// Get full image URL
  /// Base URL: https://prod.aaravpos.com/
  /// Image path: uploads/staff/{image}
  String? get imageUrl {
    if (image == null || image!.isEmpty) return null;
    return 'https://prod.aaravpos.com/uploads/staff/$image';
  }

  factory StaffMember.fromJson(Map<String, dynamic> json) {
    return StaffMember(
      id: json['id'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      role: json['role'] as String? ?? '',
      color: json['color'] as String?,
      image: json['image'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, firstName, lastName, role, color, image];
}
