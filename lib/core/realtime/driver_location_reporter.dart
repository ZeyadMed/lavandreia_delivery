import 'dart:async';
import 'dart:io';

import 'package:geolocator/geolocator.dart';
import 'package:lavanderia_delivery/core/cache_manager/cache_manager.dart';
import 'package:lavanderia_delivery/core/helpers/logger.dart';
import 'package:lavanderia_delivery/core/realtime/location_background_service.dart';
import 'package:lavanderia_delivery/features/trips/data/trips_data_source.dart';

/// بيبعت موقع المندوب للباك طول ما هو متاح، حتى والتطبيق في الخلفية.
/// السيرفر بيبعت NewTripAvailable بس للي بعت موقعه في آخر 15 دقيقة،
/// فمن غيره مافيش popups للرحلات الجديدة. وبيقف بس لما التوفر يتقفل
/// (أو الجلسة تخلص).
///
/// - Android: foreground service في isolate لوحده ([LocationBackgroundService])،
///   فبيكمل كمان بعد ما التطبيق يتقفل من الـ recent apps.
/// - iOS: النظام مابيشغّلش أي كود بعد ما المستخدم يقفل التطبيق خالص، فبنكمل
///   في الخلفية بس عن طريق تحديثات الموقع اللي بتخلي التطبيق صاحي
class DriverLocationReporter {
  final TripsDataSource _dataSource;

  DriverLocationReporter(this._dataSource);

  StreamSubscription<Position>? _positionSubscription;
  Timer? _timer;
  Position? _lastPosition;

  /// بتتنادى لما المندوب يفتح التوفر أو البروفايل يقول إنه متاح،
  /// ومن الـ resume عشان لو الصلاحية اتدت بعدين
  Future<void> start() async {
    await CacheManager.setLocationSharing(true);
    // خدمة موقع من غير صلاحية بتقع على Android 14، فبنستنى الصلاحية
    // (بتتطلب من شاشة الرحلات المتاحة) ونحاول تاني مع الـ resume
    if (!await _hasPermission()) return;
    if (Platform.isAndroid) {
      await LocationBackgroundService.start();
    } else {
      _startForegroundUpdates();
    }
  }

  /// المندوب قفل التوفر أو خرج
  Future<void> stop() async {
    await CacheManager.setLocationSharing(false);
    if (Platform.isAndroid) {
      await LocationBackgroundService.stop();
    } else {
      _stopForegroundUpdates();
    }
  }

  /// التطبيق رجع للواجهة: لو التوفر مفتوح نتأكد إن الإرسال شغال
  Future<void> resume() async {
    if (CacheManager.isLocationSharing()) await start();
  }

  Future<bool> _hasPermission() async {
    try {
      final permission = await Geolocator.checkPermission();
      return permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always;
    } catch (_) {
      return false;
    }
  }

  /// iOS: الـ stream مع allowBackgroundLocationUpdates هو اللي بيخلي النظام
  /// يسيب التطبيق شغال في الخلفية، والتايمر بيبعت آخر موقع كل 90 ثانية
  void _startForegroundUpdates() {
    if (_timer != null) return;
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: AppleSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 50,
        allowBackgroundLocationUpdates: true,
        pauseLocationUpdatesAutomatically: false,
        showBackgroundLocationIndicator: true,
        activityType: ActivityType.automotiveNavigation,
      ),
    ).listen(
      (position) {
        final first = _lastPosition == null;
        _lastPosition = position;
        if (first) _send();
      },
      onError: (e) => loggerWarn('Location stream failed: $e'),
    );
    _timer = Timer.periodic(LocationBackgroundService.interval, (_) => _send());
  }

  void _stopForegroundUpdates() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
    _timer?.cancel();
    _timer = null;
    _lastPosition = null;
  }

  Future<void> _send() async {
    final position = _lastPosition;
    if (position == null) return;
    final result = await _dataSource.updateLocation(
      latitude: position.latitude,
      longitude: position.longitude,
    );
    result.fold(
      (failure) => loggerWarn('Location update failed: ${failure.message}'),
      (_) {},
    );
  }
}
