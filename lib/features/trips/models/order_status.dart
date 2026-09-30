/// حالة الطلب (enum OrderStatus في الـ swagger).
/// الترتيب لازم يفضل زي الـ swagger بالظبط لأن الباك ممكن يرجعها رقم،
/// والحالات الجديدة الباك بيضيفها في الآخر
enum OrderStatus {
  newOrder('New'),
  awaitingPickup('AwaitingPickup'),
  atLaundryPendingMatch('AtLaundryPendingMatch'),
  adjustmentPendingApproval('AdjustmentPendingApproval'),
  inProgress('InProgress'),
  ready('Ready'),
  outForDelivery('OutForDelivery'),
  delivered('Delivered'),
  rejected('Rejected'),

  /// المغسلة وافقت على مندوب التسليم ومستنية تأكد إنها سلّمته الهدوم
  /// (confirm-handover)، وقبلها مينفعش arrive
  awaitingDropoffCollection('AwaitingDropoffCollection'),
  pickupFailed('PickupFailed'),
  deliveryFailed('DeliveryFailed'),
  cancelled('Cancelled'),

  /// قيمة مش معروفة أو مش موجودة. مش بتتحسب على أي حالة حقيقية،
  /// والمرحلة بتتحدد ساعتها من حالة الرحلة نفسها
  unknown('');

  final String apiValue;

  const OrderStatus(this.apiValue);

  static OrderStatus parse(dynamic value) {
    if (value is num) {
      final index = value.toInt();
      // unknown مش ليها رقم عند الباك
      return index >= 0 && index < unknown.index
          ? OrderStatus.values[index]
          : unknown;
    }
    return tryParseName(value?.toString()) ?? unknown;
  }

  /// بالاسم بس، عشان نفرّق بين حالة طلب وحالة رحلة جوه نفس الحقل
  static OrderStatus? tryParseName(String? value) {
    final text = value?.trim().toLowerCase() ?? '';
    if (text.isEmpty) return null;
    for (final status in values) {
      if (status != unknown && status.apiValue.toLowerCase() == text) {
        return status;
      }
    }
    return null;
  }

  /// الهدوم وصلت المغسلة، يعني رحلة الاستلام خلصت
  bool get isAfterPickup => const {
    atLaundryPendingMatch,
    adjustmentPendingApproval,
    inProgress,
    ready,
    awaitingDropoffCollection,
    outForDelivery,
    delivered,
    deliveryFailed,
  }.contains(this);
}
