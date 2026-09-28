import 'package:lavanderia_delivery/core/helpers/generic_data_source.dart';
import 'package:lavanderia_delivery/core/http/either.dart';
import 'package:lavanderia_delivery/core/http/endpoints.dart';
import 'package:lavanderia_delivery/core/http/failure.dart';
import 'package:lavanderia_delivery/features/auth/models/auth_model.dart';

abstract interface class LoginDataSource {
  Future<Either<Failure, AuthModel>> login({
    required String phoneNumber,
    required String password,
    required bool rememberMe,
    required String deviceInfo,
    required String deviceId,
  });
}

class LoginDataSourceImpl implements LoginDataSource {
  final GenericDataSource _genericDataSource;
  LoginDataSourceImpl(this._genericDataSource);

  @override
  Future<Either<Failure, AuthModel>> login({
    required String phoneNumber,
    required String password,
    required bool rememberMe,
    required String deviceInfo,
    required String deviceId,
  }) async {
    final result = await _genericDataSource.authenticate<AuthModel>(
      endpoint: Endpoints.login,
      data: {
        'phoneNumber': phoneNumber,
        'password': password,
        'rememberMe': rememberMe,
        'deviceInfo': deviceInfo,
        'deviceId': deviceId,
      },
      headers: {'Authorization': null},
      fromJson: (json) => AuthModel.fromJson(json),
    );
    return result;
  }
}
