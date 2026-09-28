import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:lavanderia_delivery/core/common_widget/custom_app_bar.dart';
import 'package:lavanderia_delivery/core/style/app_colors.dart';
import 'package:lavanderia_delivery/core/theme/text_styles.dart';
import 'package:lavanderia_delivery/features/home/presentation/view/widget/home_colors.dart';
import 'package:lavanderia_delivery/features/home/presentation/view/widget/home_widgets.dart';

/// شاشة سياسة الخصوصية للمندوب: مقدمة فوق وتحتها كارت لكل بند
/// البنود جاية من ملفات الترجمة فبتتغير مع اللغة لوحدها
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const List<({String emoji, String titleKey, String bodyKey})>
  _sections = [
    (
      emoji: '📁',
      titleKey: 'privacy_data_title',
      bodyKey: 'driver_privacy_data_body',
    ),
    (
      emoji: '📍',
      titleKey: 'driver_privacy_location_title',
      bodyKey: 'driver_privacy_location_body',
    ),
    (
      emoji: '⚙️',
      titleKey: 'privacy_usage_title',
      bodyKey: 'driver_privacy_usage_body',
    ),
    (
      emoji: '🤝',
      titleKey: 'privacy_sharing_title',
      bodyKey: 'driver_privacy_sharing_body',
    ),
    (
      emoji: '🛡️',
      titleKey: 'privacy_security_title',
      bodyKey: 'privacy_security_body',
    ),
    (
      emoji: '✅',
      titleKey: 'privacy_rights_title',
      bodyKey: 'driver_privacy_rights_body',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: const CustomAppBar(
        title: 'privacy_policy',
        backgroundColor: AppColors.backgroundColor,
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h),
        children: [
          const _PrivacyIntro(),
          for (final section in _sections) ...[
            Gap(12.h),
            _PolicySectionCard(
              emoji: section.emoji,
              titleKey: section.titleKey,
              bodyKey: section.bodyKey,
            ),
          ],
        ],
      ),
    );
  }
}

/// كارت المقدمة بالأزرق الباهت عشان يفرق عن باقي البنود
class _PrivacyIntro extends StatelessWidget {
  const _PrivacyIntro();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(18.r),
      decoration: BoxDecoration(
        color: HomeColors.lightBlue,
        borderRadius: BorderRadius.circular(22.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'privacy_intro_title'.tr(),
            style: TextStyles.boldStyle(16, color: AppColors.primaryColor),
          ),
          Gap(8.h),
          Text(
            'driver_privacy_intro_body'.tr(),
            style: TextStyles.boldStyle(
              13,
              color: AppColors.greyColor,
              weight: FontWeight.w400,
            ).copyWith(height: 1.7),
          ),
        ],
      ),
    );
  }
}

class _PolicySectionCard extends StatelessWidget {
  final String emoji;
  final String titleKey;
  final String bodyKey;

  const _PolicySectionCard({
    required this.emoji,
    required this.titleKey,
    required this.bodyKey,
  });

  @override
  Widget build(BuildContext context) {
    return HomeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36.r,
                height: 36.r,
                decoration: BoxDecoration(
                  color: HomeColors.cardGrey,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                alignment: Alignment.center,
                child: Text(emoji, style: TextStyle(fontSize: 18.sp)),
              ),
              Gap(10.w),
              Expanded(
                child: Text(
                  titleKey.tr(),
                  style: TextStyles.boldStyle(15, color: AppColors.blackColor),
                ),
              ),
            ],
          ),
          Gap(12.h),
          Text(
            bodyKey.tr(),
            style: TextStyles.boldStyle(
              13,
              color: AppColors.greyColor,
              weight: FontWeight.w400,
            ).copyWith(height: 1.7),
          ),
        ],
      ),
    );
  }
}
