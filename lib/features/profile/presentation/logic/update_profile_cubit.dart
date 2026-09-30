import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lavanderia_delivery/core/bloc/base_bloc.dart';
import 'package:lavanderia_delivery/features/profile/data/profile_data_source.dart';
import 'package:lavanderia_delivery/features/profile/models/update_profile_request.dart';

/// بتبعت التعديلات لـ PUT api/driver/profile
class UpdateProfileCubit extends Cubit<BaseState<void>> {
  final ProfileDataSource _profileDataSource;

  UpdateProfileCubit(this._profileDataSource) : super(const BaseState<void>());

  Future<void> updateProfile(UpdateProfileRequest request) async {
    emit(const BaseState(status: Status.loading));

    final result = await _profileDataSource.updateProfile(request);

    result.fold(
      (failure) => emit(
        BaseState(status: Status.failure, errorMessage: failure.message),
      ),
      (_) => emit(const BaseState(status: Status.success)),
    );
  }
}
