import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:lavanderia_delivery/core/style/app_colors.dart';
import 'package:lavanderia_delivery/core/theme/text_styles.dart';
import 'package:lavanderia_delivery/features/home/presentation/view/widget/home_colors.dart';
import 'package:lavanderia_delivery/features/trips/models/delivery_trip_model.dart';
import 'package:lavanderia_delivery/features/trips/presentation/view/widget/trip_widgets.dart';

/// الكارت الأبيض الأساسي اللي كل أقسام الرئيسية مبنية عليه
class HomeCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  const HomeCard({super.key, required this.child, this.padding, this.onTap});

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(22.r);
    return Material(
      color: AppColors.whiteColor,
      borderRadius: radius,
      shadowColor: Colors.black12,
      elevation: 1,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Padding(padding: padding ?? EdgeInsets.all(18.r), child: child),
      ),
    );
  }
}

class AvailabilityCard extends StatelessWidget {
  final bool isAvailable;
  final ValueChanged<bool> onChanged;

  const AvailabilityCard({
    super.key,
    required this.isAvailable,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = isAvailable ? HomeColors.green : AppColors.greyColor;

    return HomeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'availability_status'.tr(),
                      style: TextStyles.boldStyle(
                        17,
                        color: AppColors.blackColor,
                      ),
                    ),
                    Gap(6.h),
                    Row(
                      children: [
                        Container(
                          width: 12.r,
                          height: 12.r,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        Gap(6.w),
                        Text(
                          (isAvailable
                                  ? 'available_for_orders'
                                  : 'unavailable_for_orders')
                              .tr(),
                          style: TextStyles.boldStyle(13, color: statusColor),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Transform.scale(
                scale: 1.1,
                child: Switch(
                  value: isAvailable,
                  onChanged: onChanged,
                  activeThumbColor: AppColors.whiteColor,
                  activeTrackColor: HomeColors.green,
                  inactiveThumbColor: AppColors.whiteColor,
                  inactiveTrackColor: AppColors.semiWhiteColor2,
                  trackOutlineColor: const WidgetStatePropertyAll(
                    Colors.transparent,
                  ),
                ),
              ),
            ],
          ),
          Gap(16.h),
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
            decoration: BoxDecoration(
              color: isAvailable ? HomeColors.lightGreen : HomeColors.cardGrey,
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: Text(
              (isAvailable ? 'available_hint' : 'unavailable_hint').tr(),
              style: TextStyles.boldStyle(13, color: statusColor),
            ),
          ),
        ],
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  final String emoji;
  final String value;
  final String labelKey;

  const StatCard({
    super.key,
    required this.emoji,
    required this.value,
    required this.labelKey,
  });

  @override
  Widget build(BuildContext context) {
    return HomeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: TextStyle(fontSize: 22.sp)),
          Gap(14.h),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              value,
              style: TextStyles.boldStyle(20, color: AppColors.blackColor),
            ),
          ),
          Gap(4.h),
          Text(
            labelKey.tr(),
            style: TextStyles.boldStyle(
              12,
              color: AppColors.greyColor,
              weight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class HomeEmptyState extends StatelessWidget {
  final String emoji;
  final String titleKey;
  final String subtitleKey;

  const HomeEmptyState({
    super.key,
    required this.emoji,
    required this.titleKey,
    required this.subtitleKey,
  });

  @override
  Widget build(BuildContext context) {
    return HomeCard(
      padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 32.h),
      child: Column(
        children: [
          Text(emoji, style: TextStyle(fontSize: 48.sp)),
          Gap(16.h),
          Text(
            titleKey.tr(),
            textAlign: TextAlign.center,
            style: TextStyles.boldStyle(16),
          ),
          Gap(6.h),
          Text(
            subtitleKey.tr(),
            textAlign: TextAlign.center,
            style: TextStyles.boldStyle(
              13,
              color: AppColors.greyColor,
              weight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

/// الرحلة اللي متعيّنة علينا ولسه ماخلصتش، الضغط عليها بيفتح شاشة الرحلة
class ActiveTripBanner extends StatelessWidget {
  final DeliveryTripModel trip;
  final VoidCallback onTap;

  const ActiveTripBanner({super.key, required this.trip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(22.r);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: const LinearGradient(
          colors: [HomeColors.headerStart, HomeColors.headerEnd],
        ),
        boxShadow: [
          BoxShadow(
            color: HomeColors.headerEnd.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.all(16.r),
            child: Row(
              children: [
                Text(trip.type.emoji, style: TextStyle(fontSize: 28.sp)),
                Gap(12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'current_trip'.tr(),
                        style: TextStyles.boldStyle(
                          16,
                          color: AppColors.whiteColor,
                        ),
                      ),
                      Gap(4.h),
                      Text(
                        '${trip.type.labelKey.tr()} • ${trip.displayNumber}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyles.boldStyle(
                          12,
                          color: AppColors.whiteColor.withValues(alpha: 0.85),
                          weight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16.sp,
                  color: AppColors.whiteColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
