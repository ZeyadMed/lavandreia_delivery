abstract interface class Endpoints {
  static const String baseUrl = 'https://lavanderia.runasp.net/';

  // ****************************** Auth ********************************
  static const String register = '/api/auth/driver/register';

  /// تفعيل رقم المندوب بعد التسجيل، بتاخد { phoneNumber, code }
  static const String verifyPhone = 'api/auth/driver/verify-phone';

  /// المدن اللي بتتعرض في الدروب داون بتاعة التسجيل،
  /// بترجع list فيها { id, name } والـ id هو اللي بيتبعت في cityId
  static const String cities = 'api/auth/cities';
  static const String verifyOtp = '/api/auth/driver/verify-phone';
  static const String login = '/api/auth/driver/login';
  static const String forgetPassword = 'forgot/password';
  static const String resetPasssword = 'forgot/reset-password';
  static const String confirmPassword = '';
  static const String resentOtp = 'resend-otp';
  static const String forgetResendOtp = 'forgot/resend-otp';
  static const String forgetVerifyOtp = 'forgot/verify-otp';
  static const String logOut = 'logout';

  /// بناخد منها accessToken جديد لما القديم يقع بـ 401.
  /// بتستقبل { refreshToken, deviceInfo, deviceId } وبترجع الاتنين جداد جوه data.
  static const String refreshToken = 'api/auth/refresh-token';

  /// بتاخد { refreshToken } وبتلغي الجلسة من عند الباك
  static const String logout = 'api/auth/logout';

  // ****************************** Profile ********************************
  /// GET بيرجع بيانات المندوب، و PUT بيعدلها (الاسم والعنوان والمدينة والمركبة)
  static const String driverProfile = 'api/driver/profile';

  /// بيرجع { phoneNumber1, phoneNumber2, email } لشاشة تواصل معنا
  static const String contacts = 'api/auth/contacts';

  /// بيرجع { content, updatedAt } والـ content عبارة عن HTML
  static const String privacyPolicy = 'api/auth/privacy-policy';

  // ****************************** Notifications ********************************
  /// GET بيرجع إشعارات المندوب بالصفحات (PageIndex, PageSize)، و DELETE بيمسحهم كلهم
  static const String driverNotifications = 'api/driver/notifications';

  /// PUT بيعلّم كل الإشعارات كمقروءة
  static const String readAllNotifications = 'api/driver/notifications/read-all';

  /// DELETE بيمسح إشعار واحد
  static String notification(int id) => 'api/driver/notifications/$id';

  /// PUT بيعلّم إشعار واحد كمقروء
  static String readNotification(int id) => 'api/driver/notifications/$id/read';

  // ****************************** Trips ********************************
  /// GET الرحلات اللي لسه من غير سواق حوالين المندوب
  /// (type = Pickup | Dropoff, lat, lng, radiusKm, PageIndex, PageSize)
  static const String availableTrips = 'api/driver/trips/available';

  /// POST بيطلب الرحلة بـ { latitude, longitude, radiusKm }، والمغسلة هي اللي بتوافق
  static String requestTrip(int tripId) => 'api/driver/trips/$tripId/request';

  /// GET طلبات المندوب على الرحلات وحالتها (PageIndex, PageSize)
  static const String tripRequests = 'api/driver/trips/requests';

  /// GET الرحلات اللي اتعيّن عليها المندوب، الشغالة والمنتهية (PageIndex, PageSize)
  static const String driverTrips = 'api/driver/trips';

  /// POST multipart بصور الهدوم (photos) وقت الاستلام من العميل، وبيرجع OTP للمغسلة
  static String collectTrip(int tripId) => 'api/driver/trips/$tripId/collect';

  /// POST لما المندوب يوصل باب العميل في رحلة التسليم، وبيرجع OTP للعميل
  static String arriveTrip(int tripId) => 'api/driver/trips/$tripId/arrive';

  /// PUT بـ { isAvailable } بيفتح أو يقفل استقبال الرحلات
  static const String driverAvailability = 'api/driver/availability';

  // ****************************** Wallet ********************************
  /// GET رصيد محفظة المندوب
  static const String driverWallet = 'api/driver/wallet';

  /// GET حركات المحفظة بالصفحات (PageIndex, PageSize)
  static const String walletTransactions = 'api/driver/wallet/transactions';

  // ****************************** Realtime ********************************
  // TODO: اسم الـ hub لسه ماوصلناش من الباك، كل المسارات اللي جربناها بترجع 401
  static const String realtimeHub = 'hubs/notifications';

  /// اند بوينتس مفتوحة بتتنادى قبل ما يبقى فيه جلسة، فمابنحطش عليها توكن
  /// والـ 401 منها معناه بيانات غلط مش جلسة منتهية
  static bool isPublicAuth(String path) {
    return path.contains(login) ||
        path.contains(verifyPhone) ||
        path.contains(register) ||
        path.contains(cities);
  }
}
