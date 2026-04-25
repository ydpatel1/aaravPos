import 'package:get_it/get_it.dart';

import '../../../features/auth/data/auth_remote_data_source.dart';
import '../../../features/auth/data/auth_repository_impl.dart';
import '../../../features/auth/domain/auth_repository.dart';
import '../../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../../features/booking/data/booking_repository_impl.dart';
import '../../../features/booking/domain/booking_repository.dart';
import '../../../features/booking/presentation/blocs/booking_bloc.dart';
import '../../../features/booking/presentation/blocs/consent_bloc.dart';
import '../../../features/booking/presentation/blocs/customer_bloc.dart';
import '../../../features/booking/presentation/blocs/service_bloc.dart';
import '../../../features/booking/presentation/blocs/slot_bloc.dart';
import '../../../features/booking/presentation/blocs/staff_bloc.dart';
import '../../../features/booking/presentation/blocs/session_bloc.dart';
import '../../network/api_service.dart';
import '../../network/dio_client.dart';
import '../../storage/secure_storage.dart';

final GetIt getIt = GetIt.instance;

Future<void> configureDependencies() async {
  if (getIt.isRegistered<SecureStorage>()) {
    return;
  }

  getIt.registerLazySingleton<SecureStorage>(SecureStorage.new);
  getIt.registerLazySingleton<DioClient>(() => DioClient(getIt()));
  getIt.registerLazySingleton<ApiService>(() => ApiService(getIt()));

  getIt.registerLazySingleton<AuthRemoteDataSource>(() => AuthRemoteDataSource(getIt()));
  getIt.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(getIt(), getIt()));
  getIt.registerLazySingleton<AuthBloc>(() => AuthBloc(getIt()));

  getIt.registerLazySingleton<BookingRepository>(BookingRepositoryImpl.new);
  getIt.registerLazySingleton<SessionBloc>(SessionBloc.new);
  getIt.registerLazySingleton<ServiceBloc>(() => ServiceBloc(getIt()));
  getIt.registerLazySingleton<StaffBloc>(() => StaffBloc(getIt()));
  getIt.registerLazySingleton<SlotBloc>(() => SlotBloc(getIt()));
  getIt.registerLazySingleton<CustomerBloc>(() => CustomerBloc(getIt()));
  getIt.registerLazySingleton<ConsentBloc>(() => ConsentBloc(getIt()));
  getIt.registerLazySingleton<BookingBloc>(() => BookingBloc(getIt()));
}
