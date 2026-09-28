import 'package:lavanderia_delivery/core/helpers/generic_data_source.dart';
import 'package:lavanderia_delivery/core/http/either.dart';
import 'package:lavanderia_delivery/core/http/endpoints.dart';
import 'package:lavanderia_delivery/core/http/failure.dart';

abstract interface class LogoutDataSource {
  Future<Either<Failure, void>> logout({required String refreshToken});
}

class LogoutDataSourceImpl implements LogoutDataSource {
  final GenericDataSource _genericDataSource;
  LogoutDataSourceImpl(this._genericDataSource);

  @override
  Future<Either<Failure, void>> logout({required String refreshToken}) async {
    final result = await _genericDataSource.postData<Map<String, dynamic>>(
      endpoint: Endpoints.logout,
      data: {'refreshToken': refreshToken},
    );
    return result.fold((failure) => Left(failure), (_) => const Right(null));
  }
}
