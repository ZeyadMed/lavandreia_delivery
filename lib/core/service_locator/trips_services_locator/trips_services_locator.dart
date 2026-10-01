import 'package:get_it/get_it.dart';
import 'package:lavanderia_delivery/core/realtime/driver_location_reporter.dart';
import 'package:lavanderia_delivery/features/home/presentation/logic/home_cubit.dart';
import 'package:lavanderia_delivery/features/trips/data/trips_data_source.dart';
import 'package:lavanderia_delivery/features/trips/presentation/logic/active_trip_cubit.dart';
import 'package:lavanderia_delivery/features/trips/presentation/logic/available_trips_cubit.dart';
import 'package:lavanderia_delivery/features/trips_history/presentation/logic/my_trips_cubit.dart';
import 'package:lavanderia_delivery/features/wallet/data/wallet_data_source.dart';
import 'package:lavanderia_delivery/features/wallet/presentation/logic/wallet_cubit.dart';
import 'package:lavanderia_delivery/features/wallet/presentation/logic/wallet_transactions_cubit.dart';

class TripsServicesLocator {
  static Future<void> init({required GetIt getIt}) async {
    getIt.registerLazySingleton<TripsDataSource>(
      () => TripsDataSourceImpl(getIt()),
    );
    // singleton عشان الإرسال يفضل واحد مهما الشاشات اتفتحت واتقفلت
    getIt.registerLazySingleton<DriverLocationReporter>(
      () => DriverLocationReporter(getIt()),
    );
    getIt.registerFactory<HomeCubit>(
      () => HomeCubit(getIt(), getIt(), getIt(), getIt()),
    );
    getIt.registerFactory<AvailableTripsCubit>(
      () => AvailableTripsCubit(getIt(), getIt(), getIt()),
    );
    getIt.registerFactory<ActiveTripCubit>(
      () => ActiveTripCubit(getIt(), getIt()),
    );
    getIt.registerFactory<MyTripsCubit>(() => MyTripsCubit(getIt()));

    getIt.registerLazySingleton<WalletDataSource>(
      () => WalletDataSourceImpl(getIt()),
    );
    getIt.registerFactory<WalletCubit>(() => WalletCubit(getIt()));
    getIt.registerFactory<WalletTransactionsCubit>(
      () => WalletTransactionsCubit(getIt()),
    );
  }
}
