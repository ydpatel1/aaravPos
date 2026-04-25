part of 'slot_bloc.dart';

class SlotState extends Equatable {
  const SlotState({
    this.isLoading = false,
    this.items = const <SlotItem>[],
    this.errorMessage,
  });

  final bool isLoading;
  final List<SlotItem> items;
  final String? errorMessage;

  SlotState copyWith({
    bool? isLoading,
    List<SlotItem>? items,
    String? errorMessage,
  }) {
    return SlotState(
      isLoading: isLoading ?? this.isLoading,
      items: items ?? this.items,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [isLoading, items, errorMessage];
}
