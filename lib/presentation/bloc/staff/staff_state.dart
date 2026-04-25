part of 'staff_bloc.dart';

class StaffState extends Equatable {
  const StaffState({
    this.isLoading = false,
    this.items = const <StaffMember>[],
    this.errorMessage,
  });

  final bool isLoading;
  final List<StaffMember> items;
  final String? errorMessage;

  StaffState copyWith({
    bool? isLoading,
    List<StaffMember>? items,
    String? errorMessage,
  }) {
    return StaffState(
      isLoading: isLoading ?? this.isLoading,
      items: items ?? this.items,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [isLoading, items, errorMessage];
}
