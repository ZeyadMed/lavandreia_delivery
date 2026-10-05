import 'dart:convert';
import 'dart:developer';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:lavanderia_delivery/core/cache_manager/cache_manager.dart';
import 'package:lavanderia_delivery/core/realtime/realtime_service.dart';
import 'package:lavanderia_delivery/core/router/app_router.dart';
import 'package:lavanderia_delivery/core/service_locator/service_locator.dart';
import 'package:lavanderia_delivery/features/trips/data/trips_data_source.dart';
import 'package:lavanderia_delivery/main.dart';

import '../helpers/logger.dart';

/// إشعارات FCM. كل حدث SignalR بيتبعت push كمان، فوالتطبيق مفتوح والـ hub
/// متوصل مابنعرضش الإشعار عشان مايبقاش تنبيهين لنفس الحاجة.
///
/// الـ push دلوقتي فيه title و body بس من غير data، فالضغط عليه بيفتح
/// الرحلة الشغالة لو فيه، وإلا بيفتح التطبيق بس
class MessagingConfig {
  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static bool _initializationComplete = false;

  /// إشعارات اتضغطت قبل ما الـ navigator يجهز
  static final List<Map<String, dynamic>> _pendingNotifications = [];

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'This channel is used for important notifications.',
    importance: Importance.max,
  );

  static Future<void> createNotificationChannel() async {
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_channel);
  }

  static Future<void> initFirebaseMessaging() async {
    if (_initializationComplete) return;

    try {
      await createNotificationChannel();

      final FirebaseMessaging messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      log('Notification permission: ${settings.authorizationStatus}');

      const InitializationSettings initializationSettings =
          InitializationSettings(
            android: AndroidInitializationSettings('@mipmap/ic_launcher'),
            iOS: DarwinInitializationSettings(
              requestSoundPermission: false,
              requestBadgePermission: false,
              requestAlertPermission: false,
            ),
          );

      await flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          final payload = response.payload;
          if (payload == null) return;
          try {
            _openFromNotification(jsonDecode(payload) as Map<String, dynamic>);
          } catch (e) {
            log('Error parsing notification payload: $e');
          }
        },
      );

      try {
        await messaging.subscribeToTopic('notifications');
      } catch (e) {
        log('Error subscribing to topic: $e');
      }

      // TODO: مفيش endpoint لتحديث الـ deviceToken عند الباك، بيتبعت مع اللوجين بس
      messaging.onTokenRefresh.listen(CacheManager.saveFcmTokenToken);
      CacheManager.fetchAndSaveFcmToken();

      FirebaseMessaging.onMessage.listen(_onForegroundMessage);

      // الإشعار اللي فتح التطبيق وهو مقفول خالص
      messaging.getInitialMessage().then((RemoteMessage? message) {
        if (message != null) _openFromNotification(message.data);
      });

      FirebaseMessaging.onMessageOpenedApp.listen(
        (message) => _openFromNotification(message.data),
      );

      _initializationComplete = true;

      for (final data in [..._pendingNotifications]) {
        _openFromNotification(data);
      }
      _pendingNotifications.clear();
    } catch (e) {
      log('Error initializing Firebase Messaging: $e');
    }
  }

  static Future<void> _onForegroundMessage(RemoteMessage event) async {
    log('Foreground message received');
    final realtime = getIt<RealtimeService>();
    // نفس الحدث وصل (أو هيوصل) من SignalR واتعرض جوه التطبيق
    if (realtime.isConnected) return;
    realtime.dispatchPush(event.data);

    final RemoteNotification? notification = event.notification;
    if (notification == null) return;
    try {
      await flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: jsonEncode(event.data),
      );
    } catch (err) {
      log('Error showing local notification: $err');
    }
  }

  /// بيشتغل في isolate لوحده من غير DI ولا UI، فمابنعملش فيه غير log.
  /// إشعارات الـ notification بيعرضها النظام بنفسه، والضغط عليها بيوصل
  /// لـ onMessageOpenedApp أو getInitialMessage
  @pragma('vm:entry-point')
  static Future<void> messageHandler(RemoteMessage message) async {
    log('Background message data: ${message.data}');
  }

  static void _openFromNotification(Map<String, dynamic> data) {
    if (!_initializationComplete) {
      _pendingNotifications.add(data);
      return;
    }
    // بعد أول frame عشان الـ navigator يكون جاهز
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await _route(data);
      } catch (e) {
        log('Error processing notification data: $e');
      }
    });
  }

  /// لو الـ data فيها رحلة بنفتحها، وإلا بنسأل الباك على الرحلة الشغالة
  /// (الـ push لسه مافيهوش data). الإشعارات تاب في البوتوم ناف مش route،
  /// فلو مفيش رحلة بنسيب التطبيق مكانه وقايمتها بتتحدث من الـ resync
  static Future<void> _route(Map<String, dynamic> data) async {
    if (navigatorKey.currentContext == null) {
      loggerError('Navigator not ready for notification: $data');
      return;
    }
    // ممكن يكون إشعار قديم والجلسة خلصت
    final token = await CacheManager.getAccessToken();
    if (token == null || token.isEmpty) return;

    var tripId = int.tryParse(
      '${data['deliveryTripId'] ?? data['tripId'] ?? ''}',
    );
    if (tripId == null) {
      final current = await getIt<TripsDataSource>().getCurrentTrip();
      tripId = current.fold((_) => null, (trip) => trip?.id);
    }

    final context = navigatorKey.currentContext;
    if (tripId == null || context == null || !context.mounted) return;
    context.push(AppRouter.activeTrip, extra: tripId);
  }

  static void dispose() {
    flutterLocalNotificationsPlugin.cancelAll();
    _initializationComplete = false;
    _pendingNotifications.clear();
  }
}
