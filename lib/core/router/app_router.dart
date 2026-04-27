import 'package:aaravpos/core/storage/secure_storage.dart';
import 'package:aaravpos/core/utils/helpers/injector.dart';
import 'package:aaravpos/presentation/screens/pages/consent_screen.dart';
import 'package:aaravpos/presentation/screens/pages/date_screen.dart';
import 'package:aaravpos/presentation/screens/pages/details_screen.dart';
import 'package:aaravpos/presentation/screens/pages/home_screen.dart';
import 'package:aaravpos/presentation/screens/pages/login_screen.dart';
import 'package:aaravpos/presentation/screens/pages/review_screen.dart';
import 'package:aaravpos/presentation/screens/pages/services_screen.dart';
import 'package:aaravpos/presentation/screens/pages/slot_screen.dart';
import 'package:aaravpos/presentation/screens/pages/staff_screen.dart';
import 'package:aaravpos/presentation/screens/pages/success_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'app_routes.dart';

class AppRouter {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: AppRoutes.login,
    redirect: (context, state) async {
      // Only run on cold start (navigating to login or root)
      if (state.matchedLocation != AppRoutes.login) return null;

      final token = await getIt<SecureStorage>().getToken();
      if (token != null && token.isNotEmpty) {
        // Token exists — go straight to home, home screen handles outlet status
        return AppRoutes.home;
      }
      return null; // No token — stay on login
    },
    routes: [
      GoRoute(path: AppRoutes.login, builder: (_, _) => const LoginScreen()),
      GoRoute(path: AppRoutes.home, builder: (_, _) => const HomeScreen()),
      GoRoute(
        path: AppRoutes.services,
        builder: (_, _) => const ServicesScreen(),
      ),
      GoRoute(path: AppRoutes.staff, builder: (_, _) => const StaffScreen()),
      GoRoute(path: AppRoutes.date, builder: (_, _) => const DateScreen()),
      GoRoute(path: AppRoutes.slots, builder: (_, _) => const SlotScreen()),
      GoRoute(path: AppRoutes.review, builder: (_, _) => const ReviewScreen()),
      GoRoute(
        path: AppRoutes.consent,
        builder: (_, _) => const ConsentScreen(),
      ),
      GoRoute(
        path: AppRoutes.success,
        builder: (_, _) => const SuccessScreen(),
      ),
      GoRoute(
        path: AppRoutes.details,
        builder: (_, _) => const DetailsScreen(),
      ),
    ],
  );
}
