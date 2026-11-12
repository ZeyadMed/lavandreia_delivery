import 'dart:async';

/// بيبلّغ إن رحلة خلصت، من أي مكان اتفتحت منه (الهوم أو السجل أو إشعار).
/// الهوم عايشة في الـ IndexedStack فمش بتتبني تاني، فبتسمع هنا عشان
/// تحدّث أرباح ورحلات النهارده قبل ما المندوب يرجعلها
class TripCompletionNotifier {
  final _controller = StreamController<int>.broadcast();

  /// بيطلّع id الرحلة اللي خلصت
  Stream<int> get completedTrips => _controller.stream;

  void notify(int tripId) => _controller.add(tripId);
}
