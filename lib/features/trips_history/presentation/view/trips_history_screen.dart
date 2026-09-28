import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:lavanderia_delivery/core/style/app_colors.dart';
import 'package:lavanderia_delivery/core/theme/text_styles.dart';
import 'package:lavanderia_delivery/features/home/presentation/view/widget/home_colors.dart';
import 'package:lavanderia_delivery/features/home/presentation/view/widget/home_widgets.dart';
import 'package:lavanderia_delivery/features/trips_history/models/trip_model.dart';

class TripsHistoryScreen extends StatefulWidget {
  const TripsHistoryScreen({super.key});

  @override
  State<TripsHistoryScreen> createState() => _TripsHistoryScreenState();
}

class _TripsHistoryScreenState extends State<TripsHistoryScreen> {
  // TODO: هتتجاب من الـ API لما يجهز
  static final List<TripModel> _trips = [
    TripModel(
      orderNumber: 'ORD-10245',
      customerName: 'أحمد محمد',
      laundryName: 'مغسلة المدينة',
      destination: 'مصر الجديدة',
      price: 75,
      date: DateTime(2026, 9, 23),
      status: TripStatus.completed,
    ),
    TripModel(
      orderNumber: 'ORD-10244',
      customerName: 'سارة أحمد',
      laundryName: 'مغسلة النيل',
      destination: 'المعادي',
      price: 60,
      date: DateTime(2026, 9, 22),
      status: TripStatus.completed,
    ),
    TripModel(
      orderNumber: 'ORD-10243',
      customerName: 'محمد علي',
      laundryName: 'مغسلة الأمل',
      destination: 'المهندسين',
      price: 0,
      date: DateTime(2026, 9, 21),
      status: TripStatus.rejected,
    ),
    TripModel(
      orderNumber: 'ORD-10242',
      customerName: 'ليلى حسن',
      laundryName: 'مغسلة الوطن',
      destination: 'الزمالك',
      price: 0,
      date: DateTime(2026, 9, 20),
      status: TripStatus.cancelled,
    ),
  ];

  /// null = الكل
  TripStatus? _selectedStatus;

  List<TripModel> get _filteredTrips => _selectedStatus == null
      ? _trips
      : _trips.where((trip) => trip.status == _selectedStatus).toList();

  @override
  Widget build(BuildContext context) {
    final trips = _filteredTrips;
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: Column(
        children: [
          const _TripsHeader(),
          Gap(20.h),
          _TripsFilterBar(
            selected: _selectedStatus,
            onChanged: (status) => setState(() => _selectedStatus = status),
          ),
          Expanded(
            child: trips.isEmpty
                ? ListView(
                    padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 24.h),
                    children: const [
                      HomeEmptyState(
                        emoji: '🚗',
                        titleKey: 'no_trips',
                        subtitleKey: 'no_trips_hint',
                      ),
                    ],
                  )
                : ListView.separated(
                    padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 24.h),
                    itemCount: trips.length,
                    separatorBuilder: (_, _) => Gap(14.h),
                    itemBuilder: (context, index) =>
                        TripCard(trip: trips[index]),
                  ),
          ),
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
  final TripStatus? selected;
  final ValueChanged<TripStatus?> onChanged;

  const _TripsFilterBar({required this.selected, required this.onChanged});

  static const List<TripStatus?> _filters = [null, ...TripStatus.values];

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
          final status = _filters[index];
          return _FilterChip(
            label: status == null ? 'all'.tr() : status.labelKey.tr(),
            isSelected: status == selected,
            onTap: () => onChanged(status),
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

/// كارت الرحلة: الحالة + رقم الطلب + العميل + المسار + السعر + التاريخ
class TripCard extends StatelessWidget {
  final TripModel trip;
  final VoidCallback? onTap;

  const TripCard({super.key, required this.trip, this.onTap});

  String _formatDate(BuildContext context) {
    final month = DateFormat.MMMM(context.locale.languageCode)
        .format(trip.date);
    return '${trip.date.day} $month ${trip.date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return HomeCard(
      onTap: onTap,
      padding: EdgeInsets.all(18.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              TripStatusBadge(status: trip.status),
              const Spacer(),
              Text(
                '#${trip.orderNumber}',
                textDirection: TextDirection.ltr,
                style: TextStyles.boldStyle(14, color: AppColors.blackColor),
              ),
            ],
          ),
          Gap(12.h),
          Text(
            trip.customerName,
            style: TextStyles.boldStyle(16, color: AppColors.blackColor),
          ),
          Gap(6.h),
          Text(
            '${trip.laundryName} ← ${trip.destination}',
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
                '${trip.price.toStringAsFixed(2)} ${'currency'.tr()}',
                style: TextStyles.boldStyle(16, color: HomeColors.green),
              ),
              const Spacer(),
              Text(
                _formatDate(context),
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

class TripStatusBadge extends StatelessWidget {
  final TripStatus status;

  const TripStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg) = switch (status) {
      TripStatus.completed => (HomeColors.lightGreen, HomeColors.green),
      TripStatus.rejected => (const Color(0xffFDECEC), HomeColors.red),
      TripStatus.cancelled => (HomeColors.cardGrey, AppColors.greyColor),
    };
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Text(
        status.labelKey.tr(),
        style: TextStyles.boldStyle(12, color: fg),
      ),
    );
  }
}

extension TripStatusX on TripStatus {
  String get labelKey => switch (this) {
    TripStatus.completed => 'trip_completed',
    TripStatus.rejected => 'trip_rejected',
    TripStatus.cancelled => 'trip_cancelled',
  };
}
