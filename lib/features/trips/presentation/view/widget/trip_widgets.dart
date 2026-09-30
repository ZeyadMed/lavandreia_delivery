import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:lavanderia_delivery/core/style/app_colors.dart';
import 'package:lavanderia_delivery/core/theme/text_styles.dart';
import 'package:lavanderia_delivery/features/home/presentation/view/widget/home_colors.dart';
import 'package:lavanderia_delivery/features/home/presentation/view/widget/home_widgets.dart';
import 'package:lavanderia_delivery/features/trips/models/delivery_trip_model.dart';

/// بيشيل الـ .0 من الأرقام الصحيحة (75.0 -> 75)
String formatAmount(num value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toStringAsFixed(2);

extension TripTypeView on TripType {
  String get labelKey => switch (this) {
    TripType.pickup => 'pickup_trip',
    TripType.dropoff => 'dropoff_trip',
  };

  String get emoji => switch (this) {
    TripType.pickup => '🧺',
    TripType.dropoff => '🚚',
  };
}

extension TripPointView on DeliveryTripModel {
  /// الاسم ممكن مايرجعش في الرحلات المتاحة، فبنعرض "العميل" أو "المغسلة"
  String get fromName => _nameOr(from, type == TripType.pickup);

  String get toName => _nameOr(to, type == TripType.dropoff);

  String _nameOr(TripPoint point, bool isCustomer) => point.name.isNotEmpty
      ? point.name
      : (isCustomer ? 'customer' : 'laundry').tr();

  /// رقم الطلب لو موجود، ولو لأ رقم الرحلة
  String get displayNumber => '#${orderId ?? id}';
}

/// تابات الاستلام والتسليم فوق ليستة الرحلات المتاحة
class TripTypeTabs extends StatelessWidget {
  final TripType selected;
  final ValueChanged<TripType> onChanged;

  const TripTypeTabs({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4.r),
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Row(
        children: [
          for (final type in TripType.values)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onChanged(type),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.symmetric(vertical: 10.h),
                  decoration: BoxDecoration(
                    color: type == selected
                        ? AppColors.primaryColor
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    '${type.emoji} ${type.labelKey.tr()}',
                    textAlign: TextAlign.center,
                    style: TextStyles.boldStyle(
                      13,
                      color: type == selected
                          ? AppColors.whiteColor
                          : AppColors.blackColor,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// كارت الرحلة المتاحة، الضغط عليه بيفتح شيت التفاصيل وطلب الرحلة
class AvailableTripCard extends StatelessWidget {
  final DeliveryTripModel trip;
  final VoidCallback onTap;

  const AvailableTripCard({super.key, required this.trip, required this.onTap});

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
                  '${trip.type.emoji} ${trip.type.labelKey.tr()}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyles.boldStyle(14, color: AppColors.blackColor),
                ),
              ),
              Gap(8.w),
              TripNumberChip(text: trip.displayNumber),
            ],
          ),
          Gap(12.h),
          TripRoutePoint(
            emoji: '📍',
            name: trip.fromName,
            address: trip.from.address,
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
          TripRoutePoint(
            emoji: '🏁',
            name: trip.toName,
            address: trip.to.address,
            color: HomeColors.orange,
          ),
          Gap(12.h),
          TripMetricsRow(trip: trip, compact: true),
          if (trip.isRequestedByMe) ...[
            Gap(10.h),
            const AwaitingApprovalBadge(),
          ],
        ],
      ),
    );
  }
}

class TripNumberChip extends StatelessWidget {
  final String text;

  const TripNumberChip({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: HomeColors.lightBlue,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Text(
        text,
        textDirection: TextDirection.ltr,
        style: TextStyles.boldStyle(11, color: AppColors.primaryColor),
      ),
    );
  }
}

/// بيظهر على الرحلة اللي طلبناها لحد ما المغسلة تختار مندوب
class AwaitingApprovalBadge extends StatelessWidget {
  const AwaitingApprovalBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: HomeColors.lightOrange,
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Text(
        '⏳ ${'awaiting_laundry_approval'.tr()}',
        style: TextStyles.boldStyle(12, color: HomeColors.orange),
      ),
    );
  }
}

class TripRoutePoint extends StatelessWidget {
  final String emoji;
  final String name;
  final String address;
  final Color color;

  const TripRoutePoint({
    super.key,
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

/// المسافة والرسوم، مستخدمة في الشيت وفي كارت الرحلة في الليست
class TripMetricsRow extends StatelessWidget {
  final DeliveryTripModel trip;
  final bool compact;

  const TripMetricsRow({super.key, required this.trip, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final distance = trip.distanceKm;
    final items = [
      if (distance != null) ('📏', '${formatAmount(distance)} ${'km'.tr()}'),
      ('💰', '${formatAmount(trip.fee)} ${'currency'.tr()}'),
      if (trip.itemsCount != null)
        ('👕', '${trip.itemsCount} ${'piece_unit'.tr()}'),
    ];

    return Container(
      padding: EdgeInsets.symmetric(vertical: compact ? 10.h : 14.h),
      decoration: BoxDecoration(
        color: HomeColors.cardGrey,
        borderRadius: BorderRadius.circular(compact ? 12.r : 16.r),
      ),
      child: Row(
        children: items
            .map(
              (item) => Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.$1,
                      style: TextStyle(fontSize: compact ? 14.sp : 18.sp),
                    ),
                    Gap(compact ? 2.h : 6.h),
                    Text(
                      item.$2,
                      style: TextStyles.boldStyle(compact ? 12 : 14),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
