import 'package:equatable/equatable.dart';

/// إشعار واحد من اللي راجعين من GET api/driver/notifications
class NotificationModel extends Equatable {
  final int id;
  final String title;
  final String body;
  final bool isRead;
  final DateTime? createdAt;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.isRead,
    this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? json['notificationId'] ?? 0,
      title: json['title'] ?? '',
      // الـ swagger مش موضح اسم الحقل، فبنقبل الاتنين
      body: json['body'] ?? json['message'] ?? '',
      isRead: json['isRead'] ?? false,
      createdAt: DateTime.tryParse(
        json['createdAt'] ?? json['sentAt'] ?? '',
      )?.toLocal(),
    );
  }

  NotificationModel copyWith({bool? isRead}) {
    return NotificationModel(
      id: id,
      title: title,
      body: body,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [id, title, body, isRead, createdAt];
}
