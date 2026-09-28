import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:lavanderia_delivery/core/style/app_colors.dart';
import 'package:lavanderia_delivery/core/theme/text_styles.dart';
import 'package:lavanderia_delivery/features/home/models/delivery_order_model.dart';
import 'package:lavanderia_delivery/features/home/presentation/view/widget/home_colors.dart';

/// بيرجع true لو السواق قبل الطلب، false لو رفضه أو الوقت خلص، null لو قفل الشيت
Future<bool?> showNewOrderBottomSheet(
  BuildContext context,
  DeliveryOrderModel order,
) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.whiteColor,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
    ),
    builder: (_) => NewOrderBottomSheet(order: order),
  );
}

class NewOrderBottomSheet extends StatefulWidget {
  final DeliveryOrderModel order;
  final Duration responseTime;

  const NewOrderBottomSheet({
    super.key,
    required this.order,
    this.responseTime = const Duration(seconds: 60),
  });

  @override
  State<NewOrderBottomSheet> createState() => _NewOrderBottomSheetState();
}

class _NewOrderBottomSheetState extends State<NewOrderBottomSheet> {
  Timer? _timer;
  late int _remainingSeconds = widget.responseTime.inSeconds;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remainingSeconds <= 1) {
        _timer?.cancel();
        // الوقت خلص = رفض تلقائي
        if (mounted) Navigator.of(context).pop(false);
        return;
      }
      setState(() => _remainingSeconds--);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _formattedTime {
    final minutes = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16.w, 24.h, 16.w, 16.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            Gap(18.h),
            ClipRRect(
              borderRadius: BorderRadius.circular(8.r),
              child: LinearProgressIndicator(
                value: _remainingSeconds / widget.responseTime.inSeconds,
                minHeight: 6.h,
                color: AppColors.primaryColor,
                backgroundColor: HomeColors.cardGrey,
              ),
            ),
            Gap(16.h),
            _buildTaskCard(order),
            Gap(12.h),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _PointCard(
                      emoji: '📍',
                      titleKey: 'pickup_point',
                      name: order.pickupName,
                      address: order.pickupAddress,
                      accentColor: HomeColors.green,
                      backgroundColor: HomeColors.lightGreen,
                    ),
                  ),
                  Gap(10.w),
                  Expanded(
                    child: _PointCard(
                      emoji: '🏠',
                      titleKey: 'dropoff_point',
                      name: order.dropoffName,
                      address: order.dropoffAddress,
                      accentColor: HomeColors.orange,
                      backgroundColor: HomeColors.lightOrange,
                    ),
                  ),
                ],
              ),
            ),
            Gap(12.h),
            OrderMetricsRow(order: order),
            Gap(20.h),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: HomeColors.lightBlue,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Text(
            '🔔 ${'new_delivery_order'.tr()}',
            style: TextStyles.boldStyle(13, color: AppColors.primaryColor),
          ),
        ),
        const Spacer(),
        Text(_formattedTime, style: TextStyles.boldStyle(22)),
      ],
    );
  }

  Widget _buildTaskCard(DeliveryOrderModel order) {
    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: HomeColors.cardGrey,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📦 ${'task_type'.tr()}',
            style: TextStyles.boldStyle(12, color: AppColors.primaryColor),
          ),
          Gap(8.h),
          Text(order.taskType, style: TextStyles.boldStyle(15)),
          Gap(4.h),
          Text(
            '${'order_number'.tr()} #${order.id}',
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

  Widget _buildActions() {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: SizedBox(
            height: 54.h,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: HomeColors.green,
                foregroundColor: AppColors.whiteColor,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                ),
              ),
              child: Text(
                '${'accept_order'.tr()} ✓',
                style: TextStyles.boldStyle(16, color: AppColors.whiteColor),
              ),
            ),
          ),
        ),
        Gap(10.w),
        Expanded(
          child: SizedBox(
            height: 54.h,
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: OutlinedButton.styleFrom(
                foregroundColor: HomeColors.red,
                side: BorderSide(color: HomeColors.red, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                ),
              ),
              child: Text(
                'reject'.tr(),
                style: TextStyles.boldStyle(16, color: HomeColors.red),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PointCard extends StatelessWidget {
  final String emoji;
  final String titleKey;
  final String name;
  final String address;
  final Color accentColor;
  final Color backgroundColor;

  const _PointCard({
    required this.emoji,
    required this.titleKey,
    required this.name,
    required this.address,
    required this.accentColor,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$emoji ${titleKey.tr()}',
            style: TextStyles.boldStyle(12, color: accentColor),
          ),
          Gap(8.h),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyles.boldStyle(15),
          ),
          Gap(4.h),
          Text(
            address,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
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

/// المسافة والوقت والسعر، مستخدمة في الشيت وفي كارت الطلب في الليست
class OrderMetricsRow extends StatelessWidget {
  final DeliveryOrderModel order;
  final bool compact;

  const OrderMetricsRow({super.key, required this.order, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final items = [
      ('📏', '${formatOrderNumber(order.distanceKm)} ${'km'.tr()}'),
      ('⏱', '${order.durationMinutes} ${'minute'.tr()}'),
      ('💰', '${formatOrderNumber(order.price)} ${'currency'.tr()}'),
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

/// بيشيل الـ .0 من الأرقام الصحيحة (75.0 -> 75)
String formatOrderNumber(num value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toString();
