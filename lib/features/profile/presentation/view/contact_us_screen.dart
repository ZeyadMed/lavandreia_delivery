import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:lavanderia_delivery/core/common_widget/custom_app_bar.dart';
import 'package:lavanderia_delivery/core/common_widget/custom_error_message.dart';
import 'package:lavanderia_delivery/core/style/app_colors.dart';
import 'package:lavanderia_delivery/core/theme/text_styles.dart';
import 'package:lavanderia_delivery/features/home/presentation/view/widget/home_colors.dart';
import 'package:lavanderia_delivery/features/home/presentation/view/widget/home_widgets.dart';
import 'package:url_launcher/url_launcher.dart';

/// شاشة تواصل معنا: كل طريقة تواصل بتفتح التطبيق بتاعها
class ContactUsScreen extends StatelessWidget {
  const ContactUsScreen({super.key});

  // TODO: الأرقام والإيميل ثابتة لحد ما ييجوا من إعدادات السيرفر
  static const String _phone = '+218911234567';
  static const String _whatsapp = '+218911234567';
  static const String _email = 'support@lavanderia.ly';

  /// بيفتح اللينك، ولو الجهاز مش عارف يفتحه بنعرض رسالة بدل ما الدوسة تضيع
  Future<void> _launch(BuildContext context, Uri uri) async {
    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    ).catchError((_) => false);

    if (!launched && context.mounted) {
      CustomErrorOverlay.show(context: context, text: 'contact_failed'.tr());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: const CustomAppBar(
        title: 'contact_us',
        backgroundColor: AppColors.backgroundColor,
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h),
        children: [
          const _ContactHeaderCard(),
          Gap(16.h),
          _ContactChannelCard(
            emoji: '📞',
            color: HomeColors.lightBlue,
            titleKey: 'contact_phone',
            value: _phone,
            onTap: () => _launch(context, Uri.parse('tel:$_phone')),
          ),
          Gap(12.h),
          _ContactChannelCard(
            emoji: '💬',
            color: HomeColors.lightGreen,
            titleKey: 'contact_whatsapp',
            value: _whatsapp,
            onTap: () => _launch(
              context,
              Uri.parse('https://wa.me/${_whatsapp.replaceAll('+', '')}'),
            ),
          ),
          Gap(12.h),
          _ContactChannelCard(
            emoji: '✉️',
            color: HomeColors.lightOrange,
            titleKey: 'contact_email',
            value: _email,
            onTap: () => _launch(context, Uri.parse('mailto:$_email')),
          ),
          Gap(16.h),
          const _WorkingHoursCard(),
        ],
      ),
    );
  }
}

class _ContactHeaderCard extends StatelessWidget {
  const _ContactHeaderCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(18.r),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [HomeColors.headerStart, HomeColors.headerEnd],
        ),
        borderRadius: BorderRadius.circular(22.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44.r,
                height: 44.r,
                decoration: BoxDecoration(
                  color: AppColors.whiteColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                alignment: Alignment.center,
                child: Text('🎧', style: TextStyle(fontSize: 22.sp)),
              ),
              Gap(12.w),
              Expanded(
                child: Text(
                  'contact_header_title'.tr(),
                  style: TextStyles.boldStyle(17, color: AppColors.whiteColor),
                ),
              ),
            ],
          ),
          Gap(12.h),
          Text(
            'driver_contact_header_body'.tr(),
            style: TextStyles.boldStyle(
              13,
              color: AppColors.whiteColor.withValues(alpha: 0.9),
              weight: FontWeight.w400,
            ).copyWith(height: 1.7),
          ),
        ],
      ),
    );
  }
}

/// سطر طريقة تواصل: أيقونة + الاسم وتحته القيمة
class _ContactChannelCard extends StatelessWidget {
  final String emoji;
  final Color color;
  final String titleKey;
  final String value;
  final VoidCallback onTap;

  const _ContactChannelCard({
    required this.emoji,
    required this.color,
    required this.titleKey,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return HomeCard(
      onTap: onTap,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      child: Row(
        children: [
          Container(
            width: 44.r,
            height: 44.r,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12.r),
            ),
            alignment: Alignment.center,
            child: Text(emoji, style: TextStyle(fontSize: 20.sp)),
          ),
          Gap(14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titleKey.tr(),
                  style: TextStyles.boldStyle(15, color: AppColors.blackColor),
                ),
                Gap(3.h),
                // الرقم والإيميل دايماً بيتعرضوا من الشمال لليمين
                Text(
                  value,
                  textDirection: TextDirection.ltr,
                  style: TextStyles.boldStyle(
                    13,
                    color: AppColors.greyColor,
                    weight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios_rounded,
            size: 14.sp,
            color: AppColors.greyColor4,
          ),
        ],
      ),
    );
  }
}

class _WorkingHoursCard extends StatelessWidget {
  const _WorkingHoursCard();

  @override
  Widget build(BuildContext context) {
    return HomeCard(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      child: Row(
        children: [
          Text('🕘', style: TextStyle(fontSize: 20.sp)),
          Gap(12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'working_hours'.tr(),
                  style: TextStyles.boldStyle(15, color: AppColors.blackColor),
                ),
                Gap(3.h),
                Text(
                  'working_hours_value'.tr(),
                  style: TextStyles.boldStyle(
                    13,
                    color: AppColors.greyColor,
                    weight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
