import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/utils/extensions/context_extension.dart';
import '../../../../shared/widgets/common_app_bar.dart';
import '../../../../shared/widgets/kiosk_bottom_bar.dart';
import '../../../../shared/widgets/platform_glass_card.dart';
import '../blocs/session_bloc.dart';

class DateScreen extends StatelessWidget {
  const DateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final selectedDate = context.watch<SessionBloc>().state.selectedDate;
    final isMobile = context.isMobile;

    return Scaffold(
      appBar: const CommonAppBar(title: 'Select Date'),
      bottomNavigationBar: KioskBottomBar(
        total: 'Total: \$215.00',
        subtitle: '2 Service Selected',
        primaryLabel: 'Continue',
        primaryEnabled: selectedDate != null,
        onPrimary: () => context.go(AppRoutes.slots),
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          child: PlatformGlassCard(
            radius: 30,
            padding: EdgeInsets.all(isMobile ? 10 : 22),
            child: SizedBox(
              width: isMobile ? double.infinity : 560,
              child: CalendarDatePicker(
                initialDate: selectedDate ?? DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 180)),
                onDateChanged: (date) => context.read<SessionBloc>().setDate(date),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
