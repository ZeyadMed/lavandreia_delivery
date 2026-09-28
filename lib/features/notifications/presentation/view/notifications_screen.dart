import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:lavanderia_delivery/core/style/app_colors.dart';
import 'package:lavanderia_delivery/core/theme/text_styles.dart';
import 'package:lavanderia_delivery/features/home/presentation/view/widget/home_colors.dart';
import 'package:lavanderia_delivery/features/home/presentation/view/widget/home_widgets.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  // TODO: هتتجاب من الـ API لما يجهز
  static const List<({String title, String time})> _notifications = [
    (title: 'لديك طلب توصيل جديد', time: 'منذ دقيقتين'),
    (title: 'تم اعتماد حسابك بنجاح', time: 'منذ ساعة'),
    (title: 'تم استلام الطلب #ORD-10245', time: 'منذ 3 ساعات'),
    (title: 'تم تسليم الطلب #ORD-10244 بنجاح', time: 'منذ يوم'),
    (title: 'تم إلغاء الطلب #ORD-10243', time: 'منذ يومين'),
    (title: 'تم إضافة 75 ج.م لأرباحك', time: 'منذ يومين'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: Column(
        children: [
          const _NotificationsHeader(),
          Expanded(
            child: _notifications.isEmpty
                ? const HomeEmptyState(
                    emoji: '🔔',
                    titleKey: 'no_notifications',
                    subtitleKey: 'no_notifications_hint',
                  )
                : ListView.separated(
                    padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 24.h),
                    itemCount: _notifications.length,
                    separatorBuilder: (_, _) => Gap(12.h),
                    itemBuilder: (context, index) {
                      final item = _notifications[index];
                      return NotificationCard(
                        title: item.title,
                        time: item.time,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _NotificationsHeader extends StatelessWidget {
  const _NotificationsHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [HomeColors.headerStart, HomeColors.headerEnd],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32.r)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 24.h),
          child: Text(
            'notifications'.tr(),
            style: TextStyles.boldStyle(22, color: AppColors.whiteColor),
          ),
        ),
      ),
    );
  }
}

/// كارت الإشعار: أيقونة نوتيفيكيشن موحدة + العنوان + الوقت
class NotificationCard extends StatelessWidget {
  final String title;
  final String time;
  final VoidCallback? onTap;

  const NotificationCard({
    super.key,
    required this.title,
    required this.time,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return HomeCard(
      onTap: onTap,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      child: Row(
        children: [
          Container(
            width: 44.r,
            height: 44.r,
            decoration: BoxDecoration(
              color: HomeColors.lightBlue,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              Icons.notifications_none_rounded,
              color: AppColors.primaryColor,
              size: 24.sp,
            ),
          ),
          Gap(14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyles.boldStyle(
                    14,
                    color: AppColors.blackColor,
                    weight: FontWeight.w500,
                  ),
                ),
                Gap(4.h),
                Text(
                  time,
                  style: TextStyles.boldStyle(
                    12,
                    color: AppColors.lightTextColor,
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
