import 'dart:async';
import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:lavanderia_delivery/core/cache_manager/cache_manager.dart';
import 'package:lavanderia_delivery/core/helpers/location_service.dart';
import 'package:lavanderia_delivery/core/helpers/logger.dart';
import 'package:lavanderia_delivery/core/http/endpoints.dart';
import 'package:lavanderia_delivery/core/http/token_refresh_service.dart';
import 'package:permission_handler/permission_handler.dart';

/// Android: foreground service بيبعت موقع المندوب كل 90 ثانية في isolate
/// لوحده، فبيكمل والتطبيق في الخلفية أو بعد ما يتقفل من الـ recent apps.
/// بيقف بس لما المندوب يقفل التوفر أو الجلسة تخلص.
///
/// الـ isolate ده مالوش DI ولا الانترسبتور، فبيبعت بـ Dio لوحده وبيجدد
/// التوكن بنفسه لو الـ access token خلص
abstract final class LocationBackgroundService {
  static const String _channelId = 'driver_location';
  static const int _notificationId = 7301;
  static const String stopEvent = 'stop';
  static const Duration interval = Duration(seconds: 90);

  /// الـ autoStartOnBoot اللي اتعمل بيه configure آخر مرة، ولو الصلاحية
  /// اتغيرت بنعمل configure تاني
  static bool? _configuredBootStart;

  static Future<void> _configure() async {
    // Android 14 بيقفل التطبيق لو خدمة موقع بدأت من الخلفية (بعد الريستارت)
    // من غير "السماح طول الوقت"، فمابنشغلهاش لوحدها غير لو الصلاحية متاخدة
    final bootStart = await Permission.locationAlways.isGranted;
    if (_configuredBootStart == bootStart) return;
    // الـ channel لازم يتعمل قبل configure، وأهميته قليلة عشان مايرنّش
    await FlutterLocalNotificationsPlugin()
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            _channelId,
            'مشاركة الموقع',
            description: 'بيظهر طول ما أنت متاح لاستقبال الرحلات',
            importance: Importance.low,
          ),
        );
    await FlutterBackgroundService().configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false,
        // بعد الريستارت الخدمة بتبدأ وبتقف على طول لو التوفر مقفول
        autoStartOnBoot: bootStart,
        isForegroundMode: true,
        notificationChannelId: _channelId,
        foregroundServiceNotificationId: _notificationId,
        initialNotificationTitle: 'أنت متاح لاستقبال الرحلات',
        initialNotificationContent: 'بنشارك موقعك عشان توصلك الرحلات القريبة',
        foregroundServiceTypes: [AndroidForegroundType.location],
      ),
      // iOS مابيستخدمش الخدمة دي، شوف DriverLocationReporter
      iosConfiguration: IosConfiguration(autoStart: false),
    );
    _configuredBootStart = bootStart;
  }

  static Future<void> start() async {
    await _configure();
    final service = FlutterBackgroundService();
    if (await service.isRunning()) return;
    await service.startService();
  }

  static Future<void> stop() async {
    final service = FlutterBackgroundService();
    if (await service.isRunning()) service.invoke(stopEvent);
  }

  @pragma('vm:entry-point')
  static Future<void> onStart(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();
    await CacheManager.init();

    final sender = _LocationSender();
    Timer? timer;
    Future<void> stopSelf() async {
      timer?.cancel();
      await service.stopSelf();
    }

    service.on(stopEvent).listen((_) => stopSelf());

    Future<void> tick() async {
      if (!await sender.send()) await stopSelf();
    }

    await tick();
    timer = Timer.periodic(interval, (_) => tick());
  }
}

class _LocationSender {
  final LocationService _locationService = LocationService();
  final TokenRefreshService _refreshService = TokenRefreshService();
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: Endpoints.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Accept-Encoding': 'identity',
        'Accept-Language': 'ar',
      },
    ),
  );

  /// false معناها الخدمة لازم تقف: التوفر اتقفل أو الجلسة خلصت
  Future<bool> send() async {
    // التطبيق ممكن يكون جدد التوكن أو قفل التوفر أو خرج
    await CacheManager.reload();
    final token = await CacheManager.getAccessToken();
    if (!CacheManager.isLocationSharing() || token == null || token.isEmpty) {
      return false;
    }

    final location = await _locationService.getCurrentPosition(
      requestPermission: false,
    );
    // مفيش GPS أو الصلاحية اتشالت، بنحاول المرة الجاية
    if (!location.isSuccess) return true;
    final data = {
      'latitude': location.latitude,
      'longitude': location.longitude,
    };

    try {
      await _put(token, data);
    } on DioException catch (e) {
      if (e.response?.statusCode != 401) {
        loggerWarn('Background location failed: ${e.message}');
        return true;
      }
      switch (await _refreshService.refresh()) {
        case RefreshSuccess(:final accessToken):
          try {
            await _put(accessToken, data);
          } on DioException catch (e) {
            loggerWarn('Background location failed after refresh: $e');
          }
        case RefreshSessionExpired():
          // التطبيق هيحوّل على اللوجين أول ما يتفتح
          return false;
        case RefreshTransientFailure():
          break;
      }
    }
    return true;
  }

  Future<void> _put(String token, Map<String, dynamic> data) {
    return _dio.put(
      Endpoints.driverLocation,
      data: data,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
  }
}
