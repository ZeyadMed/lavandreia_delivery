import 'package:lavanderia_delivery/core/helpers/generic_data_source.dart';
import 'package:lavanderia_delivery/core/http/either.dart';
import 'package:lavanderia_delivery/core/http/endpoints.dart';
import 'package:lavanderia_delivery/core/http/failure.dart';
import 'package:lavanderia_delivery/features/notifications/models/notifications_page_model.dart';

abstract interface class NotificationsDataSource {
  Future<Either<Failure, NotificationsPageModel>> getNotifications({
    required int pageIndex,
    required int pageSize,
  });
  Future<Either<Failure, void>> markAsRead(int notificationId);
  Future<Either<Failure, void>> markAllAsRead();
  Future<Either<Failure, void>> deleteNotification(int notificationId);
  Future<Either<Failure, void>> deleteAll();
}

class NotificationsDataSourceImpl implements NotificationsDataSource {
  final GenericDataSource _genericDataSource;
  NotificationsDataSourceImpl(this._genericDataSource);

  @override
  Future<Either<Failure, NotificationsPageModel>> getNotifications({
    required int pageIndex,
    required int pageSize,
  }) async {
    // مابنستخدمش PaginationParams لأنها بتبعت page و per_page،
    // والباك مستني PageIndex و PageSize
    return _genericDataSource.fetchResult<NotificationsPageModel>(
      endpoint: Endpoints.driverNotifications,
      queryParameters: {'PageIndex': pageIndex, 'PageSize': pageSize},
      fromJson: (json) => NotificationsPageModel.fromJson(
        json,
        pageIndex: pageIndex,
        pageSize: pageSize,
      ),
    );
  }

  @override
  Future<Either<Failure, void>> markAsRead(int notificationId) async {
    final result = await _genericDataSource.updateData<Null>(
      endpoint: Endpoints.readNotification(notificationId),
    );
    return result.fold((failure) => Left(failure), (_) => const Right(null));
  }

  @override
  Future<Either<Failure, void>> markAllAsRead() async {
    final result = await _genericDataSource.updateData<Null>(
      endpoint: Endpoints.readAllNotifications,
    );
    return result.fold((failure) => Left(failure), (_) => const Right(null));
  }

  @override
  Future<Either<Failure, void>> deleteNotification(int notificationId) async {
    final result = await _genericDataSource.deleteData<Null>(
      endpoint: Endpoints.notification(notificationId),
    );
    return result.fold((failure) => Left(failure), (_) => const Right(null));
  }

  @override
  Future<Either<Failure, void>> deleteAll() async {
    final result = await _genericDataSource.deleteData<Null>(
      endpoint: Endpoints.driverNotifications,
    );
    return result.fold((failure) => Left(failure), (_) => const Right(null));
  }
}
