import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:lavanderia_delivery/core/cache_manager/cache_manager.dart';
import 'package:lavanderia_delivery/core/helpers/logger.dart';
import 'package:lavanderia_delivery/core/http/endpoints.dart';
import 'package:lavanderia_delivery/core/http/token_refresh_service.dart';
import 'package:lavanderia_delivery/core/realtime/realtime_event.dart';
import 'package:signalr_netcore/signalr_client.dart';

/// حالة الاتصال اللي بتتعرض للمندوب (شريط "جاري إعادة الاتصال")
enum RealtimeConnection { disconnected, connecting, connected, reconnecting }

/// اتصال SignalR واحد للتطبيق كله على hub الطلبات، والشاشات بتسمع على [events].
///
/// الاتصال من السيرفر للتطبيق بس: مابننادي أي method على الـ hub، والسيرفر
/// بيحط المندوب في الجروب بتاعه من الـ JWT. وبعد أي reconnect بنبعت
/// [RealtimeEvent.resync] عشان الأحداث اللي فاتت مابتتعادش
class RealtimeService {
  final TokenRefreshService _refreshService;

  RealtimeService(this._refreshService);

  final StreamController<RealtimeEvent> _events =
      StreamController<RealtimeEvent>.broadcast();

  /// للـ UI: بيظهر الشريط وقت reconnecting
  final ValueNotifier<RealtimeConnection> connection = ValueNotifier(
    RealtimeConnection.disconnected,
  );

  HubConnection? _hub;
  Future<void>? _starting;
  Timer? _retryTimer;
  int _retryAttempt = 0;

  Stream<RealtimeEvent> get events => _events.stream;

  bool get isConnected => _hub?.state == HubConnectionState.Connected;

  /// بتتنادى من أول شاشة بعد اللوجين أو السبلاش ومع رجوع التطبيق للواجهة،
  /// ولو اتنادت واحنا متوصلين أو بنتوصل مابتعملش حاجة
  Future<void> start() {
    if (isConnected) return Future.value();
    return _starting ??= _connect().whenComplete(() => _starting = null);
  }

  Future<void> _connect() async {
    final token = await CacheManager.getAccessToken();
    if (token == null || token.isEmpty) return;

    final hub = _hub ??= _buildHub();
    // الـ automatic reconnect شغال لوحده، ومابينفعش start وهو في النص
    if (hub.state != HubConnectionState.Disconnected) return;

    _retryTimer?.cancel();
    connection.value = RealtimeConnection.connecting;
    if (await _tryStart(hub)) return _onConnected(hub);

    if (!identical(_hub, hub)) return;
    connection.value = RealtimeConnection.disconnected;
    _scheduleRetry();
  }

  /// الـ hub مابيعديش على الانترسبتور، فلو التوكن خلص بنجدد بنفسنا مرة.
  /// أي خطأ تاني (نت، سيرفر واقع) مالوش علاقة بالتوكن فمابنجددش
  Future<bool> _tryStart(HubConnection hub) async {
    try {
      await hub.start();
      return true;
    } catch (e) {
      loggerWarn('Realtime connect failed: $e');
      if (!e.toString().contains('401')) return false;
      final refreshed = await _refreshService.refresh();
      if (refreshed is! RefreshSuccess || !identical(_hub, hub)) return false;
      try {
        await hub.start();
        return true;
      } catch (e) {
        loggerWarn('Realtime connect failed again: $e');
        return false;
      }
    }
  }

  void _onConnected(HubConnection hub) {
    if (!identical(_hub, hub)) return;
    logger('Realtime connected');
    _retryAttempt = 0;
    connection.value = RealtimeConnection.connected;
  }

  /// لو الاتصال الأول فشل أو الـ automatic reconnect استسلم، بنحاول تاني
  /// بفترات بتطول لحد دقيقة، طول ما الجلسة لسه موجودة
  void _scheduleRetry() {
    _retryTimer?.cancel();
    final seconds = (5 * (1 << _retryAttempt)).clamp(5, 60);
    _retryAttempt++;
    _retryTimer = Timer(Duration(seconds: seconds), () async {
      if (_hub == null) return;
      await start();
      // اتصال بعد انقطاع، فممكن أحداث تكون فاتتنا
      if (isConnected) _emit(const RealtimeEvent(name: RealtimeEvent.resync));
    });
  }

  HubConnection _buildHub() {
    final hub = HubConnectionBuilder()
        .withUrl(
          '${Endpoints.baseUrl}${Endpoints.realtimeHub}',
          options: HttpConnectionOptions(
            // بيتقرا مع كل reconnect عشان ياخد أحدث توكن بعد التجديد
            accessTokenFactory: () async =>
                await CacheManager.getAccessToken() ?? '',
          ),
        )
        .withAutomaticReconnect()
        .build();

    for (final method in RealtimeEvent.hubMethods) {
      hub.on(method, (arguments) => _onHubMessage(method, arguments));
    }
    hub.onreconnecting(({error}) {
      if (!identical(_hub, hub)) return;
      loggerWarn('Realtime reconnecting: $error');
      connection.value = RealtimeConnection.reconnecting;
    });
    hub.onreconnected(({connectionId}) {
      if (!identical(_hub, hub)) return;
      _onConnected(hub);
      _emit(const RealtimeEvent(name: RealtimeEvent.resync));
    });
    hub.onclose(({error}) {
      // stop() بيشيل الـ hub الأول، فده قفل مقصود
      if (!identical(_hub, hub)) return;
      loggerWarn('Realtime closed: $error');
      connection.value = RealtimeConnection.reconnecting;
      _scheduleRetry();
    });
    return hub;
  }

  void _onHubMessage(String method, List<Object?>? arguments) {
    final payload = arguments == null || arguments.isEmpty
        ? null
        : arguments.first;
    _emit(RealtimeEvent(name: method, data: _asMap(payload)));
  }

  /// بيتنادى لما التطبيق يرجع من الخلفية، عشان الشاشة المفتوحة تجيب حالتها
  void resync() => _emit(const RealtimeEvent(name: RealtimeEvent.resync));

  /// الـ push دلوقتي فيه title و body بس، فمابنعتمدش عليه غير كإشارة إن
  /// حاجة اتغيرت وإحنا مش متوصلين، وبنعمل resync
  void dispatchPush(Map<String, dynamic> data) {
    if (isConnected) return;
    final type = data['type']?.toString();
    _emit(
      RealtimeEvent(
        name: RealtimeEvent.hubMethods.contains(type)
            ? type!
            : RealtimeEvent.resync,
        data: data,
      ),
    );
  }

  void _emit(RealtimeEvent event) {
    logger('Realtime event: $event');
    if (!_events.isClosed) _events.add(event);
  }

  Map<String, dynamic> _asMap(Object? payload) {
    if (payload is Map) return Map<String, dynamic>.from(payload);
    if (payload is String && payload.isNotEmpty) {
      try {
        final decoded = jsonDecode(payload);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {}
    }
    return const {};
  }

  /// بتتنادى مع مسح الجلسة (خروج أو انتهاء) عشان الحساب اللي بعده
  /// مايستقبلش أحداث اللي قبله
  Future<void> stop() async {
    _retryTimer?.cancel();
    _retryTimer = null;
    _retryAttempt = 0;
    final hub = _hub;
    _hub = null;
    connection.value = RealtimeConnection.disconnected;
    if (hub == null) return;
    try {
      await hub.stop();
    } catch (e) {
      loggerWarn('Realtime stop failed: $e');
    }
  }
}
