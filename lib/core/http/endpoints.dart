abstract interface class Endpoints {
  static const String baseUrl = 'https://lavanderia.runasp.net/';
  static const String updateLocation = '';

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

  /// اند بوينتس مفتوحة بتتنادى قبل ما يبقى فيه جلسة، فمابنحطش عليها توكن
  /// والـ 401 منها معناه بيانات غلط مش جلسة منتهية
  static bool isPublicAuth(String path) {
    return path.contains(login) ||
        path.contains(verifyPhone) ||
        path.contains(register) ||
        path.contains(cities);
  }
}
