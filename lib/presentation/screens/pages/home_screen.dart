import 'package:aaravpos/presentation/bloc/auth/auth_bloc.dart';
import 'package:aaravpos/presentation/bloc/session/session_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/utils/extensions/context_extension.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = context.isMobile;

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
              const Center(
                child: Text(
                  'AaravPOS',
                  style: TextStyle(color: Color(0xFFE12242), fontWeight: FontWeight.w800, fontSize: 28),
                ),
              ),
              SizedBox(height: isMobile ? 20 : 30),
              Expanded(
                child: isMobile
                    ? ListView(
                        children: const [
                          _ModeCard(title: 'Appointment', icon: Icons.calendar_month_outlined),
                          SizedBox(height: 16),
                          _ModeCard(title: 'Check-In', icon: Icons.place_outlined),
                        ],
                      )
                    : const Row(
                        children: [
                          Expanded(child: _ModeCard(title: 'Appointment', icon: Icons.calendar_month_outlined)),
                          SizedBox(width: 22),
                          Expanded(child: _ModeCard(title: 'Check-In', icon: Icons.place_outlined)),
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
  const _ModeCard({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final isMobile = context.isMobile;

    return InkWell(
      onTap: () {
        if (title == 'Appointment') {
          context.read<SessionBloc>().setMode(BookingMode.appointment);
        } else {
          context.read<SessionBloc>().setMode(BookingMode.checkIn);
        }
        context.go(AppRoutes.services);
      },
      borderRadius: BorderRadius.circular(24),
      child: Ink(
        height: isMobile ? 220 : 370,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            colors: [Color(0xFFEB5770), Color(0xFFE84B67)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: const [
            BoxShadow(color: Color(0x30E12242), blurRadius: 24, offset: Offset(0, 14)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: isMobile ? 28 : 38,
              backgroundColor: const Color(0x40FFFFFF),
              child: Icon(icon, size: isMobile ? 24 : 34, color: Colors.white),
            ),
            SizedBox(height: isMobile ? 12 : 26),
            Text(
              title,
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: isMobile ? 28 : 18),
            ),
          ],
        ),
      ),
    );
  }
}
