import 'package:aaravpos/presentation/bloc/session/session_bloc.dart';
import 'package:aaravpos/presentation/bloc/slot/slot_bloc.dart';
import 'package:aaravpos/presentation/bloc/staff/staff_bloc.dart';
import 'package:aaravpos/domain/model/slot_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../shared/widgets/app_shimmer.dart';
import '../../../../shared/widgets/common_app_bar.dart';
import '../../../../shared/widgets/error_state_widget.dart';
import '../../../../shared/widgets/kiosk_bottom_bar.dart';
import '../widgets/staff_card.dart';

class StaffScreen extends StatefulWidget {
  const StaffScreen({super.key});

  @override
  State<StaffScreen> createState() => _StaffScreenState();
}

class _StaffScreenState extends State<StaffScreen> {
  bool _waitingForSlots = false;

  @override
  void initState() {
    super.initState();
    context.read<StaffBloc>().fetchStaff();
  }

  void _handleContinue() {
    final session = context.read<SessionBloc>().state;

    if (session.isCheckIn) {
      // Check-In: fetch today's slots, auto-select nearest, skip date+slot screens
      final staffId = session.selectedStaff?.id;
      if (staffId == null) return;

      final today = DateTime.now();
      context.read<SessionBloc>().setDate(today);
      context.read<SlotBloc>().fetchSlots(staffId, today);
      setState(() => _waitingForSlots = true);
    } else {
      // Appointment: go to date picker
      context.push(AppRoutes.date);
    }
  }

  void _autoSelectAndNavigate(SlotState slotState) {
    if (!_waitingForSlots) return;
    setState(() => _waitingForSlots = false);

    if (slotState.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(slotState.errorMessage!),
          backgroundColor: const Color(0xFFE12242),
        ),
      );
      return;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Find first available slot that is in the future
    final nearest =
        slotState.items.where((slot) {
          if (!slot.available) return false;
          final dt = slot.toDateTime(today);
          return dt != null && dt.isAfter(now);
        }).toList()..sort((a, b) {
          final at = a.toDateTime(today)!;
          final bt = b.toDateTime(today)!;
          return at.compareTo(bt);
        });

    if (nearest.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No available time slots for today'),
          backgroundColor: Color(0xFFE12242),
        ),
      );
      return;
    }

    // Find consecutive slots needed for total service duration
    final session = context.read<SessionBloc>().state;
    final slotsNeeded = session.slotsNeeded;
    final allSlots = List<SlotItem>.from(slotState.items)
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    List<SlotItem>? selectedSlots;
    for (var i = 0; i < allSlots.length; i++) {
      final slot = allSlots[i];
      if (!slot.available || slot.isBooked) continue;
      final dt = slot.toDateTime(today);
      if (dt == null || !dt.isAfter(now)) continue;

      // Try to collect slotsNeeded consecutive slots from here
      final collected = <SlotItem>[];
      bool canBook = true;
      for (var j = 0; j < slotsNeeded; j++) {
        final pos = i + j;
        if (pos >= allSlots.length) { canBook = false; break; }
        final s = allSlots[pos];
        if (!s.available || s.isBooked) { canBook = false; break; }
        if (j > 0 && allSlots[pos - 1].endTime != s.startTime) {
          canBook = false; break;
        }
        collected.add(s);
      }
      if (canBook && collected.length == slotsNeeded) {
        selectedSlots = collected;
        break;
      }
    }

    if (selectedSlots == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No available time slots for today'),
          backgroundColor: Color(0xFFE12242),
        ),
      );
      return;
    }

    final startSlot = selectedSlots.first;
    final lastSlot = selectedSlots.last;
    final startParts = startSlot.startTime.split(':');
    final endParts = lastSlot.endTime.split(':');
    final startDt = DateTime(today.year, today.month, today.day,
        int.parse(startParts[0]), int.parse(startParts[1]));
    final endDt = DateTime(today.year, today.month, today.day,
        int.parse(endParts[0]), int.parse(endParts[1]));

    context.read<SessionBloc>().setSlotSelection(
      startSlot: startSlot,
      slotIds: selectedSlots.map((s) => s.id).toList(),
      startTime: startDt.toIso8601String(),
      endTime: endDt.toIso8601String(),
    );
    context.push(AppRoutes.review);
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionBloc>().state;

    return BlocListener<SlotBloc, SlotState>(
      listener: (context, slotState) {
        if (!slotState.isLoading) {
          _autoSelectAndNavigate(slotState);
        }
      },
      child: Scaffold(
        appBar: CommonAppBar(
          title: 'Select your service provider',
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        bottomNavigationBar: KioskBottomBar(
          total: 'Total: ${session.formattedTotal}',
          subtitle: '${session.selectedServices.length} Service Selected',
          primaryLabel: _waitingForSlots ? 'Finding slot...' : 'Continue',
          primaryEnabled: session.selectedStaff != null && !_waitingForSlots,
          onPrimary: _handleContinue,
        ),
        body: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: BlocBuilder<StaffBloc, StaffState>(
            builder: (context, state) {
              if (state.isLoading) {
                return LayoutBuilder(
                  builder: (context, constraints) {
                    final cols = constraints.maxWidth < 550
                        ? 2
                        : constraints.maxWidth < 900
                        ? 3
                        : 4;
                    return _StaffShimmer(cols: cols);
                  },
                );
              }
              if (state.errorMessage != null) {
                return ErrorStateWidget(
                  message: state.errorMessage!,
                  onRetry: () => context.read<StaffBloc>().fetchStaff(),
                );
              }

              return LayoutBuilder(
                builder: (context, constraints) {
                  final cols = constraints.maxWidth < 550
                      ? 2
                      : constraints.maxWidth < 900
                      ? 3
                      : 4;

                  return AlignedGridView.count(
                    crossAxisCount: cols,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    itemCount: state.items.length,
                    itemBuilder: (_, index) {
                      final staff = state.items[index];
                      return StaffCard(
                        name: staff.fullName,
                        role: staff.role,
                        index: index,
                        color: staff.color,
                        imageUrl: staff.imageUrl,
                        isSelected: staff == session.selectedStaff,
                        onTap: () =>
                            context.read<SessionBloc>().setStaff(staff),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Shimmer skeleton that matches the StaffCard layout exactly:
/// colored card → avatar circle → name line → role line
class _StaffShimmer extends StatelessWidget {
  const _StaffShimmer({required this.cols});

  final int cols;

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: SingleChildScrollView(
        child: AlignedGridView.count(
          crossAxisCount: cols,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 6,
        itemBuilder: (_, __) => Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Avatar circle with border ring — matches _buildAvatar()
              Container(
                width: 82, // 76 image + 3*2 border
                height: 82,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFD4D4D6),
                  border: Border.all(color: Colors.white, width: 3),
                ),
              ),
              const SizedBox(height: 16),
              // Name line — full width, bold
              ShimmerBox(height: 14, borderRadius: 6),
              const SizedBox(height: 8),
              // Role line — shorter, centered
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ShimmerBox(height: 11, borderRadius: 5),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}
