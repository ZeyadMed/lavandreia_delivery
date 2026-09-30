import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:lavanderia_delivery/core/bloc/base_bloc.dart';
import 'package:lavanderia_delivery/core/common_widget/custom_error_message.dart';
import 'package:lavanderia_delivery/core/service_locator/service_locator.dart';
import 'package:lavanderia_delivery/core/style/app_colors.dart';
import 'package:lavanderia_delivery/core/theme/text_styles.dart';
import 'package:lavanderia_delivery/features/home/presentation/view/widget/home_colors.dart';
import 'package:lavanderia_delivery/features/home/presentation/view/widget/home_widgets.dart';
import 'package:lavanderia_delivery/features/notifications/models/notification_model.dart';
import 'package:lavanderia_delivery/features/notifications/presentation/logic/notifications_cubit.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<NotificationsCubit>()
        ..initPagination()
        ..fetch(page: 1),
      child: Scaffold(
        backgroundColor: AppColors.backgroundColor,
        body: BlocBuilder<NotificationsCubit, BaseState<NotificationModel>>(
          builder: (context, state) {
            return Column(
              children: [
                _NotificationsHeader(
                  hasItems: state.items.isNotEmpty,
                  hasUnread: state.items.any((n) => !n.isRead),
                ),
                Expanded(child: _NotificationsBody(state: state)),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _NotificationsBody extends StatelessWidget {
  final BaseState<NotificationModel> state;

  const _NotificationsBody({required this.state});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<NotificationsCubit>();

    if (state.isLoading && state.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.isFailure && state.items.isEmpty) {
      return _NotificationsError(
        message: state.errorMessage ?? '',
        onRetry: cubit.refresh,
      );
    }

    if (state.items.isEmpty) {
      // ListView عشان الـ RefreshIndicator يشتغل حتى والليستة فاضية
      return RefreshIndicator(
        onRefresh: cubit.refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            Gap(80.h),
            const HomeEmptyState(
              emoji: '🔔',
              titleKey: 'no_notifications',
              subtitleKey: 'no_notifications_hint',
            ),
          ],
        ),
      );
    }

    final showLoadMore = state.isLoadingMore || state.isLoadingMoreFauilare;

    return RefreshIndicator(
      onRefresh: cubit.refresh,
      child: ListView.separated(
        controller: cubit.scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 24.h),
        itemCount: state.items.length + (showLoadMore ? 1 : 0),
        separatorBuilder: (_, _) => Gap(12.h),
        itemBuilder: (context, index) {
          if (index == state.items.length) {
            return state.isLoadingMore
                ? const Center(child: CircularProgressIndicator())
                : TextButton(
                    onPressed: () => cubit.fetch(page: state.page),
                    child: Text('try_again'.tr()),
                  );
          }

          final item = state.items[index];
          return Dismissible(
            key: ValueKey(item.id),
            direction: DismissDirection.endToStart,
            background: const _DeleteBackground(),
            onDismissed: (_) => _run(
              context,
              cubit.deleteNotification(item.id),
            ),
            child: NotificationCard(
              title: item.title,
              body: item.body,
              time: _timeAgo(item.createdAt),
              isRead: item.isRead,
              onTap: item.isRead
                  ? null
                  : () => _run(context, cubit.markAsRead(item.id)),
            ),
          );
        },
      ),
    );
  }
}

/// بتستنى العملية ولو رجعت رسالة خطأ بتعرضها
Future<void> _run(BuildContext context, Future<String?> action) async {
  final error = await action;
  if (error != null && context.mounted) {
    CustomErrorOverlay.show(context: context, text: error);
  }
}

String _timeAgo(DateTime? date) {
  if (date == null) return '';
  final diff = DateTime.now().difference(date);
  if (diff.inMinutes < 1) return 'just_now'.tr();
  if (diff.inHours < 1) {
    return 'minutes_ago'.tr(args: ['${diff.inMinutes}']);
  }
  if (diff.inDays < 1) return 'hours_ago'.tr(args: ['${diff.inHours}']);
  if (diff.inDays < 7) return 'days_ago'.tr(args: ['${diff.inDays}']);
  return DateFormat('yyyy/MM/dd').format(date);
}

class _NotificationsHeader extends StatelessWidget {
  final bool hasItems;
  final bool hasUnread;

  const _NotificationsHeader({required this.hasItems, required this.hasUnread});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<NotificationsCubit>();

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
          padding: EdgeInsets.fromLTRB(20.w, 12.h, 8.w, 24.h),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'notifications'.tr(),
                  style: TextStyles.boldStyle(22, color: AppColors.whiteColor),
                ),
              ),
              if (hasUnread)
                IconButton(
                  tooltip: 'mark_all_as_read'.tr(),
                  onPressed: () => _run(context, cubit.markAllAsRead()),
                  icon: const Icon(
                    Icons.done_all_rounded,
                    color: AppColors.whiteColor,
                  ),
                ),
              if (hasItems)
                IconButton(
                  tooltip: 'delete_all_notifications'.tr(),
                  onPressed: () => _confirmDeleteAll(context, cubit),
                  icon: const Icon(
                    Icons.delete_sweep_outlined,
                    color: AppColors.whiteColor,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// بنأكد قبل المسح لأنه مالوش رجوع
  Future<void> _confirmDeleteAll(
    BuildContext context,
    NotificationsCubit cubit,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.whiteColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Text(
          'delete_all_notifications'.tr(),
          style: TextStyles.boldStyle(17),
        ),
        content: Text(
          'delete_all_notifications_confirm'.tr(),
          style: TextStyles.boldStyle(
            14,
            color: AppColors.greyColor,
            weight: FontWeight.w400,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              'cancel'.tr(),
              style: TextStyles.boldStyle(14, color: AppColors.greyColor),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              'delete'.tr(),
              style: TextStyles.boldStyle(14, color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await _run(context, cubit.deleteAll());
    }
  }
}

class _DeleteBackground extends StatelessWidget {
  const _DeleteBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: AlignmentDirectional.centerEnd,
      padding: EdgeInsetsDirectional.only(end: 24.w),
      decoration: BoxDecoration(
        color: Colors.redAccent,
        borderRadius: BorderRadius.circular(22.r),
      ),
      child: Icon(
        Icons.delete_outline_rounded,
        color: AppColors.whiteColor,
        size: 26.sp,
      ),
    );
  }
}

class _NotificationsError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _NotificationsError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyles.boldStyle(
                14,
                color: AppColors.greyColor,
                weight: FontWeight.w400,
              ),
            ),
            Gap(12.h),
            TextButton(onPressed: onRetry, child: Text('try_again'.tr())),
          ],
        ),
      ),
    );
  }
}

/// كارت الإشعار: أيقونة نوتيفيكيشن موحدة + العنوان + النص + الوقت،
/// والإشعار اللي لسه ماتقراش عليه نقطة وعنوانه أتقل
class NotificationCard extends StatelessWidget {
  final String title;
  final String body;
  final String time;
  final bool isRead;
  final VoidCallback? onTap;

  const NotificationCard({
    super.key,
    required this.title,
    this.body = '',
    required this.time,
    this.isRead = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return HomeCard(
      onTap: onTap,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                    weight: isRead ? FontWeight.w500 : FontWeight.w700,
                  ),
                ),
                if (body.isNotEmpty) ...[
                  Gap(4.h),
                  Text(
                    body,
                    style: TextStyles.boldStyle(
                      13,
                      color: AppColors.greyColor,
                      weight: FontWeight.w400,
                    ),
                  ),
                ],
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
          if (!isRead) ...[
            Gap(8.w),
            Container(
              width: 8.r,
              height: 8.r,
              margin: EdgeInsets.only(top: 6.h),
              decoration: const BoxDecoration(
                color: AppColors.primaryColor,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
