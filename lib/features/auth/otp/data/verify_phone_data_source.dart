import 'package:lavanderia_delivery/core/helpers/generic_data_source.dart';
import 'package:lavanderia_delivery/core/http/either.dart';
import 'package:lavanderia_delivery/core/http/endpoints.dart';
import 'package:lavanderia_delivery/core/http/failure.dart';
import 'package:lavanderia_delivery/features/auth/models/auth_model.dart';

abstract interface class VerifyPhoneDataSource {
  Future<Either<Failure, AuthModel>> verifyPhone({
    required String phoneNumber,
    required String code,
  });
}

class VerifyPhoneDataSourceImpl implements VerifyPhoneDataSource {
  final GenericDataSource _genericDataSource;
  VerifyPhoneDataSourceImpl(this._genericDataSource);

  @override
  Future<Either<Failure, AuthModel>> verifyPhone({
    required String phoneNumber,
    required String code,
  }) async {
    // postData مش authenticate: حساب المندوب بيبقى تحت المراجعة بعد التفعيل
    // فمش بيدخل ومفيش توكنز نحفظها
    final result = await _genericDataSource.postData<AuthModel>(
      endpoint: Endpoints.verifyPhone,
      data: {'phoneNumber': phoneNumber, 'code': code},
      headers: {'Authorization': null},
      fromJson: (json) => AuthModel.fromJson(json),
    );
    return result;
  }
}
