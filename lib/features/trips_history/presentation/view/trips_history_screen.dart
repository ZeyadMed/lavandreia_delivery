import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:lavanderia_delivery/core/bloc/base_bloc.dart';
import 'package:lavanderia_delivery/core/router/app_router.dart';
import 'package:lavanderia_delivery/core/service_locator/service_locator.dart';
import 'package:lavanderia_delivery/core/style/app_colors.dart';
import 'package:lavanderia_delivery/core/theme/text_styles.dart';
import 'package:lavanderia_delivery/features/home/presentation/view/widget/home_colors.dart';
import 'package:lavanderia_delivery/features/home/presentation/view/widget/home_widgets.dart';
import 'package:lavanderia_delivery/features/trips/models/delivery_trip_model.dart';
import 'package:lavanderia_delivery/features/trips/presentation/view/widget/trip_widgets.dart';
import 'package:lavanderia_delivery/features/trips_history/presentation/logic/my_trips_cubit.dart';

/// فلتر الشاشة، بيتطبق على اللي اتحمل لأن الـ API مفيهوش فلتر بالحالة
enum TripsFilter { active, completed, failed, cancelled }

extension on TripsFilter {
  String get labelKey => switch (this) {
    TripsFilter.active => 'trip_active',
    TripsFilter.completed => 'trip_completed',
    TripsFilter.failed => 'trip_failed',
    TripsFilter.cancelled => 'trip_cancelled',
  };

  bool matches(DeliveryTripModel trip) => switch (this) {
    TripsFilter.active => trip.isActive,
    TripsFilter.completed => trip.stage == TripStage.completed,
    TripsFilter.failed => trip.stage == TripStage.failed,
    TripsFilter.cancelled => trip.stage == TripStage.cancelled,
  };
}

class TripsHistoryScreen extends StatefulWidget {
  const TripsHistoryScreen({super.key});

  @override
  State<TripsHistoryScreen> createState() => _TripsHistoryScreenState();
}

class _TripsHistoryScreenState extends State<TripsHistoryScreen> {
  /// null = الكل
  TripsFilter? _selectedFilter;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<MyTripsCubit>()
        ..initPagination()
        ..fetch(page: 1),
      child: Scaffold(
        backgroundColor: AppColors.backgroundColor,
        body: Column(
          children: [
            const _TripsHeader(),
            Gap(20.h),
            _TripsFilterBar(
              selected: _selectedFilter,
              onChanged: (filter) => setState(() => _selectedFilter = filter),
            ),
            Expanded(
              child: BlocBuilder<MyTripsCubit, BaseState<DeliveryTripModel>>(
                builder: (context, state) =>
                    _TripsList(state: state, filter: _selectedFilter),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TripsList extends StatelessWidget {
  final BaseState<DeliveryTripModel> state;
  final TripsFilter? filter;

  const _TripsList({required this.state, required this.filter});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<MyTripsCubit>();

    if (state.isLoading && state.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final filter = this.filter;
    final trips = filter == null
        ? state.items
        : state.items.where(filter.matches).toList();

    if (trips.isEmpty) {
      // ListView عشان الـ RefreshIndicator يشتغل حتى والليستة فاضية
      return RefreshIndicator(
        onRefresh: cubit.refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 24.h),
          children: [
            if (state.isFailure)
              _ErrorCard(
                message: state.errorMessage ?? '',
                onRetry: cubit.refresh,
              )
            else
              const HomeEmptyState(
                emoji: '🚗',
                titleKey: 'no_trips',
                subtitleKey: 'no_trips_hint',
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
        itemCount: trips.length + (showLoadMore ? 1 : 0),
        separatorBuilder: (_, _) => Gap(14.h),
        itemBuilder: (context, index) {
          if (index == trips.length) {
            return state.isLoadingMore
                ? const Center(child: CircularProgressIndicator())
                : TextButton(
                    onPressed: () => cubit.fetch(page: state.page),
                    child: Text('try_again'.tr()),
                  );
          }
          final trip = trips[index];
          return TripCard(
            trip: trip,
            onTap: trip.isActive
                ? () async {
                    await context.push(AppRouter.activeTrip, extra: trip.id);
                    cubit.refresh();
                  }
                : null,
          );
        },
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorCard({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return HomeCard(
      padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 24.h),
      child: Column(
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
          Gap(8.h),
          TextButton(onPressed: onRetry, child: Text('try_again'.tr())),
        ],
      ),
    );
  }
}

class _TripsHeader extends StatelessWidget {
  const _TripsHeader();

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
            'trips'.tr(),
            style: TextStyles.boldStyle(22, color: AppColors.whiteColor),
          ),
        ),
      ),
    );
  }
}

class _TripsFilterBar extends StatelessWidget {
  final TripsFilter? selected;
  final ValueChanged<TripsFilter?> onChanged;

  const _TripsFilterBar({required this.selected, required this.onChanged});

  static const List<TripsFilter?> _filters = [null, ...TripsFilter.values];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        itemCount: _filters.length,
        separatorBuilder: (_, _) => Gap(8.w),
        itemBuilder: (context, index) {
          final filter = _filters[index];
          return _FilterChip(
            label: filter == null ? 'all'.tr() : filter.labelKey.tr(),
            isSelected: filter == selected,
            onTap: () => onChanged(filter),
          );
        },
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(50.r);
    return Material(
      color: isSelected ? AppColors.primaryColor : AppColors.whiteColor,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 18.w),
          child: Center(
            child: Text(
              label,
              style: TextStyles.boldStyle(
                14,
                color: isSelected ? AppColors.whiteColor : AppColors.blackColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// كارت الرحلة: الحالة + رقم الطلب + نوع الرحلة + المسار + الرسوم + التاريخ
class TripCard extends StatelessWidget {
  final DeliveryTripModel trip;
  final VoidCallback? onTap;

  const TripCard({super.key, required this.trip, this.onTap});

  String _formatDate(BuildContext context, DateTime date) {
    final month = DateFormat.MMMM(context.locale.languageCode).format(date);
    return '${date.day} $month ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final date = trip.completedAt ?? trip.createdAt;
    return HomeCard(
      onTap: onTap,
      padding: EdgeInsets.all(18.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              TripStageBadge(stage: trip.stage),
              const Spacer(),
              Text(
                trip.displayNumber,
                textDirection: TextDirection.ltr,
                style: TextStyles.boldStyle(14, color: AppColors.blackColor),
              ),
            ],
          ),
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
          Gap(12.h),
          Row(
            children: [
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

class TripStageBadge extends StatelessWidget {
  final TripStage stage;

  const TripStageBadge({super.key, required this.stage});

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg, String key) = switch (stage) {
      TripStage.completed => (
        HomeColors.lightGreen,
        HomeColors.green,
        'trip_completed',
      ),
      TripStage.failed => (
        const Color(0xffFDECEC),
        HomeColors.red,
        'trip_failed',
      ),
      TripStage.cancelled => (
        HomeColors.cardGrey,
        AppColors.greyColor,
        'trip_cancelled',
      ),
      _ => (HomeColors.lightBlue, AppColors.primaryColor, 'trip_active'),
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
