import 'package:lavanderia_delivery/core/cache_manager/cache_manager.dart';
import 'package:lavanderia_delivery/core/realtime/driver_location_reporter.dart';
import 'package:lavanderia_delivery/core/realtime/realtime_service.dart';
import 'package:lavanderia_delivery/core/service_locator/service_locator.dart';

/// مكان واحد لكل حاجة تخص جلسة المستخدم: مسح بياناته عند الخروج
/// أو انتهاء الجلسة، ومنع التحويل للوجين أكتر من مرة.
abstract final class Session {
  static bool _expiryHandled = false;

  /// بتمسح التوكنز وبيانات المستخدم والسلة، عشان اللي يدخل بعده
  /// مايلاقيش حاجة من الحساب القديم
  static Future<void> clear() async {
    await CacheManager.clearTokens();
    await CacheManager.clearUserData();
    // سواء خروج أو الجلسة انتهت من الانترسبتور، مابقاش فيه مندوب نستقبل
    // أحداثه أو نبعت موقعه
    if (getIt.isRegistered<DriverLocationReporter>()) {
      await getIt<DriverLocationReporter>().stop();
    }
    if (getIt.isRegistered<RealtimeService>()) {
      await getIt<RealtimeService>().stop();
    }
  }

  /// لما كذا ريكوست يقعوا بـ 401 مع بعض، أول واحد بس هو اللي
  /// بيرجع true وبيحوّل المستخدم للوجين، والباقي بيتجاهلوا
  static bool claimExpiryRedirect() {
    if (_expiryHandled) return false;
    _expiryHandled = true;
    return true;
  }

  /// بتتنادى بعد لوجين ناجح عشان لو الجلسة الجديدة انتهت نحوّل تاني
  static void started() => _expiryHandled = false;
}
