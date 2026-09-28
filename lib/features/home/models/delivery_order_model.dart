import 'package:equatable/equatable.dart';

/// طلب توصيل واحد، نفس البيانات اللي بتظهر في الـ bottom sheet وفي ليست الطلبات الجديدة
class DeliveryOrderModel extends Equatable {
  final String id;
  final String taskType;
  final String pickupName;
  final String pickupAddress;
  final String dropoffName;
  final String dropoffAddress;
  final double distanceKm;
  final int durationMinutes;
  final num price;

  const DeliveryOrderModel({
    required this.id,
    required this.taskType,
    required this.pickupName,
    required this.pickupAddress,
    required this.dropoffName,
    required this.dropoffAddress,
    required this.distanceKm,
    required this.durationMinutes,
    required this.price,
  });

  DeliveryOrderModel copyWith({String? id}) => DeliveryOrderModel(
    id: id ?? this.id,
    taskType: taskType,
    pickupName: pickupName,
    pickupAddress: pickupAddress,
    dropoffName: dropoffName,
    dropoffAddress: dropoffAddress,
    distanceKm: distanceKm,
    durationMinutes: durationMinutes,
    price: price,
  );

  @override
  List<Object?> get props => [id];
}

/// داتا تجريبية لحد ما الـ API يجهز
abstract final class MockDeliveryOrders {
  static const List<DeliveryOrderModel> templates = [
    DeliveryOrderModel(
      id: 'ORD-10246',
      taskType: 'استلام من المغسلة وتسليم للعميل',
      pickupName: 'مغسلة المدينة',
      pickupAddress: 'مدينة نصر، القاهرة',
      dropoffName: 'أحمد محمد',
      dropoffAddress: 'مصر الجديدة، القاهرة',
      distanceKm: 4.5,
      durationMinutes: 18,
      price: 75,
    ),
    DeliveryOrderModel(
      id: 'ORD-10247',
      taskType: 'استلام من العميل وتسليم للمغسلة',
      pickupName: 'محمود علي',
      pickupAddress: 'المعادي، القاهرة',
      dropoffName: 'مغسلة النظافة',
      dropoffAddress: 'زهراء المعادي، القاهرة',
      distanceKm: 3.2,
      durationMinutes: 12,
      price: 50,
    ),
    DeliveryOrderModel(
      id: 'ORD-10248',
      taskType: 'استلام من المغسلة وتسليم للعميل',
      pickupName: 'مغسلة الياسمين',
      pickupAddress: 'الدقي، الجيزة',
      dropoffName: 'سارة إبراهيم',
      dropoffAddress: 'المهندسين، الجيزة',
      distanceKm: 2.8,
      durationMinutes: 10,
      price: 45,
    ),
    DeliveryOrderModel(
      id: 'ORD-10249',
      taskType: 'استلام من العميل وتسليم للمغسلة',
      pickupName: 'خالد حسن',
      pickupAddress: 'التجمع الخامس، القاهرة',
      dropoffName: 'مغسلة المدينة',
      dropoffAddress: 'مدينة نصر، القاهرة',
      distanceKm: 9.1,
      durationMinutes: 25,
      price: 110,
    ),
  ];
}
