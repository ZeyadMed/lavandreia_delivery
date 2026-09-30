import 'package:lavanderia_delivery/core/helpers/generic_data_source.dart';
import 'package:lavanderia_delivery/core/http/either.dart';
import 'package:lavanderia_delivery/core/http/endpoints.dart';
import 'package:lavanderia_delivery/core/http/failure.dart';
import 'package:lavanderia_delivery/features/auth/register/models/driver_register_request.dart';
import 'package:lavanderia_delivery/features/auth/register/models/register_model.dart';

abstract interface class RegisterDataSource {
  Future<Either<Failure, RegisterModel>> register(
    DriverRegisterRequest request,
  );
}

class RegiterDataSourceImpl implements RegisterDataSource {
  final GenericDataSource _genericDataSource;
  RegiterDataSourceImpl(this._genericDataSource);
  @override
  Future<Either<Failure, RegisterModel>> register(
    DriverRegisterRequest request,
  ) async {
    // form-data عشان الصور بتتبعت مع البيانات في نفس الريكوست
    final result = await _genericDataSource.postFormData<RegisterModel>(
      endpoint: Endpoints.register,
      data: request.toFormData(),
      headers: {'Authorization': null},
      fromJson: (json) => RegisterModel.fromJson(json),
    );
    return result;
  }
}
