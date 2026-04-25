import 'package:aaravpos/domain/model/service_item.dart';
import 'package:aaravpos/presentation/bloc/service/service_bloc.dart';
import 'package:aaravpos/presentation/bloc/session/session_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/utils/extensions/context_extension.dart';
import '../../../../shared/widgets/common_app_bar.dart';
import '../../../../shared/widgets/error_state_widget.dart';
import '../../../../shared/widgets/kiosk_bottom_bar.dart';
import '../widgets/service_card.dart';

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ServiceBloc>().fetchServices();
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionBloc>().state;

    return Scaffold(
      appBar: const CommonAppBar(title: 'Select Services'),
      bottomNavigationBar: KioskBottomBar(
        total: 'Total: \$215.00',
        subtitle: '${session.selectedServices.length} Services Selected',
        primaryLabel: 'Continue',
        primaryEnabled: session.selectedServices.isNotEmpty,
        onPrimary: () => context.go(AppRoutes.staff),
      ),
      body: BlocBuilder<ServiceBloc, ServiceState>(
        builder: (context, state) {
          if (state.isLoading) {
            return _buildShimmer();
          }
          if (state.errorMessage != null) {
            return ErrorStateWidget(
              message: state.errorMessage!,
              onRetry: () => context.read<ServiceBloc>().fetchServices(),
            );
          }

          final grouped = <String, List<ServiceItem>>{};
          for (final item in state.items) {
            grouped.putIfAbsent(item.category, () => []).add(item);
          }

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            children: [
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search services or categories...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: const Color(0xFFF7F7F8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(26),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              ...grouped.entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                  child: Column(
                    children: [
                      Container(
                        height: 56,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE12242),
                          borderRadius: BorderRadius.circular(28),
                        ),
                        child: Center(
                          child: Text(
                            entry.key,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          int crossAxisCount;
                          if (constraints.maxWidth < 700) {
                            crossAxisCount = 1;
                          } else if (constraints.maxWidth < 1100) {
                            crossAxisCount = 2;
                          } else {
                            crossAxisCount = 3;
                          }

                          return GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: context.isMobile ? 2.2 : 2.4,
                            ),
                            itemCount: entry.value.length,
                            itemBuilder: (_, index) {
                              final item = entry.value[index];
                              return ServiceCard(
                                title: item.name,
                                duration: item.durationMin,
                                price: item.price,
                                consentRequired: item.consentRequired,
                                isSelected: session.selectedServices.contains(item),
                                onTap: () => context.read<SessionBloc>().toggleService(item),
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            height: 58,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(26)),
          ),
          const SizedBox(height: 16),
          Container(
            height: 62,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28)),
          ),
          const SizedBox(height: 12),
          ...List<Widget>.generate(
            6,
            (_) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              height: 84,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
            ),
          ),
        ],
      ),
    );
  }
}
