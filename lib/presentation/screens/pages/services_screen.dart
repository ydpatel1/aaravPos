import 'package:aaravpos/domain/model/service_item.dart';
import 'package:aaravpos/presentation/bloc/service/service_bloc.dart';
import 'package:aaravpos/presentation/bloc/session/session_bloc.dart';
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
import '../widgets/service_card.dart';

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  final Map<String, bool> _expandedCategories = {};

  @override
  void initState() {
    super.initState();
    // Every time ServicesScreen opens, wipe all downstream selections
    // so the user always starts fresh from this point.
    context.read<SessionBloc>().clearServicesAndBelow();
    context.read<ServiceBloc>().fetchServices();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionBloc>().state;

    return Scaffold(
      appBar: CommonAppBar(
        title: 'Select Services',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      bottomNavigationBar: KioskBottomBar(
        total: 'Total: ${session.formattedTotal}',
        subtitle: '${session.selectedServices.length} Services Selected',
        primaryLabel: 'Continue',
        primaryEnabled: session.selectedServices.isNotEmpty,
        onPrimary: () => context.push(AppRoutes.staff),
      ),
      body: BlocBuilder<ServiceBloc, ServiceState>(
        builder: (context, state) {
          if (state.isLoading) return _ServicesShimmer();
          if (state.errorMessage != null) {
            return ErrorStateWidget(
              message: state.errorMessage!,
              onRetry: () => context.read<ServiceBloc>().fetchServices(),
            );
          }

          // Filter by search query
          final filtered = _query.isEmpty
              ? state.items
              : state.items
                    .where(
                      (s) =>
                          s.name.toLowerCase().contains(_query.toLowerCase()) ||
                          s.category.toLowerCase().contains(
                            _query.toLowerCase(),
                          ),
                    )
                    .toList();

          // Group by category
          final grouped = <String, List<ServiceItem>>{};
          for (final item in filtered) {
            grouped.putIfAbsent(item.category, () => []).add(item);
          }

          // Initialize expanded state for new categories
          for (final category in grouped.keys) {
            _expandedCategories.putIfAbsent(category, () => true);
          }

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            children: [
              // Search bar
              TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: 'Search services or categories...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: const Color(0xFFF7F7F8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(26),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(26),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(26),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Category sections with expand/collapse
              ...grouped.entries.map((entry) {
                final isExpanded = _expandedCategories[entry.key] ?? true;
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category header - clickable to expand/collapse
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _expandedCategories[entry.key] =
                                !(_expandedCategories[entry.key] ?? true);
                          });
                        },
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE12242),
                            borderRadius: BorderRadius.circular(28),
                          ),
                          alignment: Alignment.center,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  entry.key,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  isExpanded
                                      ? Icons.expand_less
                                      : Icons.expand_more,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Service grid - shown/hidden based on expansion
                      if (isExpanded)
                        LayoutBuilder(
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
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: entry.value.length,
                              itemBuilder: (context, i) {
                                final item = entry.value[i];
                                return ServiceCard(
                                  title: item.name,
                                  duration: item.durationMin,
                                  price: item.price,
                                  consentRequired: item.consentRequired,
                                  consentTemplateId: item.consentTemplate?.id,
                                  isSelected: session.selectedServices.contains(
                                    item,
                                  ),
                                  onTap: () => context
                                      .read<SessionBloc>()
                                      .toggleService(item),
                                );
                              },
                            );
                          },
                        ),
                    ],
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}

/// Shimmer skeleton that matches the final layout:
/// search bar → category pill → responsive grid × 2 rows, repeated × 3 categories
class _ServicesShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        children: [
          // Search bar skeleton
          ShimmerBox(height: 52, borderRadius: 26),
          const SizedBox(height: AppSpacing.lg),

          // 3 category sections
          for (int c = 0; c < 3; c++) ...[
            // Category header pill
            ShimmerBox(height: 48, borderRadius: 28),
            const SizedBox(height: AppSpacing.md),

            // Grid: 2 rows × cols cards
            LayoutBuilder(
              builder: (context, constraints) {
                final cols = constraints.maxWidth < 550
                    ? 2 // Mobile: 2 items
                    : constraints.maxWidth < 900
                    ? 3 // Tablet: 3 items
                    : 4; // Desktop: 4 items
                final cardAspect = constraints.maxWidth < 550 ? 1.5 : 2.0;
                final cardWidth =
                    (constraints.maxWidth - (cols - 1) * 12) / cols;
                final cardHeight = cardWidth / cardAspect;
                return Column(
                  children: [
                    for (int row = 0; row < 2; row++) ...[
                      Row(
                        children: [
                          for (int col = 0; col < cols; col++) ...[
                            if (col > 0) const SizedBox(width: 12),
                            Expanded(
                              child: ShimmerBox(
                                height: cardHeight,
                                borderRadius: 14,
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (row < 1) const SizedBox(height: 12),
                    ],
                  ],
                );
              },
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ],
      ),
    );
  }
}
