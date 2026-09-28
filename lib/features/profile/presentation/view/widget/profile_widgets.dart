import 'dart:io';

import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:lavanderia_delivery/core/style/app_colors.dart';
import 'package:lavanderia_delivery/core/theme/text_styles.dart';
import 'package:lavanderia_delivery/features/home/presentation/view/widget/home_colors.dart';
import 'package:lavanderia_delivery/features/home/presentation/view/widget/home_widgets.dart';

/// الهيدر الأزرق: صورة المندوب + الاسم + الرقم + بادج الحساب الموثّق
class ProfileHeader extends StatelessWidget {
  final String name;
  final String phone;
  final File? image;
  final bool isVerified;

  const ProfileHeader({
    super.key,
    required this.name,
    required this.phone,
    this.image,
    this.isVerified = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [HomeColors.headerStart, HomeColors.headerEnd],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32.r)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 28.h),
          child: Column(
            children: [
              Container(
                width: 80.r,
                height: 80.r,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.whiteColor.withValues(alpha: 0.2),
                  border: Border.all(
                    color: AppColors.whiteColor.withValues(alpha: 0.5),
                    width: 2,
                  ),
                ),
                alignment: Alignment.center,
                child: image != null
                    ? Image.file(
                        image!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      )
                    : Text('👤', style: TextStyle(fontSize: 38.sp)),
              ),
              Gap(12.h),
              Text(
                name,
                textAlign: TextAlign.center,
                style: TextStyles.boldStyle(20, color: AppColors.whiteColor),
              ),
              Gap(4.h),
              Text(
                phone,
                textDirection: TextDirection.ltr,
                style: TextStyles.boldStyle(
                  14,
                  color: AppColors.whiteColor.withValues(alpha: 0.85),
                  weight: FontWeight.w400,
                ),
              ),
              if (isVerified) ...[Gap(12.h), const _VerifiedBadge()],
            ],
          ),
        ),
      ),
    );
  }
}

class _VerifiedBadge extends StatelessWidget {
  const _VerifiedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: HomeColors.lightGreen,
        borderRadius: BorderRadius.circular(50.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7.r,
            height: 7.r,
            decoration: const BoxDecoration(
              color: HomeColors.green,
              shape: BoxShape.circle,
            ),
          ),
          Gap(6.w),
          Text(
            'verified_account'.tr(),
            style: TextStyles.boldStyle(12, color: HomeColors.green),
          ),
        ],
      ),
    );
  }
}

/// كارت المركبة: أيقونة العربية + الموديل + اللوحة واللون
class VehicleCard extends StatelessWidget {
  final String model;
  final String plateNumber;
  final String color;

  const VehicleCard({
    super.key,
    required this.model,
    required this.plateNumber,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return HomeCard(
      padding: EdgeInsets.all(16.r),
      child: Row(
        children: [
          Container(
            width: 52.r,
            height: 52.r,
            decoration: BoxDecoration(
              color: HomeColors.lightBlue,
              borderRadius: BorderRadius.circular(14.r),
            ),
            alignment: Alignment.center,
            child: Text('🚗', style: TextStyle(fontSize: 26.sp)),
          ),
          Gap(14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  model,
                  style: TextStyles.boldStyle(16, color: AppColors.blackColor),
                ),
                Gap(4.h),
                Text(
                  '$plateNumber • $color',
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

class ProfileMenuItem {
  final String emoji;
  final String titleKey;
  final VoidCallback? onTap;

  const ProfileMenuItem({
    required this.emoji,
    required this.titleKey,
    this.onTap,
  });
}

/// كارت واحد فيه كل سطور القايمة وبينهم خط فاصل
class ProfileMenuCard extends StatelessWidget {
  final List<ProfileMenuItem> items;

  const ProfileMenuCard({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return HomeCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            if (i > 0)
              Divider(height: 1, thickness: 1, color: AppColors.semiWhiteColor),
            _ProfileMenuTile(
              item: items[i],
              isFirst: i == 0,
              isLast: i == items.length - 1,
            ),
          ],
        ],
      ),
    );
  }
}

class _ProfileMenuTile extends StatelessWidget {
  final ProfileMenuItem item;
  final bool isFirst;
  final bool isLast;

  const _ProfileMenuTile({
    required this.item,
    required this.isFirst,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    // الريبل بياخد نفس انحناء الكارت في أول وآخر سطر
    final radius = BorderRadius.vertical(
      top: isFirst ? Radius.circular(22.r) : Radius.zero,
      bottom: isLast ? Radius.circular(22.r) : Radius.zero,
    );
    return InkWell(
      borderRadius: radius,
      onTap: item.onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 18.h),
        child: Row(
          children: [
            Text(item.emoji, style: TextStyle(fontSize: 20.sp)),
            Gap(12.w),
            Expanded(
              child: Text(
                item.titleKey.tr(),
                style: TextStyles.boldStyle(
                  15,
                  color: AppColors.blackColor,
                  weight: FontWeight.w500,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14.sp,
              color: AppColors.greyColor4,
            ),
          ],
        ),
      ),
    );
  }
}

/// زرار تسجيل الخروج، أحمر باهت عشان يبان إنه إجراء مختلف عن باقي القايمة
class ProfileLogoutButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onTap;

  const ProfileLogoutButton({
    super.key,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(18.r);
    return Material(
      color: HomeColors.red.withValues(alpha: 0.08),
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        // بنقفل الزرار وقت الطلب عشان مايتبعتش مرتين
        onTap: isLoading ? null : onTap,
        child: SizedBox(
          height: 56.h,
          child: Center(
            child: isLoading
                ? SizedBox(
                    width: 22.r,
                    height: 22.r,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: HomeColors.red,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.logout_rounded,
                        size: 20.sp,
                        color: HomeColors.red,
                      ),
                      Gap(8.w),
                      Text(
                        'logout'.tr(),
                        style: TextStyles.boldStyle(16, color: HomeColors.red),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
