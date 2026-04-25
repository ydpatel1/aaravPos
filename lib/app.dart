import 'package:aaravpos/presentation/bloc/auth/auth_bloc.dart';
import 'package:aaravpos/presentation/bloc/booking/booking_bloc.dart';
import 'package:aaravpos/presentation/bloc/consent/consent_bloc.dart';
import 'package:aaravpos/presentation/bloc/customer/customer_bloc.dart';
import 'package:aaravpos/presentation/bloc/service/service_bloc.dart';
import 'package:aaravpos/presentation/bloc/session/session_bloc.dart';
import 'package:aaravpos/presentation/bloc/slot/slot_bloc.dart';
import 'package:aaravpos/presentation/bloc/staff/staff_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/constants/app_constants.dart';
import 'core/utils/helpers/injector.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

class AaravPosApp extends StatelessWidget {
  const AaravPosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: getIt<AuthBloc>()),
        BlocProvider<SessionBloc>.value(value: getIt<SessionBloc>()),
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
