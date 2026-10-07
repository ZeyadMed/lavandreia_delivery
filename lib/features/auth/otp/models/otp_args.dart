/// شاشة الـ OTP مشتركة بين فلوين، والـ purpose هو اللي بيحدد
/// بعد النجاح بنروح فين
enum OtpPurpose {
  /// بعد إنشاء حساب: بنفعل الرقم ونوديه شاشة الحساب تحت المراجعة
  register,

  /// اللوجين رجع 409 لأن الرقم مش متفعل: بنفعله ونرجعه يسجل دخول تاني
  login,
}

/// بيتبعت في state.extra لشاشة الـ OTP
class OtpArgs {
  final String phoneNumber;
  final OtpPurpose purpose;

  const OtpArgs({required this.phoneNumber, required this.purpose});
}
