import 'package:aaravpos/domain/model/slot_item.dart';
import 'package:aaravpos/presentation/bloc/session/session_bloc.dart';
import 'package:aaravpos/presentation/bloc/slot/slot_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/utils/extensions/context_extension.dart';
import '../../../../shared/widgets/common_app_bar.dart';
import '../../../../shared/widgets/error_state_widget.dart';
import '../../../../shared/widgets/kiosk_bottom_bar.dart';

class SlotScreen extends StatefulWidget {
  const SlotScreen({super.key});

  @override
  State<SlotScreen> createState() => _SlotScreenState();
}

class _SlotScreenState extends State<SlotScreen> {
  @override
  void initState() {
    super.initState();
    final session = context.read<SessionBloc>().state;
    final staffId = session.selectedStaff?.id;
    final date = session.selectedDate;

    if (staffId != null && date != null) {
      context.read<SlotBloc>().fetchSlots(staffId, date);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedSlot = context.watch<SessionBloc>().state.selectedSlot;

    return Scaffold(
      appBar: CommonAppBar(
        title: 'Select Time Slot',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      bottomNavigationBar: KioskBottomBar(
        total: 'Total: \$215.00',
        subtitle: selectedSlot == null
            ? 'Select a time slot'
            : '${selectedSlot.startTime} selected',
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
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              );
            }
            if (state.errorMessage != null) {
              return ErrorStateWidget(
                message: state.errorMessage!,
                onRetry: () {
                  final session = context.read<SessionBloc>().state;
                  final staffId = session.selectedStaff?.id;
                  final date = session.selectedDate;
                  if (staffId != null && date != null) {
                    context.read<SlotBloc>().fetchSlots(staffId, date);
                  }
                },
              );
            }

            // Group slots by period (Morning, Afternoon, Evening)
            final groups = <String, List<SlotItem>>{
              'Morning': [],
              'Afternoon': [],
              'Evening': [],
            };

            for (final slot in state.items) {
              if (!slot.available) continue; // Skip unavailable slots

              final time = slot.startTime;
              final hour = int.tryParse(time.split(':')[0]) ?? 0;

              if (hour < 12) {
                groups['Morning']!.add(slot);
              } else if (hour < 17) {
                groups['Afternoon']!.add(slot);
              } else {
                groups['Evening']!.add(slot);
              }
            }

            // Remove empty periods
            groups.removeWhere((key, value) => value.isEmpty);

            return ListView(
              children: groups.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    children: [
                      Container(
                        height: 56,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE12242),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        alignment: Alignment.centerLeft,
                        child: Text(
                          entry.key,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: entry.value.map<Widget>((slot) {
                          final selected = selectedSlot?.id == slot.id;
                          return InkWell(
                            onTap: () =>
                                context.read<SessionBloc>().setSlot(slot),
                            child: Container(
                              width: context.isMobile ? 102 : 120,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: selected
                                    ? const Color(0x1FE12242)
                                    : const Color(0xFFF2F2F4),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: selected
                                      ? const Color(0xFFE12242)
                                      : const Color(0xFFD5D5D8),
                                ),
                              ),
                              child: Text(
                                slot.startTime,
                                style: TextStyle(
                                  color: selected
                                      ? const Color(0xFFE12242)
                                      : const Color(0xFF2B2B2B),
                                  fontWeight: selected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
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
