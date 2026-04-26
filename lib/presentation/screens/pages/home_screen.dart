import 'package:aaravpos/presentation/bloc/auth/auth_bloc.dart';
import 'package:aaravpos/presentation/bloc/session/session_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../shared/widgets/aarav_pos_logo.dart';
import '../../../../core/utils/extensions/context_extension.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = context.isMobile;
    final isOutletOpen = context.watch<SessionBloc>().state.isOutletOpen;
    print("check this isOutletOpen ${isOutletOpen}");
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFF1F1F2),
        onPressed: () async {
          await context.read<AuthBloc>().logout();
          if (context.mounted) {
            context.go(AppRoutes.login);
          }
        },
        child: const Icon(Icons.logout, color: Color(0xFFE12242)),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 16 : 28),
          child: Column(
            children: [
              const SizedBox(height: 12),
              const Center(child: AaravPosLogo()),
              SizedBox(height: isMobile ? 20 : 30),
              Expanded(
                child: isMobile
                    ? ListView(
                        children: [
                          _ModeCard(
                            title: 'Appointment',
                            icon: Icons.calendar_month_outlined,
                            enabled: !isOutletOpen,
                          ),
                          const SizedBox(height: 16),
                          _ModeCard(
                            title: 'Check-In',
                            icon: Icons.place_outlined,
                            enabled: isOutletOpen,
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: _ModeCard(
                              title: 'Appointment',
                              icon: Icons.calendar_month_outlined,
                              enabled: !isOutletOpen,
                            ),
                          ),
                          const SizedBox(width: 22),
                          Expanded(
                            child: _ModeCard(
                              title: 'Check-In',
                              icon: Icons.place_outlined,
                              enabled: isOutletOpen,
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.title,
    required this.icon,
    required this.enabled,
  });

  final String title;
  final IconData icon;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final isMobile = context.isMobile;

    return Opacity(
      opacity: enabled ? 1.0 : 0.45,
      child: InkWell(
        onTap: enabled
            ? () {
                if (title == 'Appointment') {
                  context.read<SessionBloc>().setMode(BookingMode.appointment);
                } else {
                  context.read<SessionBloc>().setMode(BookingMode.checkIn);
                }
                context.go(AppRoutes.services);
              }
            : null,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          height: isMobile ? 220 : 370,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              colors: enabled
                  ? const [Color(0xFFEB5770), Color(0xFFE84B67)]
                  : const [Color(0xFFBDBDBD), Color(0xFFBDBDBD)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: enabled
                    ? const Color(0x30E12242)
                    : const Color(0x20000000),
                blurRadius: 24,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: isMobile ? 28 : 38,
                backgroundColor: const Color(0x40FFFFFF),
                child: Icon(
                  icon,
                  size: isMobile ? 24 : 34,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: isMobile ? 12 : 26),
              Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: isMobile ? 28 : 18,
                ),
              ),
              if (!enabled) ...[
                const SizedBox(height: 8),
                const Text(
                  'Outlet is closed',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
