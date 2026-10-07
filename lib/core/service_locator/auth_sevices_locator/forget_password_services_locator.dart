import 'package:get_it/get_it.dart';
import 'package:lavanderia_delivery/features/auth/change_password/presentation/logic/reset_password_bloc.dart';
import 'package:lavanderia_delivery/features/auth/forget_password/data/forget_password_data_source.dart';
import 'package:lavanderia_delivery/features/auth/forget_password/presentation/logic/forget_password_bloc.dart';

class ForgetPasswordServicesLocator {
  static Future<void> init({required GetIt getIt}) async {
    getIt.registerLazySingleton<ForgetPasswordDataSource>(
      () => ForgetPasswordDataSourceImpl(getIt()),
    );
    getIt.registerFactory<ForgetPasswordBloc>(
      () => ForgetPasswordBloc(getIt()),
    );
    getIt.registerFactory<ResetPasswordBloc>(() => ResetPasswordBloc(getIt()));
  }
}
