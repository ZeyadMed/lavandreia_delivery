import 'package:lavanderia_delivery/core/helpers/generic_data_source.dart';
import 'package:lavanderia_delivery/core/http/either.dart';
import 'package:lavanderia_delivery/core/http/endpoints.dart';
import 'package:lavanderia_delivery/core/http/failure.dart';
import 'package:lavanderia_delivery/features/profile/models/driver_profile_model.dart';
import 'package:lavanderia_delivery/features/profile/models/update_profile_request.dart';

abstract interface class ProfileDataSource {
  Future<Either<Failure, DriverProfileModel>> getProfile();
  Future<Either<Failure, void>> updateProfile(UpdateProfileRequest request);
  Future<Either<Failure, void>> deleteAccount();
}

class ProfileDataSourceImpl implements ProfileDataSource {
  final GenericDataSource _genericDataSource;
  ProfileDataSourceImpl(this._genericDataSource);

  @override
  Future<Either<Failure, DriverProfileModel>> getProfile() async {
    return _genericDataSource.fetchResult<DriverProfileModel>(
      endpoint: Endpoints.driverProfile,
      fromJson: DriverProfileModel.fromJson,
    );
  }

  @override
  Future<Either<Failure, void>> updateProfile(
    UpdateProfileRequest request,
  ) async {
    final result = await _genericDataSource.updateData<Null>(
      endpoint: Endpoints.driverProfile,
      data: request.toJson(),
    );
    return result.fold((failure) => Left(failure), (_) => const Right(null));
  }

  @override
  Future<Either<Failure, void>> deleteAccount() async {
    final result = await _genericDataSource.deleteData<Null>(
      endpoint: Endpoints.deleteAccount,
    );
    return result.fold((failure) => Left(failure), (_) => const Right(null));
  }
}
