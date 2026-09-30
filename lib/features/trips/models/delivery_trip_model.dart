import 'package:equatable/equatable.dart';
import 'package:lavanderia_delivery/features/trips/models/json_reader.dart';
import 'package:lavanderia_delivery/features/trips/models/order_status.dart';

/// Pickup: من بيت العميل للمغسلة، Dropoff: من المغسلة لبيت العميل
enum TripType {
  pickup('Pickup'),
  dropoff('Dropoff');

  /// القيمة اللي بتتبعت في الـ query (enum DeliveryTripType في الـ swagger)
  final String apiValue;

  const TripType(this.apiValue);

  static TripType parse(dynamic value) {
    if (value is num) return value.toInt() == 1 ? dropoff : pickup;
    final text = value?.toString().toLowerCase() ?? '';
    return text.contains('drop') || text.contains('deliver') ? dropoff : pickup;
  }
}

/// المرحلة اللي الرحلة فيها من ناحية المندوب.
/// بتتحدد من حالة الطلب الأول لأنها متوثقة في الـ swagger، ولو مش كفاية
/// (زي AwaitingPickup اللي بتفضل طول رحلة الاستلام) من حالة الرحلة والـ OTP
enum TripStage {
  /// لسه من غير سواق
  awaitingDriver,

  /// Dropoff: المغسلة اختارتنا ورايحين ناخد الهدوم، ومستنيين المغسلة
  /// تأكد التسليم (confirm-handover) قبل ما نتحرك للعميل
  awaitingHandover,

  /// اتعيّن علينا ولسه ماستلمناش الهدوم (أو لسه ماوصلناش العميل في التسليم)
  assigned,

  /// Pickup: استلمنا من العميل وماشيين للمغسلة ومعانا OTP
  collected,

  /// Dropoff: وصلنا باب العميل ومعانا OTP مستنيين يأكده
  arrived,
  completed,

  /// PickupFailed أو DeliveryFailed: العميل مش موجود أو العنوان غلط
  failed,
  cancelled,
}

/// نقطة في الرحلة: العميل أو المغسلة
class TripPoint extends Equatable {
  final String name;
  final String phone;
  final String address;
  final double? latitude;
  final double? longitude;

  const TripPoint({
    this.name = '',
    this.phone = '',
    this.address = '',
    this.latitude,
    this.longitude,
  });

  bool get hasLocation => latitude != null && longitude != null;

  @override
  List<Object?> get props => [name, phone, address, latitude, longitude];
}

/// رحلة استلام أو تسليم، نفس الموديل للمتاحة وللي اتعيّنت علينا
class DeliveryTripModel extends Equatable {
  final int id;
  final int? orderId;
  final TripType type;
  final String rawStatus;
  final OrderStatus orderStatus;
  final num fee;
  final double? distanceKm;
  final TripPoint customer;
  final TripPoint laundry;
  final String? otpCode;
  final int? itemsCount;

  /// المندوب ده طلب الرحلة ولسه مستني المغسلة
  final bool isRequestedByMe;
  final DateTime? createdAt;
  final DateTime? completedAt;

  const DeliveryTripModel({
    required this.id,
    required this.type,
    this.orderId,
    this.rawStatus = '',
    this.orderStatus = OrderStatus.unknown,
    this.fee = 0,
    this.distanceKm,
    this.customer = const TripPoint(),
    this.laundry = const TripPoint(),
    this.otpCode,
    this.itemsCount,
    this.isRequestedByMe = false,
    this.createdAt,
    this.completedAt,
  });

  factory DeliveryTripModel.fromJson(Map<String, dynamic> json) {
    // بيانات الرحلة ممكن تيجي في الروت أو جوه order / laundry / customer
    const inOrder = ['order'];
    const inLaundry = ['laundry', 'order'];
    const inCustomer = ['customer', 'order'];
    final laundry = json.pickMap(['laundry']) ?? const {};
    final customer = json.pickMap(['customer']) ?? const {};
    final order = json.pickMap(['order']) ?? const {};

    final rawStatus = json.pickString(['status', 'tripStatus']);
    var orderStatus = OrderStatus.parse(
      json.pick(['orderStatus'], inside: inOrder) ?? order['status'],
    );
    // لو حالة الطلب مش جاية لوحدها، ممكن تكون هي نفسها اللي في status
    if (orderStatus == OrderStatus.unknown) {
      orderStatus = OrderStatus.tryParseName(rawStatus) ?? OrderStatus.unknown;
    }

    return DeliveryTripModel(
      id: json.pickInt(['id', 'tripId', 'deliveryTripId']) ?? 0,
      orderId: json.pickInt(['orderId']) ?? order.pickInt(['id']),
      type: TripType.parse(json.pick(['type', 'tripType'])),
      rawStatus: rawStatus,
      orderStatus: orderStatus,
      fee: json.pickDouble(['fee', 'deliveryFee', 'amount', 'price']) ?? 0,
      distanceKm: json.pickDouble(['distanceKm', 'distance']),
      laundry: TripPoint(
        name: _or(
          json.pickString(['laundryName'], inside: inLaundry),
          laundry.pickString(['name', 'nameAr', 'nameEn']),
        ),
        phone: _or(
          json.pickString([
            'laundryPhoneNumber',
            'laundryPhone',
          ], inside: inLaundry),
          laundry.pickString(['phoneNumber', 'phone']),
        ),
        address: _or(
          json.pickString(['laundryAddress'], inside: inLaundry),
          laundry.pickString(['address']),
        ),
        latitude:
            json.pickDouble(['laundryLatitude'], inside: inLaundry) ??
            laundry.pickDouble(['latitude', 'lat']),
        longitude:
            json.pickDouble(['laundryLongitude'], inside: inLaundry) ??
            laundry.pickDouble(['longitude', 'lng']),
      ),
      customer: TripPoint(
        // اسم ورقم اللي هيسلّم أو يستلم الهدوم لو مش العميل نفسه
        name: _or(
          json.pickString([
            'pickupContactName',
            'contactName',
            'customerName',
          ], inside: inCustomer),
          customer.pickString(['fullName', 'name']),
        ),
        phone: _or(
          json.pickString([
            'pickupContactPhoneNumber',
            'contactPhoneNumber',
            'customerPhoneNumber',
            'customerPhone',
          ], inside: inCustomer),
          customer.pickString(['phoneNumber', 'phone']),
        ),
        address: json.pickString([
          'deliveryAddress',
          'customerAddress',
          'address',
        ], inside: inCustomer),
        latitude: json.pickDouble([
          'customerLatitude',
          'deliveryLatitude',
          'latitude',
        ], inside: inCustomer),
        longitude: json.pickDouble([
          'customerLongitude',
          'deliveryLongitude',
          'longitude',
        ], inside: inCustomer),
      ),
      otpCode: _nonEmpty(json.pickString(['otpCode', 'otp', 'code'])),
      itemsCount: json.pickInt(['itemsCount', 'piecesCount'], inside: inOrder),
      isRequestedByMe:
          json.pick(['isRequested', 'isRequestedByMe', 'hasRequested']) == true,
      createdAt: json.pickDate(['createdAt', 'createdAtUtc']),
      completedAt: json.pickDate(['completedAt', 'completedAtUtc']),
    );
  }

  static String _or(String value, String fallback) =>
      value.isNotEmpty ? value : fallback;

  static String? _nonEmpty(String value) => value.isEmpty ? null : value;

  /// من فين لفين حسب نوع الرحلة
  TripPoint get from => type == TripType.pickup ? customer : laundry;

  TripPoint get to => type == TripType.pickup ? laundry : customer;

  TripStage get stage => _stageFromOrder() ?? _stageFromTripStatus();

  /// null لو حالة الطلب مش كفاية تحدد المرحلة
  TripStage? _stageFromOrder() {
    final order = orderStatus;
    if (type == TripType.pickup) {
      if (order == OrderStatus.pickupFailed) return TripStage.failed;
      // الهدوم وصلت المغسلة، حتى لو اللي حصل بعد كده فشل في التسليم
      if (order.isAfterPickup) return TripStage.completed;
      if (order == OrderStatus.rejected) return TripStage.cancelled;
      if (order == OrderStatus.cancelled) {
        return _tripStatusSaysCompleted
            ? TripStage.completed
            : TripStage.cancelled;
      }
      // New / AwaitingPickup / unknown: حالة الطلب واحدة طول رحلة الاستلام
      return null;
    }

    return switch (order) {
      OrderStatus.delivered => TripStage.completed,
      OrderStatus.deliveryFailed => TripStage.failed,
      OrderStatus.cancelled || OrderStatus.rejected => TripStage.cancelled,
      OrderStatus.awaitingDropoffCollection => TripStage.awaitingHandover,
      OrderStatus.outForDelivery =>
        _tripStatus.contains('arriv') || otpCode != null
            ? TripStage.arrived
            : TripStage.assigned,
      // Ready (المغسلة لسه ماوافقتش) أو unknown
      _ => null,
    };
  }

  /// حالة الرحلة من غير اسم حالة الطلب لو هي اللي جاية في status،
  /// عشان مثلاً AwaitingDropoffCollection فيها كلمة collect
  String get _tripStatus => OrderStatus.tryParseName(rawStatus) != null
      ? ''
      : rawStatus.toLowerCase();

  bool get _tripStatusSaysCompleted {
    final status = _tripStatus;
    return status.contains('complet') ||
        status.contains('deliver') ||
        status.contains('confirm') ||
        status.contains('done');
  }

  /// الـ enum بتاع حالة الرحلة مش موجود في الـ swagger، فبنستنتجها من الاسم
  TripStage _stageFromTripStatus() {
    final status = _tripStatus;
    if (status.contains('cancel')) return TripStage.cancelled;
    if (status.contains('fail')) return TripStage.failed;
    if (_tripStatusSaysCompleted) return TripStage.completed;
    if (status.contains('arriv')) return TripStage.arrived;
    if (status.contains('collect') ||
        status.contains('picked') ||
        status.contains('transit')) {
      return TripStage.collected;
    }
    if (status.contains('pending') ||
        status.contains('available') ||
        status.contains('open') ||
        status == 'new' ||
        (status.isEmpty && orderStatus == OrderStatus.newOrder)) {
      return TripStage.awaitingDriver;
    }
    // الـ OTP بيرجع بس بعد collect أو arrive
    if (otpCode != null) {
      return type == TripType.pickup ? TripStage.collected : TripStage.arrived;
    }
    return TripStage.assigned;
  }

  bool get isActive => switch (stage) {
    TripStage.awaitingDriver ||
    TripStage.completed ||
    TripStage.failed ||
    TripStage.cancelled => false,
    _ => true,
  };

  DeliveryTripModel copyWith({
    String? otpCode,
    String? rawStatus,
    bool? isRequestedByMe,
  }) {
    return DeliveryTripModel(
      id: id,
      orderId: orderId,
      type: type,
      rawStatus: rawStatus ?? this.rawStatus,
      orderStatus: orderStatus,
      fee: fee,
      distanceKm: distanceKm,
      customer: customer,
      laundry: laundry,
      otpCode: otpCode ?? this.otpCode,
      itemsCount: itemsCount,
      isRequestedByMe: isRequestedByMe ?? this.isRequestedByMe,
      createdAt: createdAt,
      completedAt: completedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    orderId,
    type,
    rawStatus,
    orderStatus,
    fee,
    distanceKm,
    customer,
    laundry,
    otpCode,
    itemsCount,
    isRequestedByMe,
    createdAt,
    completedAt,
  ];
}
