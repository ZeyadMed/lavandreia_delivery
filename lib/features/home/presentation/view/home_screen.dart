import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:lavanderia_delivery/core/bloc/base_bloc.dart';
import 'package:lavanderia_delivery/core/cache_manager/cache_manager.dart';
import 'package:lavanderia_delivery/core/common_widget/custom_error_message.dart';
import 'package:lavanderia_delivery/core/common_widget/custom_success_message.dart';
import 'package:lavanderia_delivery/core/helpers/location_service.dart';
import 'package:lavanderia_delivery/core/router/app_router.dart';
import 'package:lavanderia_delivery/core/service_locator/service_locator.dart';
import 'package:lavanderia_delivery/core/style/app_colors.dart';
import 'package:lavanderia_delivery/core/theme/text_styles.dart';
import 'package:lavanderia_delivery/features/home/presentation/logic/home_cubit.dart';
import 'package:lavanderia_delivery/features/home/presentation/view/widget/home_colors.dart';
import 'package:lavanderia_delivery/features/home/presentation/view/widget/home_widgets.dart';
import 'package:lavanderia_delivery/features/trips/models/delivery_trip_model.dart';
import 'package:lavanderia_delivery/features/trips/presentation/logic/available_trips_cubit.dart';
import 'package:lavanderia_delivery/features/trips/presentation/view/widget/trip_details_bottom_sheet.dart';
import 'package:lavanderia_delivery/features/trips/presentation/view/widget/trip_widgets.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<HomeCubit>()..load()),
        BlocProvider(
          create: (_) => getIt<AvailableTripsCubit>()..initPagination(),
        ),
      ],
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView();

  Future<void> _toggleAvailability(BuildContext context, bool value) async {
    final error = await context.read<HomeCubit>().toggleAvailability(value);
    if (error != null && context.mounted) {
      CustomErrorOverlay.show(context: context, text: error);
    }
  }

  Future<void> _openTrip(BuildContext context, DeliveryTripModel trip) async {
    final tripsCubit = context.read<AvailableTripsCubit>();
    final requested = await showTripDetailsBottomSheet(
      context,
      trip,
      onRequest: () => tripsCubit.requestTrip(trip),
    );
    if (requested == true && context.mounted) {
      CustomSuccessOverlay.show(context: context, text: 'trip_requested');
    }
  }

  Future<void> _openActiveTrip(BuildContext context, int? tripId) async {
    final homeCubit = context.read<HomeCubit>();
    await context.push(AppRouter.activeTrip, extra: tripId);
    // الرحلة ممكن تكون خلصت واحنا جوه، فبنحدّث الـ banner والإحصائيات
    homeCubit.loadMyTrips();
  }

  Future<void> _refresh(BuildContext context) async {
    final homeCubit = context.read<HomeCubit>();
    final tripsCubit = context.read<AvailableTripsCubit>();
    await Future.wait([
      homeCubit.load(),
      if (homeCubit.state.isAvailable) tripsCubit.refresh(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final tripsCubit = context.read<AvailableTripsCubit>();

    return MultiBlocListener(
      listeners: [
        // أول ما التوفر يتفتح (أو يتقرا من البروفايل) بنجيب الرحلات المتاحة
        BlocListener<HomeCubit, HomeState>(
          listenWhen: (previous, current) =>
              previous.isAvailable != current.isAvailable,
          listener: (context, state) {
            if (state.isAvailable) tripsCubit.refresh();
          },
        ),
        // رد المغسلة على طلب رحلة
        BlocListener<HomeCubit, HomeState>(
          listenWhen: (previous, current) =>
              previous.resolutionTick != current.resolutionTick,
          listener: (context, state) {
            if (state.resolution == TripResolution.approved) {
              CustomSuccessOverlay.show(
                context: context,
                text: 'trip_request_approved',
              );
              _openActiveTrip(context, state.activeTrip?.id);
            } else if (state.resolution == TripResolution.rejected) {
              CustomErrorOverlay.show(
                context: context,
                text: 'trip_request_rejected'.tr(),
              );
            }
          },
        ),
      ],
      child: Scaffold(
        backgroundColor: AppColors.backgroundColor,
        body: Column(
          children: [
            HomeHeader(name: CacheManager.getUserName() ?? ''),
            Expanded(
              child: BlocBuilder<HomeCubit, HomeState>(
                builder: (context, state) {
                  return RefreshIndicator(
                    onRefresh: () => _refresh(context),
                    child: ListView(
                      // من غير التوفر مفيش رحلات، فمش عايزين السكرول يحمّل صفحات
                      controller: state.isAvailable
                          ? tripsCubit.scrollController
                          : null,
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(16.w, 24.h, 16.w, 24.h),
                      children: [
                        AvailabilityCard(
                          isAvailable: state.isAvailable,
                          onChanged: (value) =>
                              _toggleAvailability(context, value),
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
                                      '${formatAmount(state.todayEarnings)} ${'currency'.tr()}',
                                  labelKey: 'today_earnings',
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (state.activeTrip != null) ...[
                          Gap(16.h),
                          ActiveTripBanner(
                            trip: state.activeTrip!,
                            onTap: () =>
                                _openActiveTrip(context, state.activeTrip!.id),
                          ),
                        ],
                        Gap(24.h),
                        Text(
                          'available_trips'.tr(),
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
                        else
                          _AvailableTripsSection(
                            onTripTap: (trip) => _openTrip(context, trip),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// تابات الاستلام والتسليم وتحتها الرحلات المتاحة أو حالة فاضية / خطأ
class _AvailableTripsSection extends StatelessWidget {
  final ValueChanged<DeliveryTripModel> onTripTap;

  const _AvailableTripsSection({required this.onTripTap});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AvailableTripsCubit>();

    return BlocBuilder<AvailableTripsCubit, BaseState<DeliveryTripModel>>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TripTypeTabs(selected: cubit.type, onChanged: cubit.changeType),
            Gap(12.h),
            ..._content(context, cubit, state),
          ],
        );
      },
    );
  }

  List<Widget> _content(
    BuildContext context,
    AvailableTripsCubit cubit,
    BaseState<DeliveryTripModel> state,
  ) {
    if ((state.isLoading || state.isInitial) && state.items.isEmpty) {
      return [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 32.h),
          child: const Center(child: CircularProgressIndicator()),
        ),
      ];
    }

    if (state.isFailure && state.items.isEmpty) {
      final needsSettings =
          cubit.locationStatus == LocationStatus.deniedForever ||
          cubit.locationStatus == LocationStatus.serviceDisabled;
      return [
        _TripsError(
          message: state.errorMessage ?? '',
          actionLabel: needsSettings ? 'open_settings' : 'try_again',
          onAction: needsSettings ? cubit.openLocationSettings : cubit.refresh,
        ),
      ];
    }

    if (state.items.isEmpty) {
      return const [
        HomeEmptyState(
          emoji: '📦',
          titleKey: 'no_available_trips',
          subtitleKey: 'no_available_trips_hint',
        ),
      ];
    }

    return [
      for (final trip in state.items)
        Padding(
          padding: EdgeInsets.only(bottom: 12.h),
          child: AvailableTripCard(trip: trip, onTap: () => onTripTap(trip)),
        ),
      if (state.isLoadingMore)
        const Center(child: CircularProgressIndicator())
      else if (state.isLoadingMoreFauilare)
        TextButton(
          onPressed: () => cubit.fetch(page: state.page),
          child: Text('try_again'.tr()),
        ),
    ];
  }
}

class _TripsError extends StatelessWidget {
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  const _TripsError({
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return HomeCard(
      padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 24.h),
      child: Column(
        children: [
          Text('📍', style: TextStyle(fontSize: 40.sp)),
          Gap(12.h),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyles.boldStyle(
              14,
              color: AppColors.greyColor,
              weight: FontWeight.w400,
            ),
          ),
          Gap(8.h),
          TextButton(onPressed: onAction, child: Text(actionLabel.tr())),
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
