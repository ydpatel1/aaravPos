import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../shared/widgets/common_app_bar.dart';
import '../../../../shared/widgets/error_state_widget.dart';
import '../../../../shared/widgets/kiosk_bottom_bar.dart';
import '../blocs/staff_bloc.dart';
import '../blocs/session_bloc.dart';
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

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionBloc>().state;

    return Scaffold(
      appBar: const CommonAppBar(title: 'Select your service provider'),
      bottomNavigationBar: KioskBottomBar(
        total: 'Total: \$215.00',
        subtitle: '${session.selectedServices.length} Service Selected',
        primaryLabel: 'Continue',
        primaryEnabled: session.selectedStaff != null,
        onPrimary: () {
          if (session.mode == BookingMode.checkIn) {
            context.go(AppRoutes.review);
          } else {
            context.go(AppRoutes.date);
          }
        },
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
                final crossAxisCount = constraints.maxWidth < 700 ? 2 : 4;
                return GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    childAspectRatio: constraints.maxWidth < 700 ? 0.86 : 0.82,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: state.items.length,
                  itemBuilder: (_, index) {
                    final staff = state.items[index];
                    return StaffCard(
                      name: staff.name,
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
