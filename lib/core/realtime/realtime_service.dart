import 'dart:async';
import 'dart:convert';

import 'package:lavanderia_delivery/core/cache_manager/cache_manager.dart';
import 'package:lavanderia_delivery/core/helpers/logger.dart';
import 'package:lavanderia_delivery/core/http/endpoints.dart';
import 'package:lavanderia_delivery/core/http/token_refresh_service.dart';
import 'package:lavanderia_delivery/core/realtime/realtime_event.dart';
import 'package:signalr_netcore/signalr_client.dart';

/// اتصال SignalR واحد للتطبيق كله، والشاشات بتسمع على [events].
///
/// الـ push (FCM) بيعدي من هنا كمان عن طريق [dispatchPush]، فلو الـ hub
/// مش متوصل الشاشات برضه بتعرف إن حاجة اتغيرت وتعمل refresh
class RealtimeService {
  final TokenRefreshService _refreshService;

  RealtimeService(this._refreshService);

  final StreamController<RealtimeEvent> _events =
      StreamController<RealtimeEvent>.broadcast();

  HubConnection? _hub;
  Future<void>? _starting;

  Stream<RealtimeEvent> get events => _events.stream;

  bool get isConnected => _hub?.state == HubConnectionState.Connected;

  /// بتتنادى بعد اللوجين أو من السبلاش لو فيه جلسة، ولو اتنادت واحنا
  /// متوصلين أو بنتوصل مابتعملش حاجة
  Future<void> start() {
    if (isConnected) return Future.value();
    return _starting ??= _connect().whenComplete(() => _starting = null);
  }

  Future<void> _connect() async {
    final token = await CacheManager.getAccessToken();
    if (token == null || token.isEmpty) return;

    final hub = _hub ??= _buildHub();
    try {
      await hub.start();
      logger('Realtime connected');
    } catch (e) {
      loggerWarn('Realtime connect failed: $e');
      // الـ hub مابيعديش على الانترسبتور، فلو التوكن خلص بنجدد بنفسنا مرة.
      // أي خطأ تاني (مسار غلط، نت) مالوش علاقة بالتوكن فمابنجددش
      if (!e.toString().contains('401')) return;
      final refreshed = await _refreshService.refresh();
      if (refreshed is! RefreshSuccess) return;
      try {
        await hub.start();
        logger('Realtime connected after token refresh');
      } catch (e) {
        loggerWarn('Realtime connect failed again: $e');
      }
    }
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
    hub.onclose(({error}) => loggerWarn('Realtime closed: $error'));
    return hub;
  }

  void _onHubMessage(String method, List<Object?>? arguments) {
    final payload = arguments == null || arguments.isEmpty
        ? null
        : arguments.first;
    _emit(RealtimeEvent(name: method, data: _asMap(payload)));
  }

  /// الـ push بيوصل بـ data كلها strings، فبنحولها لنفس شكل أحداث الـ hub
  void dispatchPush(Map<String, dynamic> data) {
    final name = (data['type'] ?? data['event'] ?? data['route'] ?? 'Push')
        .toString();
    _emit(RealtimeEvent(name: name, data: data));
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
      return {'message': payload};
    }
    if (payload is num) return {'tripId': payload};
    return const {};
  }

  /// بتتنادى في الخروج عشان الحساب اللي بعده مايستقبلش أحداث اللي قبله
  Future<void> stop() async {
    final hub = _hub;
    _hub = null;
    if (hub == null) return;
    try {
      await hub.stop();
    } catch (e) {
      loggerWarn('Realtime stop failed: $e');
    }
  }
}
