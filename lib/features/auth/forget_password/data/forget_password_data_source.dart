import 'package:lavanderia_delivery/core/helpers/generic_data_source.dart';
import 'package:lavanderia_delivery/core/http/either.dart';
import 'package:lavanderia_delivery/core/http/endpoints.dart';
import 'package:lavanderia_delivery/core/http/failure.dart';

/// الاتنين بيرجعوا رسالة الباك اللي بتتعرض للمستخدم
abstract interface class ForgetPasswordDataSource {
  Future<Either<Failure, String>> forgotPassword({required String phoneNumber});

  Future<Either<Failure, String>> resetPassword({
    required String phoneNumber,
    required String code,
    required String newPassword,
  });
}

class ForgetPasswordDataSourceImpl implements ForgetPasswordDataSource {
  final GenericDataSource _genericDataSource;
  ForgetPasswordDataSourceImpl(this._genericDataSource);

  /// نفس الاند بوينتس بتخدم كل التطبيقات، والـ accountType هو اللي بيحدد
  /// الباك يدور على الرقم في أنهي حسابات
  static const String _accountType = 'Driver';

  @override
  Future<Either<Failure, String>> forgotPassword({
    required String phoneNumber,
  }) {
    return _genericDataSource.postData<String>(
      endpoint: Endpoints.forgotPassword,
      data: {'phoneNumber': phoneNumber, 'accountType': _accountType},
      headers: {'Authorization': null},
      fromJson: (json) => json['message']?.toString() ?? '',
    );
  }

  @override
  Future<Either<Failure, String>> resetPassword({
    required String phoneNumber,
    required String code,
    required String newPassword,
  }) {
    return _genericDataSource.postData<String>(
      endpoint: Endpoints.resetPassword,
      data: {
        'phoneNumber': phoneNumber,
        'accountType': _accountType,
        'code': code,
        'newPassword': newPassword,
      },
      headers: {'Authorization': null},
      fromJson: (json) => json['message']?.toString() ?? '',
    );
  }
}
