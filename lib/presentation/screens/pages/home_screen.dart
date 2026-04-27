import 'package:aaravpos/presentation/bloc/auth/auth_bloc.dart';
import 'package:aaravpos/presentation/bloc/session/session_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/utils/extensions/context_extension.dart';
import '../../../../shared/widgets/aarav_pos_logo.dart';
import '../../../../shared/widgets/app_shimmer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // If outlet status not yet loaded (e.g. app restart with saved token),
    // fetch it now — shows shimmer while loading
    final authStatus = context.read<AuthBloc>().state.status;
    if (authStatus != AuthStatus.authenticated) {
      context.read<AuthBloc>().refreshOutletStatus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = context.isMobile;

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFF1F1F2),
        onPressed: () async {
          await context.read<AuthBloc>().logout();
          if (context.mounted) context.go(AppRoutes.login);
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
                child: BlocBuilder<AuthBloc, AuthState>(
                  buildWhen: (prev, curr) => prev.status != curr.status,
                  builder: (context, authState) {
                    final isLoading =
                        authState.status == AuthStatus.outletLoading ||
                        authState.status == AuthStatus.initial;

                    if (isLoading) {
                      return _buildShimmer(isMobile);
                    }

                    final isOutletOpen = context
                        .watch<SessionBloc>()
                        .state
                        .isOutletOpen;

                    return isMobile
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
                        : Container(
                            constraints: BoxConstraints(maxWidth: 750),
                            child: Row(
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
                          );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShimmer(bool isMobile) {
    return AppShimmer(
      child: isMobile
          ? Column(
              children: [
                ShimmerBox(height: 220, borderRadius: 24),
                const SizedBox(height: 16),
                ShimmerBox(height: 220, borderRadius: 24),
              ],
            )
          : Row(
              children: [
                Expanded(child: ShimmerBox(height: 370, borderRadius: 24)),
                const SizedBox(width: 22),
                Expanded(child: ShimmerBox(height: 370, borderRadius: 24)),
              ],
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
                context.push(AppRoutes.services);
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
