/// حدث جاي من السيرفر، سواء من SignalR أو من push (FCM) لما SignalR مش متوصل.
///
/// أسامي الأحداث والـ payload لسه مش متوثقة من الباك، فبنقرا المفاتيح
/// المعتادة ونسيب الـ data كلها متاحة للي محتاج حاجة زيادة
class RealtimeEvent {
  final String name;
  final Map<String, dynamic> data;

  const RealtimeEvent({required this.name, this.data = const {}});

  /// TripRequestResolved: المغسلة اختارت مندوب للرحلة (إحنا أو غيرنا)
  static const String tripRequestResolved = 'TripRequestResolved';

  /// أي تغيير في حالة رحلة أو طلب: تأكيد الـ OTP، التسليم، إلخ
  static const String tripUpdated = 'TripUpdated';
  static const String orderUpdated = 'OrderUpdated';

  /// رحلة جديدة بقت متاحة في النطاق (لو الباك وفّره)
  static const String newTripAvailable = 'NewTripAvailable';

  /// كل الأسامي اللي بنسمع عليها في الـ hub، اللي مش بيتبعت منها مابيأثرش
  static const List<String> hubMethods = [
    tripRequestResolved,
    tripUpdated,
    orderUpdated,
    newTripAvailable,
    'TripAvailable',
    'TripCreated',
    'PickupConfirmed',
    'DropoffConfirmed',
    'TripCompleted',
    'ReceiveNotification',
    'NotificationReceived',
  ];

  bool get isTripRequestResolved =>
      _sameName(tripRequestResolved) || data['type'] == tripRequestResolved;

  bool get isNewTrip =>
      _sameName(newTripAvailable) ||
      _sameName('TripAvailable') ||
      _sameName('TripCreated');

  int? get tripId => _int(data['tripId'] ?? data['deliveryTripId']);

  int? get orderId => _int(data['orderId']);

  /// في TripRequestResolved: هل الطلب بتاعنا هو اللي اتقبل
  bool? get isApproved {
    final raw = data['approved'] ?? data['isApproved'] ?? data['status'];
    if (raw is bool) return raw;
    if (raw is String) {
      final value = raw.toLowerCase();
      if (value == 'approved' || value == 'true') return true;
      if (value == 'rejected' || value == 'false') return false;
    }
    return null;
  }

  bool _sameName(String other) => name.toLowerCase() == other.toLowerCase();

  static int? _int(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  @override
  String toString() => 'RealtimeEvent($name, $data)';
}
