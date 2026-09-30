import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:gap/gap.dart';
import 'package:lavanderia_delivery/core/bloc/base_bloc.dart';
import 'package:lavanderia_delivery/core/common_widget/custom_app_bar.dart';
import 'package:lavanderia_delivery/core/service_locator/service_locator.dart';
import 'package:lavanderia_delivery/core/style/app_colors.dart';
import 'package:lavanderia_delivery/core/theme/text_styles.dart';
import 'package:lavanderia_delivery/features/home/presentation/view/widget/home_colors.dart';
import 'package:lavanderia_delivery/features/home/presentation/view/widget/home_widgets.dart';
import 'package:lavanderia_delivery/features/profile/models/privacy_policy_model.dart';
import 'package:lavanderia_delivery/features/profile/presentation/logic/privacy_policy_cubit.dart';

/// شاشة سياسة الخصوصية للمندوب: مقدمة فوق وتحتها المحتوى اللي جاي
/// من api/auth/privacy-policy، وهو HTML بيتكتب من لوحة التحكم
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<PrivacyPolicyCubit>()..getPrivacyPolicy(),
      child: Scaffold(
        backgroundColor: AppColors.backgroundColor,
        appBar: const CustomAppBar(
          title: 'privacy_policy',
          backgroundColor: AppColors.backgroundColor,
        ),
        body: BlocBuilder<PrivacyPolicyCubit, BaseState<PrivacyPolicyModel>>(
          builder: (context, state) {
            final policy = state.data;
            return ListView(
              padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h),
              children: [
                const _PrivacyIntro(),
                Gap(12.h),
                if (policy != null)
                  _PolicyContentCard(policy: policy)
                else if (state.isFailure)
                  _PolicyLoadError(
                    message: state.errorMessage ?? '',
                    onRetry: () =>
                        context.read<PrivacyPolicyCubit>().getPrivacyPolicy(),
                  )
                else
                  const Center(child: CircularProgressIndicator()),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// كارت المقدمة بالأزرق الباهت عشان يفرق عن المحتوى
class _PrivacyIntro extends StatelessWidget {
  const _PrivacyIntro();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(18.r),
      decoration: BoxDecoration(
        color: HomeColors.lightBlue,
        borderRadius: BorderRadius.circular(22.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'privacy_intro_title'.tr(),
            style: TextStyles.boldStyle(16, color: AppColors.primaryColor),
          ),
          Gap(8.h),
          Text(
            'driver_privacy_intro_body'.tr(),
            style: TextStyles.boldStyle(
              13,
              color: AppColors.greyColor,
              weight: FontWeight.w400,
            ).copyWith(height: 1.7),
          ),
        ],
      ),
    );
  }
}

class _PolicyContentCard extends StatelessWidget {
  final PrivacyPolicyModel policy;

  const _PolicyContentCard({required this.policy});

  @override
  Widget build(BuildContext context) {
    final updatedAt = policy.updatedAt;
    return HomeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HtmlWidget(
            policy.content,
            // الستايل الأساسي للنص، والـ inline styles اللي في الـ HTML بتغطي عليه
            textStyle: TextStyles.boldStyle(
              13,
              color: AppColors.greyColor,
              weight: FontWeight.w400,
            ).copyWith(height: 1.7),
          ),
          if (updatedAt != null) ...[
            Gap(12.h),
            Text(
              'last_updated'.tr(
                args: [DateFormat('yyyy/MM/dd').format(updatedAt)],
              ),
              style: TextStyles.boldStyle(
                12,
                color: AppColors.lightTextColor,
                weight: FontWeight.w400,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PolicyLoadError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _PolicyLoadError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return HomeCard(
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyles.boldStyle(
              13,
              color: AppColors.greyColor,
              weight: FontWeight.w400,
            ),
          ),
          Gap(8.h),
          TextButton(onPressed: onRetry, child: Text('try_again'.tr())),
        ],
      ),
    );
  }
}
