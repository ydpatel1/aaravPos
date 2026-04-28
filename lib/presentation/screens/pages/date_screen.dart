import 'package:aaravpos/presentation/bloc/session/session_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../shared/widgets/common_app_bar.dart';
import '../../../../shared/widgets/kiosk_bottom_bar.dart';

class DateScreen extends StatefulWidget {
  const DateScreen({super.key});

  @override
  State<DateScreen> createState() => _DateScreenState();
}

class _DateScreenState extends State<DateScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionBloc>().state;

    return Scaffold(
      appBar: CommonAppBar(
        title: 'Select Date',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      bottomNavigationBar: KioskBottomBar(
        total: 'Total: \$215.00',
        subtitle: '${session.selectedServices.length} Service Selected',
        primaryLabel: 'Continue',
        primaryEnabled: _selectedDay != null,
        onPrimary: () {
          if (_selectedDay != null) {
            context.read<SessionBloc>().setDate(_selectedDay!);
            context.push(AppRoutes.slots);
          }
        },
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(24),
            child: TableCalendar(
              firstDay: DateTime.now(),
              lastDay: DateTime.now().add(const Duration(days: 365)),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                if (selectedDay.isBefore(
                  DateTime.now().subtract(const Duration(days: 1)),
                )) {
                  return; // Don't allow past dates
                }
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
              },
              calendarFormat: CalendarFormat.month,
              availableCalendarFormats: const {CalendarFormat.month: 'Month'},
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFE12242),
                ),
                leftChevronIcon: const Icon(
                  Icons.chevron_left,
                  color: Color(0xFFE12242),
                ),
                rightChevronIcon: const Icon(
                  Icons.chevron_right,
                  color: Color(0xFFE12242),
                ),
              ),
              daysOfWeekStyle: const DaysOfWeekStyle(
                weekdayStyle: TextStyle(
                  color: Color(0xFF737373),
                  fontWeight: FontWeight.w600,
                ),
                weekendStyle: TextStyle(
                  color: Color(0xFF737373),
                  fontWeight: FontWeight.w600,
                ),
              ),
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: const Color(0xFFE12242).withValues(alpha: 0.2),
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.circular(12),
                ),
                todayTextStyle: const TextStyle(
                  color: Color(0xFFE12242),
                  fontWeight: FontWeight.w700,
                ),
                selectedDecoration: BoxDecoration(
                  color: const Color(0xFFE12242),
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.circular(12),
                ),
                selectedTextStyle: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
                defaultDecoration: BoxDecoration(
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.circular(12),
                ),
                weekendDecoration: BoxDecoration(
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.circular(12),
                ),
                disabledTextStyle: const TextStyle(color: Color(0xFFD4D4D6)),
                outsideTextStyle: const TextStyle(color: Color(0xFFD4D4D6)),
              ),
              enabledDayPredicate: (day) {
                // Disable past dates
                return day.isAfter(
                  DateTime.now().subtract(const Duration(days: 1)),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
