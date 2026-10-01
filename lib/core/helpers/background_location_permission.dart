import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lavanderia_delivery/core/style/app_colors.dart';
import 'package:lavanderia_delivery/core/theme/text_styles.dart';
import 'package:permission_handler/permission_handler.dart';

/// Android: عشان إرسال الموقع يكمل في الخلفية ويرجع لوحده بعد ريستارت
/// الموبايل، محتاجين صلاحية الموقع "طول الوقت"، ونشيل توفير البطارية عن
/// التطبيق عشان أجهزة زي Xiaomi وSamsung ماتقفلش الخدمة.
///
/// جوجل بتطلب نوضّح للمستخدم ليه قبل ما نطلب صلاحية الموقع في الخلفية،
/// فبيظهر dialog الأول. iOS مش محتاج حاجة من دول، الإرسال في الخلفية
/// شغال بصلاحية "أثناء الاستخدام"
abstract final class BackgroundLocationPermission {
  /// بنسأل مرة واحدة بس في كل فتحة للتطبيق، عشان مانزهقش المندوب
  static bool _askedThisSession = false;

  /// true لو الاتنين متاخدين (أو مش Android)
  static Future<bool> isGranted() async {
    if (!Platform.isAndroid) return true;
    return await Permission.locationAlways.isGranted &&
        await Permission.ignoreBatteryOptimizations.isGranted;
  }

  /// بتتنادى لما المندوب يفتح التوفر. [force] بيتجاهل إننا سألنا قبل كده
  static Future<void> request(BuildContext context, {bool force = false}) async {
    if (!Platform.isAndroid) return;
    if (_askedThisSession && !force) return;
    _askedThisSession = true;

    // "طول الوقت" مابتتطلبش غير بعد "أثناء الاستخدام"
    var whileInUse = await Permission.locationWhenInUse.status;
    if (!whileInUse.isGranted) {
      whileInUse = await Permission.locationWhenInUse.request();
      if (!whileInUse.isGranted) return;
    }

    final needsAlways = !await Permission.locationAlways.isGranted;
    final needsBattery = !await Permission.ignoreBatteryOptimizations.isGranted;
    if (!needsAlways && !needsBattery) return;
    if (!context.mounted) return;

    final accepted = await _explain(context);
    if (accepted != true) return;

    // Android 11+ بيفتح صفحة الإعدادات والمندوب بيختار "السماح طول الوقت"
    if (needsAlways) await Permission.locationAlways.request();
    if (needsBattery) await Permission.ignoreBatteryOptimizations.request();
  }

  static Future<bool?> _explain(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.whiteColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Text(
          'background_location_title'.tr(),
          style: TextStyles.boldStyle(17),
        ),
        content: Text(
          'background_location_body'.tr(),
          style: TextStyles.boldStyle(
            14,
            color: AppColors.greyColor,
            weight: FontWeight.w400,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              'not_now'.tr(),
              style: TextStyles.boldStyle(14, color: AppColors.greyColor),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              'allow'.tr(),
              style: TextStyles.boldStyle(14, color: AppColors.primaryColor),
            ),
          ),
        ],
      ),
    );
  }
}
