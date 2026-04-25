import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/constants/app_constants.dart';
import 'core/di/injector.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/booking/presentation/blocs/booking_bloc.dart';
import 'features/booking/presentation/blocs/consent_bloc.dart';
import 'features/booking/presentation/blocs/customer_bloc.dart';
import 'features/booking/presentation/blocs/service_bloc.dart';
import 'features/booking/presentation/blocs/slot_bloc.dart';
import 'features/booking/presentation/blocs/staff_bloc.dart';
import 'features/booking/presentation/cubit/session_cubit.dart';

class AaravPosApp extends StatelessWidget {
  const AaravPosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: getIt<AuthBloc>()),
        BlocProvider<SessionCubit>.value(value: getIt<SessionCubit>()),
        BlocProvider<ServiceBloc>.value(value: getIt<ServiceBloc>()),
        BlocProvider<StaffBloc>.value(value: getIt<StaffBloc>()),
        BlocProvider<SlotBloc>.value(value: getIt<SlotBloc>()),
        BlocProvider<CustomerBloc>.value(value: getIt<CustomerBloc>()),
        BlocProvider<ConsentBloc>.value(value: getIt<ConsentBloc>()),
        BlocProvider<BookingBloc>.value(value: getIt<BookingBloc>()),
      ],
      child: MaterialApp.router(
        title: AppConstants.appName,
        theme: AppTheme.lightTheme,
        routerConfig: AppRouter.router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
