import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:lavanderia_delivery/core/common_widget/custom_error_message.dart';
import 'package:lavanderia_delivery/core/common_widget/custom_success_message.dart';
import 'package:lavanderia_delivery/core/style/app_colors.dart';
import 'package:lavanderia_delivery/core/theme/text_styles.dart';
import 'package:lavanderia_delivery/features/home/models/delivery_order_model.dart';
import 'package:lavanderia_delivery/features/home/presentation/logic/home_cubit.dart';
import 'package:lavanderia_delivery/features/home/presentation/view/widget/home_colors.dart';
import 'package:lavanderia_delivery/features/home/presentation/view/widget/home_widgets.dart';
import 'package:lavanderia_delivery/features/home/presentation/view/widget/new_order_bottom_sheet.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(create: (_) => HomeCubit(), child: const _HomeView());
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView();

  // TODO: هيتجاب من بيانات المستخدم المتخزنة لما الـ API يجهز
  static const String _driverName = 'أحمد محمد';

  Future<void> _openOrder(
    BuildContext context,
    DeliveryOrderModel order, {
    bool isSimulated = false,
  }) async {
    final cubit = context.read<HomeCubit>();
    final accepted = await showNewOrderBottomSheet(context, order);
    if (!context.mounted) return;

    if (accepted == true) {
      cubit.acceptOrder(order);
      CustomSuccessOverlay.show(context: context, text: 'order_accepted');
    } else if (accepted == false) {
      cubit.rejectOrder(order);
      CustomErrorOverlay.show(context: context, text: 'order_rejected'.tr());
    } else if (isSimulated) {
      // قفل الشيت من غير ما يرد، الطلب يفضل مستنيه في الليست
      cubit.addPendingOrder(order);
    }
  }

  void _simulateNewOrder(BuildContext context) {
    final cubit = context.read<HomeCubit>();
    if (!cubit.state.isAvailable) {
      CustomErrorOverlay.show(
        context: context,
        text: 'enable_availability_first'.tr(),
      );
      return;
    }
    _openOrder(context, cubit.generateSimulatedOrder(), isSimulated: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: Column(
        children: [
          const HomeHeader(name: _driverName),
          Expanded(
            child: BlocBuilder<HomeCubit, HomeState>(
              builder: (context, state) {
                return ListView(
                  padding: EdgeInsets.fromLTRB(16.w, 24.h, 16.w, 24.h),
                  children: [
                    AvailabilityCard(
                      isAvailable: state.isAvailable,
                      onChanged: context.read<HomeCubit>().toggleAvailability,
                    ),
                    Gap(16.h),
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: StatCard(
                              emoji: '🚗',
                              value: '${state.todayTrips}',
                              labelKey: 'today_trips',
                            ),
                          ),
                          Gap(12.w),
                          Expanded(
                            child: StatCard(
                              emoji: '💰',
                              value:
                                  '${formatOrderNumber(state.todayEarnings)} ${'currency'.tr()}',
                              labelKey: 'today_earnings',
                            ),
                          ),
                        ],
                      ),
                    ),
                    Gap(24.h),
                    Text(
                      'waiting_for_orders'.tr(),
                      style: TextStyles.boldStyle(
                        17,
                        color: AppColors.blackColor,
                      ),
                    ),
                    Gap(12.h),
                    if (!state.isAvailable)
                      const HomeEmptyState(
                        emoji: '😴',
                        titleKey: 'unavailable_for_orders',
                        subtitleKey: 'unavailable_hint',
                      )
                    else if (state.pendingOrders.isEmpty)
                      const HomeEmptyState(
                        emoji: '📦',
                        titleKey: 'no_new_orders',
                        subtitleKey: 'no_new_orders_desc',
                      )
                    else
                      ...state.pendingOrders.map(
                        (order) => Padding(
                          padding: EdgeInsets.only(bottom: 12.h),
                          child: PendingOrderCard(
                            order: order,
                            onTap: () => _openOrder(context, order),
                          ),
                        ),
                      ),
                    Gap(16.h),
                    SimulateOrderButton(
                      onPressed: () => _simulateNewOrder(context),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// الهيدر الأزرق: البروفايل والترحيب وزرار الإشعارات
class HomeHeader extends StatelessWidget {
  final String name;

  const HomeHeader({super.key, required this.name});

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
          padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 28.h),
          child: Row(
            children: [
              // _HeaderIconButton(
              //   child: Stack(
              //     clipBehavior: Clip.none,
              //     children: [
              //       Icon(
              //         Icons.notifications_none_rounded,
              //         color: AppColors.whiteColor,
              //         size: 24.sp,
              //       ),
              //       PositionedDirectional(
              //         top: 0,
              //         start: 0,
              //         child: Container(
              //           width: 8.r,
              //           height: 8.r,
              //           decoration: const BoxDecoration(
              //             color: Color(0xffFF5A5F),
              //             shape: BoxShape.circle,
              //           ),
              //         ),
              //       ),
              //     ],
              //   ),
              // ),
              // Gap(14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'hello_comma'.tr(),
                      style: TextStyles.boldStyle(
                        13,
                        color: AppColors.whiteColor.withValues(alpha: 0.85),
                        weight: FontWeight.w400,
                      ),
                    ),
                    Gap(2.h),
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyles.boldStyle(
                        22,
                        color: AppColors.whiteColor,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 48.r,
                height: 48.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.whiteColor.withValues(alpha: 0.2),
                  border: Border.all(
                    color: AppColors.whiteColor.withValues(alpha: 0.6),
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.person_rounded,
                  color: AppColors.whiteColor,
                  size: 28.sp,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final Widget child;

  const _HeaderIconButton({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44.r,
      height: 44.r,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.whiteColor.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: child,
    );
  }
}
