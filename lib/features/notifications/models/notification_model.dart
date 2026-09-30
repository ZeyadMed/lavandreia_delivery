import 'package:equatable/equatable.dart';

/// إشعار واحد من اللي راجعين من GET api/driver/notifications
class NotificationModel extends Equatable {
  final int id;
  final String title;
  final String body;
  final bool isRead;
  final DateTime? createdAt;

  /// لو الإشعار ليه علاقة برحلة، الضغط عليه بيفتحها
  /// (الحقل مش موضح في الـ swagger فبنقبل أكتر من اسم)
  final int? tripId;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.isRead,
    this.createdAt,
    this.tripId,
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
      tripId: int.tryParse(
        '${json['tripId'] ?? json['deliveryTripId'] ?? json['referenceId'] ?? ''}',
      ),
    );
  }

  NotificationModel copyWith({bool? isRead}) {
    return NotificationModel(
      id: id,
      title: title,
      body: body,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
      tripId: tripId,
    );
  }

  @override
  List<Object?> get props => [id, title, body, isRead, createdAt, tripId];
}
