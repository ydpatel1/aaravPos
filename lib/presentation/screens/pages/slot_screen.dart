import 'package:aaravpos/domain/model/slot_item.dart';
import 'package:aaravpos/presentation/bloc/session/session_bloc.dart';
import 'package:aaravpos/presentation/bloc/slot/slot_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/utils/extensions/context_extension.dart';
import '../../../../core/utils/extensions/space_extension.dart';
import '../../../../shared/widgets/app_shimmer.dart';
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

  // ── Helpers ─────────────────────────────────────────────────────────────────

  bool _isPast(SlotItem slot, DateTime selectedDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selDay = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    if (selDay != today) return false;
    final dt = slot.toDateTime(selectedDate);
    if (dt == null) return false;
    return dt.isBefore(now);
  }

  String _formatTime(String time) {
    final parts = time.split(':');
    if (parts.length < 2) return time;
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    final period = h < 12 ? 'AM' : 'PM';
    final hour = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$hour:${m.toString().padLeft(2, '0')} $period';
  }

  String _buildSubtitle(SessionState session) {
    final slot = session.selectedSlot;
    final services = session.selectedServices;
    if (slot == null) return '${services.length} Service Selected';

    final startFmt = _formatTime(slot.startTime);

    // Compute end time from total duration
    final totalMin = session.totalDuration;
    final parts = slot.startTime.split(':');
    if (parts.length < 2) return '${services.length} Service Selected';
    final startH = int.tryParse(parts[0]) ?? 0;
    final startM = int.tryParse(parts[1]) ?? 0;
    final endTotal = startH * 60 + startM + totalMin;
    final endH = endTotal ~/ 60 % 24;
    final endM = endTotal % 60;
    final endFmt =
        '${endH > 12 ? endH - 12 : (endH == 0 ? 12 : endH)}:${endM.toString().padLeft(2, '0')} ${endH < 12 ? 'AM' : 'PM'}';

    return '$startFmt – $endFmt • ${services.length} Services';
  }

  // ── Multi-slot selection ─────────────────────────────────────────────────────

  /// Handles tapping a slot chip.
  /// Tries to collect slotsNeeded consecutive available slots starting from tapped.
  void _handleSlotTap(
    BuildContext ctx,
    SlotItem tapped,
    List<SlotItem> allSlots,
    DateTime selectedDate,
  ) {
    final session = ctx.read<SessionBloc>().state;
    final slotsNeeded = session.slotsNeeded;

    final idx = allSlots.indexWhere((s) => s.id == tapped.id);
    if (idx == -1) return;

    // Validate and collect consecutive slots
    final collected = <SlotItem>[];
    bool canSelect = true;

    for (var i = 0; i < slotsNeeded; i++) {
      final pos = idx + i;
      if (pos >= allSlots.length) {
        canSelect = false;
        break;
      }
      final slot = allSlots[pos];

      if (slot.isBooked || !slot.available) {
        canSelect = false;
        break;
      }
      if (_isPast(slot, selectedDate)) {
        canSelect = false;
        break;
      }
      // Check continuity: previous slot's endTime must equal this slot's startTime
      if (i > 0) {
        final prev = allSlots[pos - 1];
        if (prev.endTime != slot.startTime) {
          canSelect = false;
          break;
        }
      }
      collected.add(slot);
    }

    if (!canSelect || collected.isEmpty) {
      final totalMin = session.totalDuration;
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          content: Text(
            'Not enough consecutive available slots for $totalMin minutes',
          ),
          backgroundColor: const Color(0xFFE12242),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    // Build ISO8601 start and end times
    final date = selectedDate;
    final startSlot = collected.first;
    final lastSlot = collected.last;

    final startParts = startSlot.startTime.split(':');
    final endParts = lastSlot.endTime.split(':');

    final startDt = DateTime(
      date.year, date.month, date.day,
      int.parse(startParts[0]), int.parse(startParts[1]),
    );
    final endDt = DateTime(
      date.year, date.month, date.day,
      int.parse(endParts[0]), int.parse(endParts[1]),
    );

    ctx.read<SessionBloc>().setSlotSelection(
      startSlot: startSlot,
      slotIds: collected.map((s) => s.id).toList(),
      startTime: startDt.toIso8601String(),
      endTime: endDt.toIso8601String(),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionBloc>().state;
    final selectedDate = session.selectedDate ?? DateTime.now();
    final selectedSlot = session.selectedSlot;
    final selectedSlotIds = session.selectedSlotIds;

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
        primaryEnabled: selectedSlot != null && selectedSlotIds.isNotEmpty,
        onPrimary: () => context.push(AppRoutes.review),
      ),
      body: Padding(
        padding: EdgeInsets.all(context.isMobile ? 16 : 20),
        child: BlocBuilder<SlotBloc, SlotState>(
          builder: (context, state) {
            if (state.isLoading) {
              return _SlotShimmer(isMobile: context.isMobile);
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

            // Flatten all slots into one ordered list for consecutive checking
            final allSlots = List<SlotItem>.from(state.items)
              ..sort((a, b) => a.startTime.compareTo(b.startTime));

            // Check if all available slots are in the past
            final hasAvailable = allSlots.any(
              (s) => s.available && !_isPast(s, selectedDate),
            );

            if (!hasAvailable && allSlots.isNotEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.schedule, size: 48, color: Color(0xFFB0B0B0)),
                    const SizedBox(height: 12),
                    const Text(
                      'No available slots for today',
                      style: TextStyle(color: Color(0xFF737373), fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => context.pop(),
                      child: const Text('Select a different date'),
                    ),
                  ],
                ),
              );
            }

            if (allSlots.isEmpty) {
              return const Center(
                child: Text(
                  'No time slots available',
                  style: TextStyle(color: Color(0xFF737373), fontSize: 16),
                ),
              );
            }

            // Group into Morning / Afternoon / Evening
            final groups = <String, List<SlotItem>>{
              'Morning': [],
              'Afternoon': [],
              'Evening': [],
            };
            for (final slot in allSlots) {
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
                          final isStart = selectedSlot?.id == slot.id;
                          final isContinuation = !isStart &&
                              selectedSlotIds.contains(slot.id);
                          final isPast = _isPast(slot, selectedDate);
                          final isUnavailable = !slot.available;
                          final isDisabled = isUnavailable || isPast;

                          return _SlotPill(
                            slot: slot,
                            isStart: isStart,
                            isContinuation: isContinuation,
                            isUnavailable: isUnavailable,
                            isPast: isPast,
                            isMobile: context.isMobile,
                            onTap: isDisabled
                                ? null
                                : () => _handleSlotTap(
                                      context,
                                      slot,
                                      allSlots,
                                      selectedDate,
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

// ── Slot pill widget ──────────────────────────────────────────────────────────

class _SlotPill extends StatelessWidget {
  const _SlotPill({
    required this.slot,
    required this.isStart,
    required this.isContinuation,
    required this.isUnavailable,
    required this.isPast,
    required this.isMobile,
    required this.onTap,
  });

  final SlotItem slot;
  final bool isStart;        // tapped start slot — bold, full border
  final bool isContinuation; // auto-selected continuation — lighter border
  final bool isUnavailable;
  final bool isPast;
  final bool isMobile;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color borderColor;
    Color textColor;
    double borderWidth;
    FontWeight fontWeight;

    if (isStart) {
      // Start slot: full red, bold, thick border
      bgColor = const Color(0xFFE12242);
      borderColor = const Color(0xFFE12242);
      textColor = Colors.white;
      borderWidth = 2;
      fontWeight = FontWeight.w700;
    } else if (isContinuation) {
      // Continuation slots: same tint, lighter border
      bgColor = const Color(0xFFFFE4E8);
      borderColor = const Color(0xFFE12242).withValues(alpha: 0.5);
      textColor = const Color(0xFFE12242);
      borderWidth = 1;
      fontWeight = FontWeight.w500;
    } else if (isUnavailable) {
      bgColor = const Color(0xFFFFE4E8);
      borderColor = const Color(0xFFFFB3BE);
      textColor = const Color(0xFFB0B0B0);
      borderWidth = 1;
      fontWeight = FontWeight.w400;
    } else if (isPast) {
      bgColor = const Color(0xFFF2F2F4);
      borderColor = const Color(0xFFD5D5D8);
      textColor = const Color(0xFFB0B0B0);
      borderWidth = 1;
      fontWeight = FontWeight.w400;
    } else {
      bgColor = const Color(0xFFF2F2F4);
      borderColor = const Color(0xFFD5D5D8);
      textColor = const Color(0xFF2B2B2B);
      borderWidth = 1;
      fontWeight = FontWeight.w500;
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
          border: Border.all(color: borderColor, width: borderWidth),
        ),
        child: Text(
          slot.startTime,
          style: TextStyle(
            color: textColor,
            fontWeight: fontWeight,
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

// ── Shimmer ───────────────────────────────────────────────────────────────────

class _SlotShimmer extends StatelessWidget {
  const _SlotShimmer({required this.isMobile});

  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    final chipWidth = isMobile ? 100.0 : 120.0;

    return AppShimmer(
      child: ListView(
        children: [
          for (int section = 0; section < 3; section++) ...[
            ShimmerBox(height: 48, borderRadius: 12),
            const SizedBox(height: 12),
            for (int row = 0; row < 2; row++) ...[
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: List.generate(
                  isMobile ? 3 : 4,
                  (_) => ShimmerBox(height: 44, width: chipWidth, borderRadius: 12),
                ),
              ),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 20),
          ],
        ],
      ),
    );
  }
}
