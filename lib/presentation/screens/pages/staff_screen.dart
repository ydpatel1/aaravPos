import 'package:aaravpos/presentation/bloc/session/session_bloc.dart';
import 'package:aaravpos/presentation/bloc/slot/slot_bloc.dart';
import 'package:aaravpos/presentation/bloc/staff/staff_bloc.dart';
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

    context.read<SessionBloc>().setSlot(nearest.first);
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

/// Shimmer skeleton that matches the staff grid layout
class _StaffShimmer extends StatelessWidget {
  const _StaffShimmer({required this.cols});

  final int cols;

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: Column(
        children: [
          Expanded(
            child: GridView.builder(
              padding: EdgeInsets.zero,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: cols,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.75,
              ),
              itemCount: cols * 2,
              itemBuilder: (_, __) => Column(
                children: [
                  // Avatar circle
                  ShimmerBox(height: 84, width: 84, borderRadius: 42),
                  const SizedBox(height: 12),
                  // Name line
                  ShimmerBox(height: 16, borderRadius: 8),
                  const SizedBox(height: 6),
                  // Role line (shorter)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: ShimmerBox(height: 12, borderRadius: 6),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
