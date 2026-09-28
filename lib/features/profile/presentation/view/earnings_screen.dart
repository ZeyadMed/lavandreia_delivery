import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:lavanderia_delivery/core/style/app_colors.dart';
import 'package:lavanderia_delivery/core/theme/text_styles.dart';
import 'package:lavanderia_delivery/features/home/presentation/view/widget/home_colors.dart';
import 'package:lavanderia_delivery/features/home/presentation/view/widget/home_widgets.dart';

/// أرقام بفواصل الآلاف وبالأرقام الإنجليزي زي باقي التطبيق (3,250)
String _formatAmount(num value) => NumberFormat('#,##0.##', 'en').format(value);

/// شاشة الأرباح: إجمالي الشهر فوق، كروت اليوم والأسبوع والشهر والرحلات،
/// وتحتهم شارت أرباح الأسبوع الحالي
class EarningsScreen extends StatelessWidget {
  const EarningsScreen({super.key});

  // TODO: هتتجاب من الـ API لما يجهز
  static const double _todayEarnings = 250;
  static const double _weekEarnings = 1150;
  static const double _monthEarnings = 3250;
  static const int _completedTrips = 43;

  /// أرباح كل يوم في الأسبوع بالترتيب من السبت للجمعة
  static const List<double> _weekDaysEarnings = [
    150,
    190,
    125,
    250,
    160,
    210,
    190,
  ];

  @override
  Widget build(BuildContext context) {
    final currency = 'currency'.tr();
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: Column(
        children: [
          const _EarningsHeader(total: _monthEarnings),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(16.w, 24.h, 16.w, 24.h),
              children: [
                _StatsRow(
                  children: [
                    _EarningsStatCard(
                      emoji: '🌅',
                      value: '${_formatAmount(_todayEarnings)} $currency',
                      labelKey: 'today',
                    ),
                    _EarningsStatCard(
                      emoji: '📅',
                      value: '${_formatAmount(_weekEarnings)} $currency',
                      labelKey: 'week',
                    ),
                  ],
                ),
                Gap(12.h),
                _StatsRow(
                  children: [
                    _EarningsStatCard(
                      emoji: '🗓️',
                      value: '${_formatAmount(_monthEarnings)} $currency',
                      labelKey: 'month',
                    ),
                    _EarningsStatCard(
                      emoji: '🚗',
                      value: '$_completedTrips ${'trip_unit'.tr()}',
                      labelKey: 'completed_trips',
                    ),
                  ],
                ),
                Gap(24.h),
                const WeeklyEarningsChart(earnings: _weekDaysEarnings),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EarningsHeader extends StatelessWidget {
  final double total;

  const _EarningsHeader({required this.total});

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
          padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 32.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Material(
                color: AppColors.whiteColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12.r),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12.r),
                  onTap: () => context.pop(),
                  child: SizedBox(
                    width: 40.r,
                    height: 40.r,
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 18.sp,
                      color: AppColors.whiteColor,
                    ),
                  ),
                ),
              ),
              Gap(16.h),
              Text(
                'month_total_earnings'.tr(),
                style: TextStyles.boldStyle(
                  14,
                  color: AppColors.whiteColor.withValues(alpha: 0.85),
                  weight: FontWeight.w400,
                ),
              ),
              Gap(6.h),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    _formatAmount(total),
                    style: TextStyles.boldStyle(
                      40,
                      color: AppColors.whiteColor,
                      weight: FontWeight.w900,
                    ),
                  ),
                  Gap(8.w),
                  Text(
                    'currency'.tr(),
                    style: TextStyles.boldStyle(
                      22,
                      color: AppColors.whiteColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// صف فيه كارتين بنفس الطول
class _StatsRow extends StatelessWidget {
  final List<Widget> children;

  const _StatsRow({required this.children});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (int i = 0; i < children.length; i++) ...[
            if (i > 0) Gap(12.w),
            Expanded(child: children[i]),
          ],
        ],
      ),
    );
  }
}

class _EarningsStatCard extends StatelessWidget {
  final String emoji;
  final String value;
  final String labelKey;

  const _EarningsStatCard({
    required this.emoji,
    required this.value,
    required this.labelKey,
  });

  @override
  Widget build(BuildContext context) {
    return HomeCard(
      padding: EdgeInsets.all(16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: TextStyle(fontSize: 24.sp)),
          Gap(14.h),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              value,
              style: TextStyles.boldStyle(18, color: AppColors.blackColor),
            ),
          ),
          Gap(4.h),
          Text(
            labelKey.tr(),
            style: TextStyles.boldStyle(
              13,
              color: AppColors.greyColor,
              weight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

/// شارت أعمدة لأرباح الأسبوع الحالي (من السبت للجمعة)
/// عمود النهارده متلوّن بالأزرق الغامق، والضغط على أي عمود بيعرض قيمته فوقه
class WeeklyEarningsChart extends StatefulWidget {
  /// 7 قيم بالترتيب من السبت للجمعة
  final List<double> earnings;

  const WeeklyEarningsChart({super.key, required this.earnings});

  static const List<String> _dayKeys = [
    'saturday',
    'sunday',
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
  ];

  @override
  State<WeeklyEarningsChart> createState() => _WeeklyEarningsChartState();
}

class _WeeklyEarningsChartState extends State<WeeklyEarningsChart> {
  static const Color _barColor = Color(0xffC9D6F5);

  /// ترتيب النهارده في الأسبوع اللي بيبدأ بالسبت
  /// (DateTime.weekday: الاثنين = 1 ... الأحد = 7، والسبت = 6)
  final int _todayIndex = (DateTime.now().weekday + 1) % 7;
  late int _selectedIndex = _todayIndex;

  @override
  Widget build(BuildContext context) {
    final earnings = widget.earnings;
    final maxValue = earnings.reduce((a, b) => a > b ? a : b);
    final chartHeight = 120.h;

    return HomeCard(
      padding: EdgeInsets.fromLTRB(16.w, 18.h, 16.w, 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'current_week_earnings'.tr(),
            style: TextStyles.boldStyle(16, color: AppColors.blackColor),
          ),
          Gap(8.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (int i = 0; i < earnings.length; i++) ...[
                if (i > 0) Gap(8.w),
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => setState(() => _selectedIndex = i),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // القيمة بتظهر فوق العمود المختار بس
                        SizedBox(
                          height: 20.h,
                          child: i == _selectedIndex
                              ? FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    _formatAmount(earnings[i]),
                                    style: TextStyles.boldStyle(
                                      11,
                                      color: AppColors.blackColor,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                        Gap(4.h),
                        SizedBox(
                          height: chartHeight,
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              height: maxValue == 0
                                  ? 4
                                  : (earnings[i] / maxValue * chartHeight)
                                        .clamp(4, chartHeight),
                              decoration: BoxDecoration(
                                color: i == _todayIndex
                                    ? AppColors.primaryColor
                                    : _barColor,
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(6.r),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Gap(8.h),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            WeeklyEarningsChart._dayKeys[i].tr(),
                            maxLines: 1,
                            style: TextStyles.boldStyle(
                              10,
                              color: i == _selectedIndex
                                  ? AppColors.blackColor
                                  : AppColors.greyColor4,
                              weight: i == _selectedIndex
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
