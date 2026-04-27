import 'package:aaravpos/presentation/bloc/session/session_bloc.dart';
import 'package:aaravpos/presentation/bloc/slot/slot_bloc.dart';
import 'package:aaravpos/presentation/bloc/staff/staff_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/router/app_routes.dart';
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
  @override
  void initState() {
    super.initState();
    context.read<StaffBloc>().fetchStaff();
  }

  void _handleContinue() async {
    final session = context.read<SessionBloc>().state;

    if (session.mode == BookingMode.checkIn) {
      // Check-In mode: Set today's date and auto-select nearest slot
      final now = DateTime.now();
      context.read<SessionBloc>().setDate(now);

      // Fetch slots for today
      final staffId = session.selectedStaff?.id;
      if (staffId == null) return;

      // Show loading dialog
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              const Center(child: CircularProgressIndicator()),
        );
      }

      // Fetch slots
      context.read<SlotBloc>().add(
        SlotsFetched(staffId: staffId, selectedDate: now),
      );

      // Wait for slots to load
      await Future.delayed(const Duration(milliseconds: 2000));

      if (mounted) {
        // Close loading dialog
        Navigator.of(context).pop();

        final slotState = context.read<SlotBloc>().state;

        debugPrint(
          '🔍 Check-In Mode: Slots loaded: ${slotState.items.length} total slots',
        );

        if (slotState.items.isNotEmpty) {
          // Find nearest available future slot
          final currentTime = DateTime.now();

          debugPrint(
            '🕐 Current time: ${currentTime.hour}:${currentTime.minute.toString().padLeft(2, '0')}',
          );

          // Filter available slots that are in the future
          final futureSlots = slotState.items.where((slot) {
            if (!slot.available) {
              debugPrint(
                '❌ Slot ${slot.startTime} not available (status: ${slot.available}, booked: ${slot.isBooked})',
              );
              return false;
            }

            final slotDateTime = slot.toDateTime(now);
            if (slotDateTime == null) {
              debugPrint('❌ Slot ${slot.startTime} - failed to parse time');
              return false;
            }

            final isFuture = slotDateTime.isAfter(currentTime);
            debugPrint(
              '${isFuture ? "✅" : "❌"} Slot ${slot.startTime} - ${isFuture ? "future" : "past"} (slot: ${slotDateTime.hour}:${slotDateTime.minute.toString().padLeft(2, '0')})',
            );

            return isFuture;
          }).toList();

          debugPrint('📋 Found ${futureSlots.length} future available slots');

          if (futureSlots.isNotEmpty) {
            // Sort by time to get the nearest one
            futureSlots.sort((a, b) {
              final aTime = a.toDateTime(now);
              final bTime = b.toDateTime(now);
              if (aTime == null || bTime == null) return 0;
              return aTime.compareTo(bTime);
            });

            // Auto-select the nearest future slot
            final selectedSlot = futureSlots.first;
            debugPrint(
              '✅ Auto-selected slot: ${selectedSlot.startTime} (ID: ${selectedSlot.id})',
            );

            // Set the slot in session
            context.read<SessionBloc>().setSlot(selectedSlot);

            // Wait a bit for state to update
            await Future.delayed(const Duration(milliseconds: 300));

            // Verify slot was set
            final updatedSession = context.read<SessionBloc>().state;
            debugPrint(
              '🔍 Slot in session after setting: ${updatedSession.selectedSlot?.startTime ?? "NULL"}',
            );
          } else {
            debugPrint('⚠️ No future slots available');
            // Show error message
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('No available time slots for today'),
                  backgroundColor: Color(0xFFE12242),
                ),
              );
              return;
            }
          }
        } else {
          debugPrint('⚠️ No slots returned from API');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No time slots available'),
                backgroundColor: Color(0xFFE12242),
              ),
            );
            return;
          }
        }

        // Navigate directly to review
        if (mounted) {
          context.push(AppRoutes.review);
        }
      }
    } else {
      // Appointment mode: Go to date selection
      context.push(AppRoutes.date);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionBloc>().state;

    return Scaffold(
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
        primaryLabel: 'Continue',
        primaryEnabled: session.selectedStaff != null,
        onPrimary: _handleContinue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: BlocBuilder<StaffBloc, StaffState>(
          builder: (context, state) {
            if (state.isLoading) {
              return const Center(child: CircularProgressIndicator());
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
                    ? 2 // Mobile: 2 items per row
                    : constraints.maxWidth < 900
                    ? 3 // Tablet: 3 items per row
                    : 4; // Desktop: 4 items per row

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
                      onTap: () => context.read<SessionBloc>().setStaff(staff),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
