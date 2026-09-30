import 'package:lavanderia_delivery/features/notifications/models/notification_model.dart';

/// صفحة من الإشعارات بالشكل اللي GenericPaginationCubit بيقراه
/// (items + pagination فيها currentPage / pagesCount / perPage / total)
class NotificationsPageModel {
  final List<NotificationModel> items;
  final NotificationsPagination pagination;

  const NotificationsPageModel({required this.items, required this.pagination});

  /// fetchResult بيبعت محتوى data لو كانت Map، أو الريسبونس كله لو data كانت List،
  /// فبندور على الليستة في المفاتيح المعتادة للاتنين
  factory NotificationsPageModel.fromJson(
    Map<String, dynamic> json, {
    required int pageIndex,
    required int pageSize,
  }) {
    final rawList = json['items'] ?? json['data'] ?? json['notifications'];
    final items = rawList is List
        ? rawList
              .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
              .toList()
        : <NotificationModel>[];

    return NotificationsPageModel(
      items: items,
      pagination: NotificationsPagination(
        currentPage: json['pageIndex'] ?? pageIndex,
        pagesCount: json['totalPages'] ?? json['pagesCount'] ?? 0,
        perPage: json['pageSize'] ?? pageSize,
        total: json['totalCount'] ?? json['count'] ?? 0,
      ),
    );
  }
}

class NotificationsPagination {
  final int currentPage;
  final int pagesCount;
  final int perPage;
  final int total;

  const NotificationsPagination({
    required this.currentPage,
    required this.pagesCount,
    required this.perPage,
    required this.total,
  });
}
