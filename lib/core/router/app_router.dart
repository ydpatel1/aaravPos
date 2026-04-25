import 'package:aaravpos/features/booking/presentation/pages/slot_screen.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/pages/login_screen.dart';
import '../../features/booking/presentation/pages/consent_screen.dart';
import '../../features/booking/presentation/pages/date_screen.dart';
import '../../features/booking/presentation/pages/details_screen.dart';
import '../../features/booking/presentation/pages/home_screen.dart';
import '../../features/booking/presentation/pages/review_screen.dart';
import '../../features/booking/presentation/pages/services_screen.dart';
import '../../features/booking/presentation/pages/staff_screen.dart';
import '../../features/booking/presentation/pages/success_screen.dart';
import 'app_routes.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.login,
    routes: [
      GoRoute(path: AppRoutes.login, builder: (_, __) => const LoginScreen()),
      GoRoute(path: AppRoutes.home, builder: (_, __) => const HomeScreen()),
      GoRoute(
        path: AppRoutes.services,
        builder: (_, __) => const ServicesScreen(),
      ),
      GoRoute(path: AppRoutes.staff, builder: (_, __) => const StaffScreen()),
      GoRoute(path: AppRoutes.date, builder: (_, __) => const DateScreen()),
      GoRoute(path: AppRoutes.slots, builder: (_, __) => const SlotScreen()),
      GoRoute(path: AppRoutes.review, builder: (_, __) => const ReviewScreen()),
      GoRoute(
        path: AppRoutes.consent,
        builder: (_, __) => const ConsentScreen(),
      ),
      GoRoute(
        path: AppRoutes.success,
        builder: (_, __) => const SuccessScreen(),
      ),
      GoRoute(
        path: AppRoutes.details,
        builder: (_, __) => const DetailsScreen(),
      ),
    ],
  );
}
