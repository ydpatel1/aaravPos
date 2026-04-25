import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/utils/extensions/context_extension.dart';
import '../../../../shared/widgets/common_app_bar.dart';
import '../../../../shared/widgets/error_state_widget.dart';
import '../../../../shared/widgets/kiosk_bottom_bar.dart';
import '../../domain/slot_item.dart';
import '../blocs/slot_bloc.dart';
import '../cubit/session_cubit.dart';

class SlotScreen extends StatefulWidget {
  const SlotScreen({super.key});

  @override
  State<SlotScreen> createState() => _SlotScreenState();
}

class _SlotScreenState extends State<SlotScreen> {
  @override
  void initState() {
    super.initState();
    final date = context.read<SessionCubit>().state.selectedDate;
    context.read<SlotBloc>().fetchSlots(date);
  }

  @override
  Widget build(BuildContext context) {
    final selectedSlot = context.watch<SessionCubit>().state.selectedSlot;

    return Scaffold(
      appBar: const CommonAppBar(title: 'Select Time Slot'),
      bottomNavigationBar: KioskBottomBar(
        total: 'Total: \$215.00',
        subtitle: selectedSlot == null ? 'Select a time slot' : '${selectedSlot.time} - 1:15 PM • 2 Services',
        primaryLabel: 'Continue',
        primaryEnabled: selectedSlot != null,
        onPrimary: () => context.go(AppRoutes.review),
      ),
      body: Padding(
        padding: EdgeInsets.all(context.isMobile ? 16 : 20),
        child: BlocBuilder<SlotBloc, SlotState>(
          builder: (context, state) {
            if (state.isLoading) {
              return Shimmer.fromColors(
                baseColor: Colors.grey.shade300,
                highlightColor: Colors.grey.shade100,
                child: ListView(
                  children: List<Widget>.generate(
                    9,
                    (_) => Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      height: 54,
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              );
            }
            if (state.errorMessage != null) {
              return ErrorStateWidget(
                message: state.errorMessage!,
                onRetry: () => context.read<SlotBloc>().fetchSlots(context.read<SessionCubit>().state.selectedDate),
              );
            }

            final groups = <String, List<SlotItem>>{'Morning': [], 'Afternoon': [], 'Evening': []};
            for (final slot in state.items) {
              groups.putIfAbsent(slot.period, () => []).add(slot);
            }

            return ListView(
              children: groups.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    children: [
                      Container(
                        height: 56,
                        decoration: BoxDecoration(color: const Color(0xFFE12242), borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        alignment: Alignment.centerLeft,
                        child: Text(
                          entry.key,
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: entry.value.map<Widget>((slot) {
                          final selected = selectedSlot == slot;
                          return InkWell(
                            onTap: () => context.read<SessionCubit>().setSlot(slot),
                            child: Container(
                              width: context.isMobile ? 102 : 120,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: selected ? const Color(0x1FE12242) : const Color(0xFFF2F2F4),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: selected ? const Color(0xFFE12242) : const Color(0xFFD5D5D8)),
                              ),
                              child: Text(
                                slot.time,
                                style: TextStyle(
                                  color: selected ? const Color(0xFFE12242) : const Color(0xFF2B2B2B),
                                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                                  fontSize: context.isMobile ? 13 : 15,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
        ),
      ),
    );
  }
}
