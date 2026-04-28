import 'package:aaravpos/data/auth/auth_remote_data_source.dart';
import 'package:aaravpos/data/auth/auth_repository_impl.dart';
import 'package:aaravpos/data/booking/booking_remote_data_source.dart';
import 'package:aaravpos/data/booking/booking_repository_impl.dart';
import 'package:aaravpos/domain/repo/auth_repository.dart';
import 'package:aaravpos/domain/repo/booking_repository.dart';
import 'package:aaravpos/presentation/bloc/auth/auth_bloc.dart';
import 'package:aaravpos/presentation/bloc/booking/booking_bloc.dart';
import 'package:aaravpos/presentation/bloc/consent/consent_bloc.dart';
import 'package:aaravpos/presentation/bloc/customer/customer_bloc.dart';
import 'package:aaravpos/presentation/bloc/service/service_bloc.dart';
import 'package:aaravpos/presentation/bloc/session/session_bloc.dart';
import 'package:aaravpos/presentation/bloc/slot/slot_bloc.dart';
import 'package:aaravpos/presentation/bloc/staff/staff_bloc.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../network/api_service.dart';
import '../../network/dio_client.dart';
import '../../storage/secure_storage.dart';

final GetIt getIt = GetIt.instance;

Future<void> configureDependencies(
  GlobalKey<NavigatorState> navigatorKey,
) async {
  if (getIt.isRegistered<SecureStorage>()) {
    return;
  }

  getIt.registerLazySingleton<SecureStorage>(SecureStorage.new);
  getIt.registerLazySingleton<DioClient>(
    () => DioClient(getIt(), navigatorKey: navigatorKey),
  );
  getIt.registerLazySingleton<ApiService>(() => ApiService(getIt()));

  getIt.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSource(getIt()),
  );
  getIt.registerLazySingleton<BookingRemoteDataSource>(
    () => BookingRemoteDataSource(getIt()),
  );
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(getIt(), getIt()),
  );
  getIt.registerLazySingleton<SessionBloc>(SessionBloc.new);
  getIt.registerLazySingleton<AuthBloc>(() => AuthBloc(getIt(), getIt()));

  getIt.registerLazySingleton<BookingRepository>(
    () => BookingRepositoryImpl(getIt(), getIt()),
  );
  getIt.registerLazySingleton<ServiceBloc>(() => ServiceBloc(getIt()));
  getIt.registerLazySingleton<StaffBloc>(() => StaffBloc(getIt()));
  getIt.registerLazySingleton<SlotBloc>(() => SlotBloc(getIt()));
  getIt.registerLazySingleton<CustomerBloc>(() => CustomerBloc(getIt()));
  getIt.registerLazySingleton<ConsentBloc>(() => ConsentBloc(getIt(), getIt()));
  getIt.registerLazySingleton<BookingBloc>(() => BookingBloc(getIt(), getIt()));
}
