import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:lavanderia_delivery/core/style/app_colors.dart';
import 'package:lavanderia_delivery/core/theme/text_styles.dart';
import 'package:lavanderia_delivery/features/home/models/delivery_order_model.dart';
import 'package:lavanderia_delivery/features/home/presentation/view/widget/home_colors.dart';
import 'package:lavanderia_delivery/features/home/presentation/view/widget/new_order_bottom_sheet.dart';

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

/// كارت الطلب في ليست الطلبات الجديدة، الضغط عليه بيفتح نفس شيت الطلب الجديد
class PendingOrderCard extends StatelessWidget {
  final DeliveryOrderModel order;
  final VoidCallback onTap;

  const PendingOrderCard({super.key, required this.order, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return HomeCard(
      onTap: onTap,
      padding: EdgeInsets.all(14.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '📦 ${order.taskType}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyles.boldStyle(14, color: AppColors.blackColor),
                ),
              ),
              Gap(8.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: HomeColors.lightBlue,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  '#${order.id}',
                  style: TextStyles.boldStyle(
                    11,
                    color: AppColors.primaryColor,
                  ),
                ),
              ),
            ],
          ),
          Gap(12.h),
          _RoutePoint(
            emoji: '📍',
            name: order.pickupName,
            address: order.pickupAddress,
            color: HomeColors.green,
          ),
          Padding(
            padding: EdgeInsetsDirectional.only(start: 9.w),
            child: SizedBox(
              height: 14.h,
              child: VerticalDivider(
                width: 1,
                thickness: 1.5,
                color: AppColors.semiWhiteColor2,
              ),
            ),
          ),
          _RoutePoint(
            emoji: '🏠',
            name: order.dropoffName,
            address: order.dropoffAddress,
            color: HomeColors.orange,
          ),
          Gap(12.h),
          OrderMetricsRow(order: order, compact: true),
        ],
      ),
    );
  }
}

class _RoutePoint extends StatelessWidget {
  final String emoji;
  final String name;
  final String address;
  final Color color;

  const _RoutePoint({
    required this.emoji,
    required this.name,
    required this.address,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(emoji, style: TextStyle(fontSize: 14.sp)),
        Gap(8.w),
        Text(name, style: TextStyles.boldStyle(13, color: color)),
        Gap(6.w),
        Expanded(
          child: Text(
            address,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyles.boldStyle(
              12,
              color: AppColors.greyColor,
              weight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }
}

class SimulateOrderButton extends StatelessWidget {
  final VoidCallback onPressed;

  const SimulateOrderButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(18.r);
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
          onTap: onPressed,
          child: SizedBox(
            height: 56.h,
            child: Center(
              child: Text(
                '🔔 ${'simulate_new_order'.tr()}',
                style: TextStyles.boldStyle(16, color: AppColors.whiteColor),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
