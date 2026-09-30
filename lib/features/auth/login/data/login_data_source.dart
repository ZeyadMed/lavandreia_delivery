import 'package:lavanderia_delivery/core/cache_manager/cache_manager.dart';
import 'package:lavanderia_delivery/core/helpers/generic_data_source.dart';
import 'package:lavanderia_delivery/core/http/either.dart';
import 'package:lavanderia_delivery/core/http/endpoints.dart';
import 'package:lavanderia_delivery/core/http/failure.dart';
import 'package:lavanderia_delivery/features/auth/models/auth_model.dart';

abstract interface class LoginDataSource {
  Future<Either<Failure, AuthModel>> login({
    required String phoneNumber,
    required String password,
  });
}

class LoginDataSourceImpl implements LoginDataSource {
  final GenericDataSource _genericDataSource;
  LoginDataSourceImpl(this._genericDataSource);

  @override
  Future<Either<Failure, AuthModel>> login({
    required String phoneNumber,
    required String password,
  }) async {
    final result = await _genericDataSource.authenticate<AuthModel>(
      endpoint: Endpoints.login,
      data: {
        'phoneNumber': phoneNumber,
        'password': password,
        // الجلسة دايماً طويلة، مفيش اختيار للمستخدم
        'rememberMe': true,
        'deviceToken': await _deviceToken(),
      },
      headers: {'Authorization': null},
      fromJson: (json) => AuthModel.fromJson(json),
    );
    return result;
  }

  /// الـ FCM token اللي الباك بيبعت عليه النوتفكيشنز.
  /// بناخد المحفوظ من أول الأبلكيشن، ولو مش موجود بنجيبه من فايربيز تاني
  Future<String> _deviceToken() async {
    final cached = await CacheManager.getFcmToken();
    if (cached != null && cached.isNotEmpty) return cached;
    return await CacheManager.fetchAndSaveFcmToken() ?? '';
  }
}
