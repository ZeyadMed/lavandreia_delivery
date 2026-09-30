import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:lavanderia_delivery/core/bloc/base_bloc.dart';
import 'package:lavanderia_delivery/core/service_locator/service_locator.dart';
import 'package:lavanderia_delivery/core/style/app_colors.dart';
import 'package:lavanderia_delivery/core/theme/text_styles.dart';
import 'package:lavanderia_delivery/features/home/presentation/view/widget/home_colors.dart';
import 'package:lavanderia_delivery/features/home/presentation/view/widget/home_widgets.dart';
import 'package:lavanderia_delivery/features/wallet/models/wallet_model.dart';
import 'package:lavanderia_delivery/features/wallet/models/wallet_transaction_model.dart';
import 'package:lavanderia_delivery/features/wallet/presentation/logic/wallet_cubit.dart';
import 'package:lavanderia_delivery/features/wallet/presentation/logic/wallet_transactions_cubit.dart';

/// أرقام بفواصل الآلاف وبالأرقام الإنجليزي زي باقي التطبيق (3,250)
String _formatAmount(num value) => NumberFormat('#,##0.##', 'en').format(value);

/// شاشة الأرباح: رصيد المحفظة فوق، كروت اليوم والأسبوع والشهر والرحلات،
/// وتحتهم شارت أرباح الأسبوع الحالي وحركات المحفظة
class EarningsScreen extends StatelessWidget {
  const EarningsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<WalletCubit>()..getWallet()),
        BlocProvider(
          create: (_) => getIt<WalletTransactionsCubit>()
            ..initPagination()
            ..fetch(page: 1),
        ),
      ],
      child: const _EarningsView(),
    );
  }
}

class _EarningsView extends StatelessWidget {
  const _EarningsView();

  Future<void> _refresh(BuildContext context) async {
    await Future.wait([
      context.read<WalletCubit>().getWallet(),
      context.read<WalletTransactionsCubit>().refresh(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final currency = 'currency'.tr();
    final transactionsCubit = context.read<WalletTransactionsCubit>();

    return BlocBuilder<WalletCubit, BaseState<WalletModel>>(
      builder: (context, walletState) {
        return BlocBuilder<
          WalletTransactionsCubit,
          BaseState<WalletTransactionModel>
        >(
          builder: (context, txState) {
            final summary = _EarningsSummary.from(
              walletState.data,
              txState.items,
            );
            return Scaffold(
              backgroundColor: AppColors.backgroundColor,
              body: Column(
                children: [
                  _EarningsHeader(
                    total: walletState.data?.balance ?? 0,
                    isLoading: walletState.isLoading && !walletState.hasData,
                  ),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () => _refresh(context),
                      child: ListView(
                        controller: transactionsCubit.scrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(16.w, 24.h, 16.w, 24.h),
                        children: [
                          if (walletState.isFailure && !walletState.hasData)
                            Padding(
                              padding: EdgeInsets.only(bottom: 16.h),
                              child: Text(
                                walletState.errorMessage ?? '',
                                textAlign: TextAlign.center,
                                style: TextStyles.boldStyle(
                                  13,
                                  color: HomeColors.red,
                                  weight: FontWeight.w400,
                                ),
                              ),
                            ),
                          _StatsRow(
                            children: [
                              _EarningsStatCard(
                                emoji: '🌅',
                                value:
                                    '${_formatAmount(summary.today)} $currency',
                                labelKey: 'today',
                              ),
                              _EarningsStatCard(
                                emoji: '📅',
                                value:
                                    '${_formatAmount(summary.week)} $currency',
                                labelKey: 'week',
                              ),
                            ],
                          ),
                          Gap(12.h),
                          _StatsRow(
                            children: [
                              _EarningsStatCard(
                                emoji: '🗓️',
                                value:
                                    '${_formatAmount(summary.month)} $currency',
                                labelKey: 'month',
                              ),
                              _EarningsStatCard(
                                emoji: '🚗',
                                value: '${summary.trips} ${'trip_unit'.tr()}',
                                labelKey: 'completed_trips',
                              ),
                            ],
                          ),
                          Gap(24.h),
                          WeeklyEarningsChart(earnings: summary.weekDays),
                          Gap(24.h),
                          Text(
                            'wallet_transactions'.tr(),
                            style: TextStyles.boldStyle(
                              16,
                              color: AppColors.blackColor,
                            ),
                          ),
                          Gap(12.h),
                          ..._transactions(context, txState),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  List<Widget> _transactions(
    BuildContext context,
    BaseState<WalletTransactionModel> state,
  ) {
    final cubit = context.read<WalletTransactionsCubit>();
    if (state.isLoading && state.items.isEmpty) {
      return const [Center(child: CircularProgressIndicator())];
    }
    if (state.items.isEmpty) {
      return [
        if (state.isFailure)
          TextButton(onPressed: cubit.refresh, child: Text('try_again'.tr()))
        else
          const HomeEmptyState(
            emoji: '💳',
            titleKey: 'no_transactions',
            subtitleKey: 'no_transactions_hint',
          ),
      ];
    }
    return [
      for (final transaction in state.items)
        Padding(
          padding: EdgeInsets.only(bottom: 10.h),
          child: _TransactionTile(transaction: transaction),
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

/// أرقام الكروت والشارت: من المحفظة لو الباك بيرجعها، ولو لأ بتتحسب
/// من الحركات اللي داخلة المحفظة في الفترة دي
class _EarningsSummary {
  final num today;
  final num week;
  final num month;
  final int trips;

  /// 7 قيم بالترتيب من السبت للجمعة
  final List<double> weekDays;

  const _EarningsSummary({
    required this.today,
    required this.week,
    required this.month,
    required this.trips,
    required this.weekDays,
  });

  factory _EarningsSummary.from(
    WalletModel? wallet,
    List<WalletTransactionModel> transactions,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // الأسبوع بيبدأ بالسبت (DateTime.weekday: السبت = 6)
    final weekStart = today.subtract(Duration(days: (now.weekday + 1) % 7));
    final monthStart = DateTime(now.year, now.month);

    final credits = transactions.where(
      (t) => t.isCredit && t.createdAt != null,
    );
    num sumSince(DateTime from) => credits
        .where((t) => !t.createdAt!.isBefore(from))
        .fold<num>(0, (sum, t) => sum + t.amount);

    final weekDays = List<double>.filled(7, 0);
    for (final t in credits) {
      final day = DateTime(
        t.createdAt!.year,
        t.createdAt!.month,
        t.createdAt!.day,
      );
      final index = day.difference(weekStart).inDays;
      if (index >= 0 && index < 7) weekDays[index] += t.amount.toDouble();
    }

    return _EarningsSummary(
      today: wallet?.todayEarnings ?? sumSince(today),
      week: wallet?.weekEarnings ?? sumSince(weekStart),
      month: wallet?.monthEarnings ?? sumSince(monthStart),
      trips:
          wallet?.completedTrips ??
          credits.where((t) => t.tripId != null).length,
      weekDays: weekDays,
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final WalletTransactionModel transaction;

  const _TransactionTile({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final date = transaction.createdAt;
    final color = transaction.isCredit ? HomeColors.green : HomeColors.red;
    final title = transaction.description.isNotEmpty
        ? transaction.description
        : (transaction.isCredit ? 'trip_fee' : 'withdrawal').tr();
    return HomeCard(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      child: Row(
        children: [
          Container(
            width: 40.r,
            height: 40.r,
            decoration: BoxDecoration(
              color: transaction.isCredit
                  ? HomeColors.lightGreen
                  : const Color(0xffFDECEC),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              transaction.isCredit
                  ? Icons.south_west_rounded
                  : Icons.north_east_rounded,
              color: color,
              size: 20.sp,
            ),
          ),
          Gap(12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyles.boldStyle(14, color: AppColors.blackColor),
                ),
                if (date != null) ...[
                  Gap(4.h),
                  Text(
                    DateFormat('yyyy/MM/dd - hh:mm a', 'en').format(date),
                    textDirection: TextDirection.ltr,
                    style: TextStyles.boldStyle(
                      12,
                      color: AppColors.lightTextColor,
                      weight: FontWeight.w400,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Gap(8.w),
          Text(
            '${transaction.isCredit ? '+' : ''}${_formatAmount(transaction.amount)}',
            textDirection: TextDirection.ltr,
            style: TextStyles.boldStyle(15, color: color),
          ),
        ],
      ),
    );
  }
}

class _EarningsHeader extends StatelessWidget {
  final num total;
  final bool isLoading;

  const _EarningsHeader({required this.total, this.isLoading = false});

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
                'wallet_balance'.tr(),
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
                    isLoading ? '—' : _formatAmount(total),
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
