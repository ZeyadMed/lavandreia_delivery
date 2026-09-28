import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:lavanderia_delivery/core/common_widget/label.dart';
import 'package:lavanderia_delivery/core/router/app_router.dart';
import 'package:lavanderia_delivery/core/style/app_colors.dart';
import 'package:lavanderia_delivery/core/theme/text_styles.dart';
import 'package:lavanderia_delivery/core/widget/custom_button.dart';

/// بتظهر بعد تأكيد التسجيل، الحساب مستني موافقة الإدارة على البيانات والمستندات
class AccountUnderReviewScreen extends StatelessWidget {
  const AccountUnderReviewScreen({super.key});

  void _backToHome(BuildContext context) => context.go(AppRouter.login);

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _backToHome(context);
      },
      child: Scaffold(
        backgroundColor: AppColors.brandBgColor,
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 110.w,
                  height: 110.w,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xffFBE8A6),
                    borderRadius: BorderRadius.circular(32.r),
                  ),
                  child: Text('⏳', style: TextStyle(fontSize: 48.sp)),
                ),
                Gap(28.h),
                LocalizedLabel(
                  text: 'account_under_review',
                  textAlign: TextAlign.center,
                  style: TextStyles.boldStyle(26, color: AppColors.blackColor),
                ),
                Gap(14.h),
                LocalizedLabel(
                  text: 'account_under_review_desc',
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  style: TextStyles.boldStyle(
                    14,
                    color: AppColors.greyColor,
                    weight: FontWeight.w400,
                  ),
                ),
                Gap(36.h),
                CustomButton(
                  onPressed: () => _backToHome(context),
                  title: 'back_to_home',
                  borderRadius: 16.r,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
