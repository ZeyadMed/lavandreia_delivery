import 'package:get_it/get_it.dart';
import 'package:lavanderia_delivery/features/profile/data/app_info_data_source.dart';
import 'package:lavanderia_delivery/features/profile/data/profile_data_source.dart';
import 'package:lavanderia_delivery/features/profile/presentation/logic/contact_info_cubit.dart';
import 'package:lavanderia_delivery/features/profile/presentation/logic/delete_account_cubit.dart';
import 'package:lavanderia_delivery/features/profile/presentation/logic/privacy_policy_cubit.dart';
import 'package:lavanderia_delivery/features/profile/presentation/logic/profile_cubit.dart';
import 'package:lavanderia_delivery/features/profile/presentation/logic/update_profile_cubit.dart';

class ProfileServicesLocator {
  static Future<void> init({required GetIt getIt}) async {
    getIt.registerLazySingleton<ProfileDataSource>(
      () => ProfileDataSourceImpl(getIt()),
    );
    getIt.registerFactory<ProfileCubit>(() => ProfileCubit(getIt()));
    getIt.registerFactory<UpdateProfileCubit>(
      () => UpdateProfileCubit(getIt()),
    );
    getIt.registerFactory<DeleteAccountCubit>(
      () => DeleteAccountCubit(getIt()),
    );

    getIt.registerLazySingleton<AppInfoDataSource>(
      () => AppInfoDataSourceImpl(getIt()),
    );
    getIt.registerFactory<ContactInfoCubit>(() => ContactInfoCubit(getIt()));
    getIt.registerFactory<PrivacyPolicyCubit>(
      () => PrivacyPolicyCubit(getIt()),
    );
  }
}
