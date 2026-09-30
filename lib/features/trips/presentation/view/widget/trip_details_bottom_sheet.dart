import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:lavanderia_delivery/core/common_widget/custom_error_message.dart';
import 'package:lavanderia_delivery/core/style/app_colors.dart';
import 'package:lavanderia_delivery/core/theme/text_styles.dart';
import 'package:lavanderia_delivery/features/home/presentation/view/widget/home_colors.dart';
import 'package:lavanderia_delivery/features/trips/models/delivery_trip_model.dart';
import 'package:lavanderia_delivery/features/trips/presentation/view/widget/trip_widgets.dart';

/// بيرجع true لو الطلب اتبعت، null لو المندوب قفل الشيت.
/// [onRequest] بترجع رسالة الخطأ أو null لو الطلب اتبعت
Future<bool?> showTripDetailsBottomSheet(
  BuildContext context,
  DeliveryTripModel trip, {
  required Future<String?> Function() onRequest,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.whiteColor,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
    ),
    builder: (_) => TripDetailsBottomSheet(trip: trip, onRequest: onRequest),
  );
}

/// تفاصيل الرحلة المتاحة وزرار طلبها. الطلب مش قبول نهائي:
/// ممكن أكتر من مندوب يطلبوا نفس الرحلة والمغسلة هي اللي بتختار
class TripDetailsBottomSheet extends StatefulWidget {
  final DeliveryTripModel trip;
  final Future<String?> Function() onRequest;

  const TripDetailsBottomSheet({
    super.key,
    required this.trip,
    required this.onRequest,
  });

  @override
  State<TripDetailsBottomSheet> createState() => _TripDetailsBottomSheetState();
}

class _TripDetailsBottomSheetState extends State<TripDetailsBottomSheet> {
  bool _isRequesting = false;

  Future<void> _request() async {
    setState(() => _isRequesting = true);
    final error = await widget.onRequest();
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() => _isRequesting = false);
    CustomErrorOverlay.show(context: context, text: error);
  }

  @override
  Widget build(BuildContext context) {
    final trip = widget.trip;

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16.w, 24.h, 16.w, 16.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 8.h,
                  ),
                  decoration: BoxDecoration(
                    color: HomeColors.lightBlue,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    '${trip.type.emoji} ${trip.type.labelKey.tr()}',
                    style: TextStyles.boldStyle(
                      13,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ),
                const Spacer(),
                TripNumberChip(text: trip.displayNumber),
              ],
            ),
            Gap(16.h),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _PointCard(
                      emoji: '📍',
                      titleKey: 'pickup_point',
                      name: trip.fromName,
                      address: trip.from.address,
                      accentColor: HomeColors.green,
                      backgroundColor: HomeColors.lightGreen,
                    ),
                  ),
                  Gap(10.w),
                  Expanded(
                    child: _PointCard(
                      emoji: '🏁',
                      titleKey: 'dropoff_point',
                      name: trip.toName,
                      address: trip.to.address,
                      accentColor: HomeColors.orange,
                      backgroundColor: HomeColors.lightOrange,
                    ),
                  ),
                ],
              ),
            ),
            Gap(12.h),
            TripMetricsRow(trip: trip),
            Gap(12.h),
            Text(
              'trip_request_hint'.tr(),
              style: TextStyles.boldStyle(
                12,
                color: AppColors.greyColor,
                weight: FontWeight.w400,
              ),
            ),
            Gap(16.h),
            if (trip.isRequestedByMe)
              const AwaitingApprovalBadge()
            else
              SizedBox(
                height: 54.h,
                child: ElevatedButton(
                  onPressed: _isRequesting ? null : _request,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: HomeColors.green,
                    foregroundColor: AppColors.whiteColor,
                    disabledBackgroundColor: HomeColors.green.withValues(
                      alpha: 0.6,
                    ),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                  ),
                  child: _isRequesting
                      ? SizedBox(
                          width: 22.r,
                          height: 22.r,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: AppColors.whiteColor,
                          ),
                        )
                      : Text(
                          'request_trip'.tr(),
                          style: TextStyles.boldStyle(
                            16,
                            color: AppColors.whiteColor,
                          ),
                        ),
                ),
              ),
          ],
        ),
      ),
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
