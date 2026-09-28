import 'package:lavanderia_delivery/core/helpers/generic_data_source.dart';
import 'package:lavanderia_delivery/core/http/either.dart';
import 'package:lavanderia_delivery/core/http/endpoints.dart';
import 'package:lavanderia_delivery/core/http/failure.dart';
import 'package:lavanderia_delivery/features/auth/models/auth_model.dart';

abstract interface class VerifyPhoneDataSource {
  Future<Either<Failure, AuthModel>> verifyPhone({
    required String phoneNumber,
    required String code,
    required String deviceInfo,
    required String deviceId,
  });
}

class VerifyPhoneDataSourceImpl implements VerifyPhoneDataSource {
  final GenericDataSource _genericDataSource;
  VerifyPhoneDataSourceImpl(this._genericDataSource);

  @override
  Future<Either<Failure, AuthModel>> verifyPhone({
    required String phoneNumber,
    required String code,
    required String deviceInfo,
    required String deviceId,
  }) async {
    final result = await _genericDataSource.authenticate<AuthModel>(
      endpoint: Endpoints.verifyPhone,
      data: {
        'phoneNumber': phoneNumber,
        'code': code,
        'deviceInfo': deviceInfo,
        'deviceId': deviceId,
      },
      headers: {'Authorization': null},
      fromJson: (json) => AuthModel.fromJson(json),
    );
    return result;
  }
}
