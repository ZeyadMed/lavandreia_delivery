import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lavanderia_delivery/core/bloc/base_bloc.dart';
import 'package:lavanderia_delivery/features/profile/data/profile_data_source.dart';
import 'package:lavanderia_delivery/features/profile/models/driver_profile_model.dart';

/// بتجيب بيانات المندوب لشاشة حسابي
class ProfileCubit extends Cubit<BaseState<DriverProfileModel>> {
  final ProfileDataSource _profileDataSource;

  ProfileCubit(this._profileDataSource)
    : super(const BaseState<DriverProfileModel>());

  Future<void> getProfile() async {
    emit(state.copyWith(status: Status.loading));

    final result = await _profileDataSource.getProfile();

    result.fold(
      (failure) => emit(
        state.copyWith(status: Status.failure, errorMessage: failure.message),
      ),
      (data) => emit(state.copyWith(status: Status.success, data: data)),
    );
  }
}
