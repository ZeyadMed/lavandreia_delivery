import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:lavanderia_delivery/core/bloc/base_bloc.dart';
import 'package:lavanderia_delivery/core/common_widget/custom_app_bar.dart';
import 'package:lavanderia_delivery/core/common_widget/custom_error_message.dart';
import 'package:lavanderia_delivery/core/service_locator/service_locator.dart';
import 'package:lavanderia_delivery/core/style/app_colors.dart';
import 'package:lavanderia_delivery/core/theme/text_styles.dart';
import 'package:lavanderia_delivery/features/home/presentation/view/widget/home_colors.dart';
import 'package:lavanderia_delivery/features/home/presentation/view/widget/home_widgets.dart';
import 'package:lavanderia_delivery/features/profile/models/contact_info_model.dart';
import 'package:lavanderia_delivery/features/profile/presentation/logic/contact_info_cubit.dart';
import 'package:url_launcher/url_launcher.dart';

/// شاشة تواصل معنا: الأرقام والإيميل جايين من api/auth/contacts
/// وكل طريقة تواصل بتفتح التطبيق بتاعها
class ContactUsScreen extends StatelessWidget {
  const ContactUsScreen({super.key});

  /// بيفتح اللينك، ولو الجهاز مش عارف يفتحه بنعرض رسالة بدل ما الدوسة تضيع
  Future<void> _launch(BuildContext context, Uri uri) async {
    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    ).catchError((_) => false);

    if (!launched && context.mounted) {
      CustomErrorOverlay.show(context: context, text: 'contact_failed'.tr());
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ContactInfoCubit>()..getContacts(),
      child: Scaffold(
        backgroundColor: AppColors.backgroundColor,
        appBar: const CustomAppBar(
          title: 'contact_us',
          backgroundColor: AppColors.backgroundColor,
        ),
        body: BlocBuilder<ContactInfoCubit, BaseState<ContactInfoModel>>(
          builder: (context, state) {
            final contacts = state.data;
            return ListView(
              padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h),
              children: [
                const _ContactHeaderCard(),
                Gap(16.h),
                if (contacts != null)
                  ..._channels(context, contacts)
                else if (state.isFailure)
                  _ContactLoadError(
                    message: state.errorMessage ?? '',
                    onRetry: () =>
                        context.read<ContactInfoCubit>().getContacts(),
                  )
                else
                  const Center(child: CircularProgressIndicator()),
                // Gap(16.h),
                // const _WorkingHoursCard(),
              ],
            );
          },
        ),
      ),
    );
  }

  /// الحقول الفاضية مابتظهرش عشان مايبقاش فيه كارت بيفتح لينك فاضي
  List<Widget> _channels(BuildContext context, ContactInfoModel contacts) {
    final cards = [
      for (final phone in [contacts.phoneNumber1, contacts.phoneNumber2])
        if (phone.isNotEmpty)
          _ContactChannelCard(
            emoji: '📞',
            color: HomeColors.lightBlue,
            titleKey: 'contact_phone',
            value: phone,
            onTap: () => _launch(context, Uri(scheme: 'tel', path: phone)),
          ),
      if (contacts.email.isNotEmpty)
        _ContactChannelCard(
          emoji: '✉️',
          color: HomeColors.lightOrange,
          titleKey: 'contact_email',
          value: contacts.email,
          onTap: () =>
              _launch(context, Uri(scheme: 'mailto', path: contacts.email)),
        ),
    ];
    return [
      for (int i = 0; i < cards.length; i++) ...[
        if (i > 0) Gap(12.h),
        cards[i],
      ],
    ];
  }
}

class _ContactLoadError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ContactLoadError({required this.message, required this.onRetry});

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

class _ContactHeaderCard extends StatelessWidget {
  const _ContactHeaderCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(18.r),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [HomeColors.headerStart, HomeColors.headerEnd],
        ),
        borderRadius: BorderRadius.circular(22.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44.r,
                height: 44.r,
                decoration: BoxDecoration(
                  color: AppColors.whiteColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                alignment: Alignment.center,
                child: Text('🎧', style: TextStyle(fontSize: 22.sp)),
              ),
              Gap(12.w),
              Expanded(
                child: Text(
                  'contact_header_title'.tr(),
                  style: TextStyles.boldStyle(17, color: AppColors.whiteColor),
                ),
              ),
            ],
          ),
          Gap(12.h),
          Text(
            'driver_contact_header_body'.tr(),
            style: TextStyles.boldStyle(
              13,
              color: AppColors.whiteColor.withValues(alpha: 0.9),
              weight: FontWeight.w400,
            ).copyWith(height: 1.7),
          ),
        ],
      ),
    );
  }
}

/// سطر طريقة تواصل: أيقونة + الاسم وتحته القيمة
class _ContactChannelCard extends StatelessWidget {
  final String emoji;
  final Color color;
  final String titleKey;
  final String value;
  final VoidCallback onTap;

  const _ContactChannelCard({
    required this.emoji,
    required this.color,
    required this.titleKey,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return HomeCard(
      onTap: onTap,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      child: Row(
        children: [
          Container(
            width: 44.r,
            height: 44.r,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12.r),
            ),
            alignment: Alignment.center,
            child: Text(emoji, style: TextStyle(fontSize: 20.sp)),
          ),
          Gap(14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titleKey.tr(),
                  style: TextStyles.boldStyle(15, color: AppColors.blackColor),
                ),
                Gap(3.h),
                // الرقم والإيميل دايماً بيتعرضوا من الشمال لليمين
                Text(
                  value,
                  textDirection: TextDirection.ltr,
                  style: TextStyles.boldStyle(
                    13,
                    color: AppColors.greyColor,
                    weight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios_rounded,
            size: 14.sp,
            color: AppColors.greyColor4,
          ),
        ],
      ),
    );
  }
}

class _WorkingHoursCard extends StatelessWidget {
  const _WorkingHoursCard();

  @override
  Widget build(BuildContext context) {
    return HomeCard(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      child: Row(
        children: [
          Text('🕘', style: TextStyle(fontSize: 20.sp)),
          Gap(12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'working_hours'.tr(),
                  style: TextStyles.boldStyle(15, color: AppColors.blackColor),
                ),
                Gap(3.h),
                Text(
                  'working_hours_value'.tr(),
                  style: TextStyles.boldStyle(
                    13,
                    color: AppColors.greyColor,
                    weight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
