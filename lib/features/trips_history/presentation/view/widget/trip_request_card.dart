import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:lavanderia_delivery/core/style/app_colors.dart';
import 'package:lavanderia_delivery/core/theme/text_styles.dart';
import 'package:lavanderia_delivery/features/home/presentation/view/widget/home_colors.dart';
import 'package:lavanderia_delivery/features/home/presentation/view/widget/home_widgets.dart';
import 'package:lavanderia_delivery/features/trips/models/driver_accreditation.dart';
import 'package:lavanderia_delivery/features/trips/models/trip_request_model.dart';
import 'package:lavanderia_delivery/features/trips/presentation/view/widget/accreditation_widgets.dart';
import 'package:lavanderia_delivery/features/trips/presentation/view/widget/trip_widgets.dart';

/// كارت طلب في "طلباتي": حالة الطلب + رقم الرحلة + المسار + الرسوم + التاريخ،
/// و badge لو المغسلة صاحبة الرحلة معتمدانا
class TripRequestCard extends StatelessWidget {
  final TripRequestModel request;
  final VoidCallback? onTap;

  const TripRequestCard({super.key, required this.request, this.onTap});

  String _formatDate(BuildContext context, DateTime date) {
    final month = DateFormat.MMMM(context.locale.languageCode).format(date);
    return '${date.day} $month ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final trip = request.trip;
    final date = request.createdAt;
    return HomeCard(
      onTap: onTap,
      padding: EdgeInsets.all(18.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              RequestStatusBadge(status: request.status),
              const Spacer(),
              Text(
                trip?.displayNumber ?? '#${request.tripId}',
                textDirection: TextDirection.ltr,
                style: TextStyles.boldStyle(14, color: AppColors.blackColor),
              ),
            ],
          ),
          if (trip != null) ...[
            Gap(12.h),
            Text(
              '${trip.type.emoji} ${trip.type.labelKey.tr()}',
              style: TextStyles.boldStyle(16, color: AppColors.blackColor),
            ),
            Gap(6.h),
            Text(
              '${trip.fromName} ← ${trip.toName}',
              style: TextStyles.boldStyle(
                13,
                color: AppColors.greyColor,
                weight: FontWeight.w400,
              ),
            ),
          ],
          if (request.isAccreditedByTripLaundry) ...[
            Gap(10.h),
            const AccreditedLaundryBadge(
              labelKey: 'accredited_by_this_laundry',
            ),
          ],
          Gap(12.h),
          Row(
            children: [
              if (trip != null)
                Text(
                  '${trip.fee.toStringAsFixed(2)} ${'currency'.tr()}',
                  style: TextStyles.boldStyle(16, color: HomeColors.green),
                ),
              const Spacer(),
              if (date != null)
                Text(
                  _formatDate(context, date),
                  style: TextStyles.boldStyle(
                    13,
                    color: AppColors.lightTextColor,
                    weight: FontWeight.w400,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class RequestStatusBadge extends StatelessWidget {
  final TripRequestStatus status;

  const RequestStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg, String key) = switch (status) {
      TripRequestStatus.pending => (
        HomeColors.lightOrange,
        HomeColors.orange,
        'request_pending',
      ),
      TripRequestStatus.approved => (
        HomeColors.lightGreen,
        HomeColors.green,
        'request_approved',
      ),
      TripRequestStatus.rejected => (
        const Color(0xffFDECEC),
        HomeColors.red,
        'request_rejected',
      ),
    };
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Text(key.tr(), style: TextStyles.boldStyle(12, color: fg)),
    );
  }
}
