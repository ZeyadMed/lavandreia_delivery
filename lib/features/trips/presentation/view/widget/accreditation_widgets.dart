import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:lavanderia_delivery/core/style/app_colors.dart';
import 'package:lavanderia_delivery/core/theme/text_styles.dart';
import 'package:lavanderia_delivery/features/home/presentation/view/widget/home_colors.dart';
import 'package:lavanderia_delivery/features/home/presentation/view/widget/home_widgets.dart';
import 'package:lavanderia_delivery/features/trips/models/accrediting_laundry_model.dart';

/// قسم "معتمد من": أسماء المغاسل اللي معتمدانا كـ chips، ولو كتير بنعرض
/// أول [maxVisible] و "+N" بتفتح الباقي
class AccreditedByCard extends StatefulWidget {
  final List<AccreditingLaundryModel> laundries;
  final int maxVisible;

  const AccreditedByCard({
    super.key,
    required this.laundries,
    this.maxVisible = 3,
  });

  @override
  State<AccreditedByCard> createState() => _AccreditedByCardState();
}

class _AccreditedByCardState extends State<AccreditedByCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final laundries = widget.laundries;
    final hidden = _isExpanded ? 0 : laundries.length - widget.maxVisible;
    final visible = hidden > 0 ? laundries.take(widget.maxVisible) : laundries;

    return HomeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('accredited_by'.tr(), style: TextStyles.boldStyle(16)),
          Gap(12.h),
          if (laundries.isEmpty)
            Text(
              'accreditation_empty'.tr(),
              style: TextStyles.boldStyle(
                13,
                color: AppColors.greyColor,
                weight: FontWeight.w400,
              ),
            )
          else
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: [
                for (final laundry in visible)
                  _AccreditationChip(label: laundry.laundryName),
                if (hidden > 0)
                  _AccreditationChip(
                    label: '+$hidden',
                    onTap: () => setState(() => _isExpanded = true),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _AccreditationChip extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const _AccreditationChip({required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(50.r);
    return Material(
      color: HomeColors.lightGreen,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
          child: Text(
            label,
            style: TextStyles.boldStyle(12, color: HomeColors.green),
          ),
        ),
      ),
    );
  }
}

/// بيظهر لما المغسلة بتاعة الرحلة تكون معتمدانا. [onDark] للهيدرز الزرقا
class AccreditedLaundryBadge extends StatelessWidget {
  final String labelKey;
  final bool onDark;

  const AccreditedLaundryBadge({
    super.key,
    required this.labelKey,
    this.onDark = false,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = onDark ? AppColors.whiteColor : HomeColors.green;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: onDark
            ? AppColors.whiteColor.withValues(alpha: 0.2)
            : HomeColors.lightGreen,
        borderRadius: BorderRadius.circular(50.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7.r,
            height: 7.r,
            decoration: BoxDecoration(
              color: onDark ? AppColors.whiteColor : HomeColors.green,
              shape: BoxShape.circle,
            ),
          ),
          Gap(6.w),
          Text(
            labelKey.tr(),
            style: TextStyles.boldStyle(12, color: foreground),
          ),
        ],
      ),
    );
  }
}
