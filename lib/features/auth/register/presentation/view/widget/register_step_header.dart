import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:lavanderia_delivery/core/common_widget/label.dart';
import 'package:lavanderia_delivery/core/style/app_colors.dart';
import 'package:lavanderia_delivery/core/theme/text_styles.dart';

/// الهيدر اللي فوق كل خطوة: زرار الرجوع، العنوان، رقم الخطوة وشريط التقدم
class RegisterStepHeader extends StatelessWidget {
  final String title;
  final int currentStep;
  final int totalSteps;
  final VoidCallback onBack;

  const RegisterStepHeader({
    super.key,
    required this.title,
    required this.currentStep,
    required this.totalSteps,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: InkWell(
            onTap: onBack,
            borderRadius: BorderRadius.circular(12.r),
            child: Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                color: AppColors.whiteColor.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: const Icon(
                Icons.chevron_left,
                color: AppColors.blackColor,
              ),
            ),
          ),
        ),
        Gap(8.h),
        LocalizedLabel(
          text: title,
          style: TextStyles.boldStyle(26, color: AppColors.blackColor),
        ),
        Gap(4.h),
        Label(
          text: 'step_of'.tr(args: ['${currentStep + 1}', '$totalSteps']),
          style: TextStyles.greyColor2Regular14,
        ),
        Gap(20.h),
        RegisterProgressBar(currentStep: currentStep, totalSteps: totalSteps),
      ],
    );
  }
}

class RegisterProgressBar extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const RegisterProgressBar({
    super.key,
    required this.currentStep,
    required this.totalSteps,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(totalSteps, (index) {
        final isDone = index <= currentStep;
        return Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            height: 4.h,
            margin: EdgeInsetsDirectional.only(
              end: index == totalSteps - 1 ? 0 : 6.w,
            ),
            decoration: BoxDecoration(
              color: isDone
                  ? AppColors.primaryColor
                  : AppColors.semiWhiteColor2,
              borderRadius: BorderRadius.circular(4.r),
            ),
          ),
        );
      }),
    );
  }
}
