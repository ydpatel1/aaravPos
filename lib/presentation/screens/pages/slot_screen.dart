import 'package:aaravpos/domain/model/slot_item.dart';
import 'package:aaravpos/presentation/bloc/session/session_bloc.dart';
import 'package:aaravpos/presentation/bloc/slot/slot_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/utils/extensions/context_extension.dart';
import '../../../../core/utils/extensions/space_extension.dart';
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

  /// Whether a slot's time is in the past compared to now (only relevant for today)
  bool _isPast(SlotItem slot, DateTime selectedDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selDay = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );
    if (selDay != today) return false; // future date — never past
    final dt = slot.toDateTime(selectedDate);
    if (dt == null) return false;
    return dt.isBefore(now);
  }

  /// Format "HH:mm" → "h:mm AM/PM"
  String _formatTime(String time) {
    final parts = time.split(':');
    if (parts.length < 2) return time;
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    final period = h < 12 ? 'AM' : 'PM';
    final hour = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$hour:${m.toString().padLeft(2, '0')} $period';
  }

  /// Build bottom bar subtitle: "11:00 AM – 1:15 PM • 2 Services"
  String _buildSubtitle(SessionState session) {
    final slot = session.selectedSlot;
    final services = session.selectedServices;
    if (slot == null) return '${services.length} Service Selected';

    final totalMin = services.fold<int>(0, (sum, s) => sum + s.durationMin);
    final parts = slot.startTime.split(':');
    if (parts.length < 2) {
      return '${services.length} Service Selected';
    }
    final startH = int.tryParse(parts[0]) ?? 0;
    final startM = int.tryParse(parts[1]) ?? 0;
    final endTotal = startH * 60 + startM + totalMin;
    final endH = endTotal ~/ 60;
    final endM = endTotal % 60;
    final endTime =
        '${endH > 12 ? endH - 12 : (endH == 0 ? 12 : endH)}:${endM.toString().padLeft(2, '0')} ${endH < 12 ? 'AM' : 'PM'}';

    return '${_formatTime(slot.startTime)} – $endTime • ${services.length} Services';
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionBloc>().state;
    final selectedDate = session.selectedDate ?? DateTime.now();
    final selectedSlot = session.selectedSlot;

    return Scaffold(
      appBar: CommonAppBar(
        title: 'Select Time Slot',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      bottomNavigationBar: KioskBottomBar(
        total: 'Total: ${session.formattedTotal}',
        subtitle: _buildSubtitle(session),
        primaryLabel: 'Continue',
        primaryEnabled: selectedSlot != null,
        onPrimary: () => context.push(AppRoutes.review),
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
                  final s = context.read<SessionBloc>().state;
                  if (s.selectedStaff?.id != null && s.selectedDate != null) {
                    context.read<SlotBloc>().fetchSlots(
                      s.selectedStaff!.id,
                      s.selectedDate!,
                    );
                  }
                },
              );
            }

            if (state.items.isEmpty) {
              return const Center(
                child: Text(
                  'No time slots available',
                  style: TextStyle(color: Color(0xFF737373), fontSize: 16),
                ),
              );
            }

            // Group ALL slots (including unavailable) into Morning/Afternoon/Evening
            final groups = <String, List<SlotItem>>{
              'Morning': [],
              'Afternoon': [],
              'Evening': [],
            };

            for (final slot in state.items) {
              final hour = int.tryParse(slot.startTime.split(':')[0]) ?? 0;
              if (hour >= 6 && hour < 12) {
                groups['Morning']!.add(slot);
              } else if (hour >= 12 && hour < 17) {
                groups['Afternoon']!.add(slot);
              } else {
                groups['Evening']!.add(slot);
              }
            }

            groups.removeWhere((_, v) => v.isEmpty);

            return ListView(
              children: groups.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section header
                      Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE12242),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        alignment: Alignment.centerLeft,
                        child: Text(
                          entry.key,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      12.vs,
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: entry.value.map<Widget>((slot) {
                          final isSelected = selectedSlot?.id == slot.id;
                          final isPast = _isPast(slot, selectedDate);
                          final isUnavailable = !slot.available;
                          final isDisabled = isUnavailable || isPast;

                          return _SlotPill(
                            slot: slot,
                            isSelected: isSelected,
                            isUnavailable: isUnavailable,
                            isPast: isPast,
                            isMobile: context.isMobile,
                            onTap: isDisabled
                                ? null
                                : () =>
                                      context.read<SessionBloc>().setSlot(slot),
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

class _SlotPill extends StatelessWidget {
  const _SlotPill({
    required this.slot,
    required this.isSelected,
    required this.isUnavailable,
    required this.isPast,
    required this.isMobile,
    required this.onTap,
  });

  final SlotItem slot;
  final bool isSelected;
  final bool isUnavailable;
  final bool isPast;
  final bool isMobile;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    // Style priority: selected > unavailable > past > normal
    Color bgColor;
    Color borderColor;
    Color textColor;

    if (isSelected) {
      bgColor = const Color(0xFFE12242);
      borderColor = const Color(0xFFE12242);
      textColor = Colors.white;
    } else if (isUnavailable) {
      bgColor = const Color(0xFFFFE4E8); // pink tint
      borderColor = const Color(0xFFFFB3BE);
      textColor = const Color(0xFFB0B0B0);
    } else if (isPast) {
      bgColor = const Color(0xFFF2F2F4);
      borderColor = const Color(0xFFD5D5D8);
      textColor = const Color(0xFFB0B0B0);
    } else {
      bgColor = const Color(0xFFF2F2F4);
      borderColor = const Color(0xFFD5D5D8);
      textColor = const Color(0xFF2B2B2B);
    }

    final needsStrikethrough = isUnavailable || isPast;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: isMobile ? 100 : 120,
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Text(
          slot.startTime,
          style: TextStyle(
            color: textColor,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            fontSize: isMobile ? 13 : 15,
            decoration: needsStrikethrough
                ? TextDecoration.lineThrough
                : TextDecoration.none,
            decorationColor: textColor,
          ),
        ),
      ),
    );
  }
}
