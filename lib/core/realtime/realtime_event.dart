import 'package:lavanderia_delivery/features/trips/models/delivery_trip_model.dart';
import 'package:lavanderia_delivery/features/trips/models/order_status.dart';
import 'package:lavanderia_delivery/features/trips/models/trip_request_model.dart';

/// حدث جاي من hub الطلبات (SignalR). كل حدث ليه payload واحد هو الـ DTO كامل،
/// والأحداث بتتعامل كإشارة نعمل بيها refetch، مش المصدر الوحيد للحالة
class RealtimeEvent {
  final String name;
  final Map<String, dynamic> data;

  const RealtimeEvent({required this.name, this.data = const {}});

  /// DeliveryTripDto: رحلة بقت متاحة في نطاق 10 كم من آخر موقع بعتناه
  static const String newTripAvailable = 'NewTripAvailable';

  /// DeliveryTripRequestDto: المغسلة وافقت أو رفضت طلبنا (أو اختارت مندوب تاني)
  static const String tripRequestResolved = 'TripRequestResolved';

  /// OrderDto: أي تغيير في طلب لينا (أو كان لينا) رحلة عليه. الـ id هنا رقم الطلب،
  /// والرحلات اللي جواه مافيهاش الحقول اللي للمندوب بس، فلازم refetch للرحلة
  static const String orderUpdated = 'OrderUpdated';

  /// مش من السيرفر: بيتبعت بعد reconnect أو رجوع التطبيق من الخلفية، لأن الأحداث
  /// اللي فاتت وإحنا مش متوصلين مابتتعادش، فكل شاشة بتجيب حالتها من جديد
  static const String resync = 'Resync';

  /// الأحداث اللي السيرفر بيبعتها للمندوب
  static const List<String> hubMethods = [
    newTripAvailable,
    tripRequestResolved,
    orderUpdated,
  ];

  bool get isNewTrip => name == newTripAvailable;

  bool get isTripRequestResolved => name == tripRequestResolved;

  bool get isOrderUpdated => name == orderUpdated;

  bool get isResync => name == resync;

  /// الرحلة الجديدة في NewTripAvailable
  DeliveryTripModel? get trip =>
      isNewTrip && data.isNotEmpty ? DeliveryTripModel.fromJson(data) : null;

  /// رد المغسلة في TripRequestResolved
  TripRequestModel? get request => isTripRequestResolved && data.isNotEmpty
      ? TripRequestModel.fromJson(data)
      : null;

  int? get tripId => switch (name) {
    newTripAvailable => _int(data['id']),
    tripRequestResolved => _int(data['deliveryTripId']),
    _ => null,
  };

  int? get orderId => switch (name) {
    orderUpdated => _int(data['id']),
    newTripAvailable => _int(data['orderId']),
    _ => null,
  };

  /// حالة الطلب الجديدة في OrderUpdated
  OrderStatus? get orderStatus => isOrderUpdated
      ? OrderStatus.tryParseName(data['status']?.toString())
      : null;

  /// في TripRequestResolved: هل طلبنا هو اللي اتقبل
  bool? get isApproved {
    if (!isTripRequestResolved) return null;
    return switch (request?.status) {
      TripRequestStatus.approved => true,
      TripRequestStatus.rejected => false,
      _ => null,
    };
  }

  static int? _int(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  @override
  String toString() => 'RealtimeEvent($name, $data)';
}
