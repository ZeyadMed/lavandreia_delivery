import 'package:equatable/equatable.dart';
import 'package:lavanderia_delivery/features/trips/models/json_reader.dart';

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
/// الـ enum الحقيقي مش موجود في الـ swagger، فبنستنتجها من الاسم
/// ومن حالة الطلب ومن وجود الـ OTP لحد ما الباك يوثقها
enum TripStage {
  /// لسه من غير سواق
  awaitingDriver,

  /// اتعيّن علينا ولسه ماستلمناش الهدوم (أو لسه ماوصلناش العميل في التسليم)
  assigned,

  /// Pickup: استلمنا من العميل وماشيين للمغسلة ومعانا OTP
  collected,

  /// Dropoff: وصلنا باب العميل ومعانا OTP مستنيين يأكده
  arrived,
  completed,
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
  final String orderStatus;
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
    this.orderStatus = '',
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

    return DeliveryTripModel(
      id: json.pickInt(['id', 'tripId', 'deliveryTripId']) ?? 0,
      orderId: json.pickInt(['orderId']) ?? order.pickInt(['id']),
      type: TripType.parse(json.pick(['type', 'tripType'])),
      rawStatus: json.pickString(['status', 'tripStatus']),
      orderStatus: _or(
        json.pickString(['orderStatus'], inside: inOrder),
        order.pickString(['status']),
      ),
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

  TripStage get stage {
    final status = rawStatus.toLowerCase();
    final order = orderStatus.toLowerCase();

    if (status.contains('cancel') || order == 'rejected') {
      return TripStage.cancelled;
    }
    if (status.contains('complet') ||
        status.contains('deliver') ||
        status.contains('confirm') ||
        status.contains('done') ||
        _orderPassedTrip(order)) {
      return TripStage.completed;
    }
    if (status.contains('arriv')) return TripStage.arrived;
    if (status.contains('collect') ||
        status.contains('picked') ||
        status.contains('transit')) {
      return TripStage.collected;
    }
    if (status.contains('pending') ||
        status.contains('available') ||
        status.contains('open') ||
        status == 'new') {
      return TripStage.awaitingDriver;
    }
    // الـ OTP بيرجع بس بعد collect أو arrive
    if (otpCode != null) {
      return type == TripType.pickup ? TripStage.collected : TripStage.arrived;
    }
    return TripStage.assigned;
  }

  /// حالة الطلب بتقول الرحلة خلصت حتى لو حالة الرحلة نفسها مش واضحة:
  /// الاستلام بيخلص لما الطلب يوصل المغسلة، والتسليم لما يبقى Delivered
  bool _orderPassedTrip(String order) {
    if (order.isEmpty) return false;
    if (type == TripType.dropoff) return order == 'delivered';
    const afterPickup = {
      'atlaundrypendingmatch',
      'adjustmentpendingapproval',
      'inprogress',
      'ready',
      'outfordelivery',
      'delivered',
    };
    return afterPickup.contains(order);
  }

  bool get isActive =>
      stage != TripStage.completed &&
      stage != TripStage.cancelled &&
      stage != TripStage.awaitingDriver;

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
