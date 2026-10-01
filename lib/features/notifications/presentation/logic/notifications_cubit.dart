import 'dart:async';

import 'package:lavanderia_delivery/core/bloc/genaric_pagination.dart';
import 'package:lavanderia_delivery/core/http/either.dart';
import 'package:lavanderia_delivery/core/http/failure.dart';
import 'package:lavanderia_delivery/core/realtime/realtime_event.dart';
import 'package:lavanderia_delivery/core/realtime/realtime_service.dart';
import 'package:lavanderia_delivery/features/notifications/data/notifications_data_source.dart';
import 'package:lavanderia_delivery/features/notifications/models/notification_model.dart';

/// إشعارات المندوب بالصفحات + القراية والمسح.
///
/// القراية والمسح بيتطبقوا على الليستة فوراً وبعدين بيتبعتوا، ولو الريكوست
/// فشل بنرجّع الليستة زي ما كانت. الدوال دي بترجع رسالة الخطأ (أو null)
/// عشان الشاشة تعرضها، بدل ما نغيّر الـ status ونشيل الليستة من قدام المندوب.
///
/// كل حدث realtime بيتحفظ إشعار عند الباك، وبعد الـ resync ممكن يكون فاتنا
/// إشعارات، فبنعمل refresh عشان الجديد يظهر من غير سحب
class NotificationsCubit extends GenericPaginationCubit<NotificationModel> {
  final NotificationsDataSource _dataSource;
  StreamSubscription<RealtimeEvent>? _subscription;

  static const int _pageSize = 20;

  NotificationsCubit(this._dataSource, RealtimeService realtime) {
    _subscription = realtime.events.listen((_) {
      if (!isClosed) refresh();
    });
  }

  @override
  Future<Either<Failure, dynamic>> loadPage(int page) {
    return _dataSource.getNotifications(pageIndex: page, pageSize: _pageSize);
  }

  Future<String?> markAsRead(int id) async {
    final previous = state.items;
    final index = previous.indexWhere((n) => n.id == id);
    if (index == -1 || previous[index].isRead) return null;

    emit(
      state.copyWith(
        items: [
          for (final n in previous) n.id == id ? n.copyWith(isRead: true) : n,
        ],
      ),
    );
    return _revertOnFailure(await _dataSource.markAsRead(id), previous);
  }

  Future<String?> markAllAsRead() async {
    final previous = state.items;
    if (previous.every((n) => n.isRead)) return null;

    emit(
      state.copyWith(
        items: [for (final n in previous) n.copyWith(isRead: true)],
      ),
    );
    return _revertOnFailure(await _dataSource.markAllAsRead(), previous);
  }

  Future<String?> deleteNotification(int id) async {
    final previous = state.items;
    emit(state.copyWith(items: previous.where((n) => n.id != id).toList()));
    return _revertOnFailure(await _dataSource.deleteNotification(id), previous);
  }

  Future<String?> deleteAll() async {
    final previous = state.items;
    emit(state.copyWith(items: const []));
    return _revertOnFailure(await _dataSource.deleteAll(), previous);
  }

  String? _revertOnFailure(
    Either<Failure, void> result,
    List<NotificationModel> previous,
  ) {
    return result.fold((failure) {
      if (!isClosed) emit(state.copyWith(items: previous));
      return failure.message;
    }, (_) => null);
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
