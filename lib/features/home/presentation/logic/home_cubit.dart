import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lavanderia_delivery/features/home/models/delivery_order_model.dart';

class HomeState extends Equatable {
  final bool isAvailable;
  final int todayTrips;
  final num todayEarnings;
  final List<DeliveryOrderModel> pendingOrders;

  const HomeState({
    this.isAvailable = true,
    this.todayTrips = 0,
    this.todayEarnings = 0,
    this.pendingOrders = const [],
  });

  HomeState copyWith({
    bool? isAvailable,
    int? todayTrips,
    num? todayEarnings,
    List<DeliveryOrderModel>? pendingOrders,
  }) => HomeState(
    isAvailable: isAvailable ?? this.isAvailable,
    todayTrips: todayTrips ?? this.todayTrips,
    todayEarnings: todayEarnings ?? this.todayEarnings,
    pendingOrders: pendingOrders ?? this.pendingOrders,
  );

  @override
  List<Object?> get props => [
    isAvailable,
    todayTrips,
    todayEarnings,
    pendingOrders,
  ];
}

/// حالة التوفر وإحصائيات اليوم وليست الطلبات الجديدة (داتا تجريبية لحد ما الـ API يجهز)
class HomeCubit extends Cubit<HomeState> {
  HomeCubit()
    : super(
        HomeState(
          todayTrips: 3,
          todayEarnings: 225,
          pendingOrders: MockDeliveryOrders.templates.take(3).toList(),
        ),
      );

  int _nextOrderNumber = 10250;
  int _nextTemplateIndex = 0;

  void toggleAvailability(bool value) =>
      emit(state.copyWith(isAvailable: value));

  /// بيولّد طلب جديد من الداتا التجريبية برقم طلب جديد علشان يتعرض في الـ bottom sheet
  DeliveryOrderModel generateSimulatedOrder() {
    final templates = MockDeliveryOrders.templates;
    final template = templates[_nextTemplateIndex % templates.length];
    _nextTemplateIndex++;
    return template.copyWith(id: 'ORD-${_nextOrderNumber++}');
  }

  void addPendingOrder(DeliveryOrderModel order) {
    emit(state.copyWith(pendingOrders: [order, ..._without(order)]));
  }

  void acceptOrder(DeliveryOrderModel order) {
    emit(
      state.copyWith(
        todayTrips: state.todayTrips + 1,
        todayEarnings: state.todayEarnings + order.price,
        pendingOrders: _without(order),
      ),
    );
  }

  void rejectOrder(DeliveryOrderModel order) {
    emit(state.copyWith(pendingOrders: _without(order)));
  }

  List<DeliveryOrderModel> _without(DeliveryOrderModel order) =>
      state.pendingOrders.where((o) => o.id != order.id).toList();
}
