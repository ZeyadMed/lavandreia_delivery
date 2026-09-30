import 'dart:io';

import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lavanderia_delivery/core/bloc/base_bloc.dart';
import 'package:lavanderia_delivery/core/common_widget/custom_error_message.dart';
import 'package:lavanderia_delivery/core/helpers/image_compress_function.dart';
import 'package:lavanderia_delivery/core/helpers/uri_launcher.dart';
import 'package:lavanderia_delivery/core/service_locator/service_locator.dart';
import 'package:lavanderia_delivery/core/style/app_colors.dart';
import 'package:lavanderia_delivery/core/theme/text_styles.dart';
import 'package:lavanderia_delivery/features/home/presentation/view/widget/home_colors.dart';
import 'package:lavanderia_delivery/features/home/presentation/view/widget/home_widgets.dart';
import 'package:lavanderia_delivery/features/trips/models/delivery_trip_model.dart';
import 'package:lavanderia_delivery/features/trips/presentation/logic/active_trip_cubit.dart';
import 'package:lavanderia_delivery/features/trips/presentation/view/widget/trip_widgets.dart';
import 'package:slide_to_act/slide_to_act.dart';

/// الرحلة الشغالة خطوة بخطوة.
/// Pickup: رايح للعميل ← صور الهدوم واستلام ← OTP للمغسلة ← المغسلة تأكد
/// Dropoff: استلام من المغسلة ← رايح للعميل ← وصلت ← OTP للعميل ← العميل يأكد
class ActiveTripScreen extends StatelessWidget {
  /// null = أول رحلة شغالة متعيّنة علينا
  final int? tripId;

  const ActiveTripScreen({super.key, this.tripId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ActiveTripCubit>()..load(tripId: tripId),
      child: Scaffold(
        backgroundColor: AppColors.backgroundColor,
        body: BlocBuilder<ActiveTripCubit, ActiveTripState>(
          builder: (context, state) {
            return Column(
              children: [
                _TripHeader(trip: state.trip),
                Expanded(child: _TripBody(state: state)),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _TripBody extends StatelessWidget {
  final ActiveTripState state;

  const _TripBody({required this.state});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ActiveTripCubit>();
    final trip = state.trip;

    if (trip == null) {
      if (state.status == Status.failure) {
        return _Message(
          emoji: '🚗',
          message: state.errorMessage ?? '',
          actionLabel: 'try_again',
          onAction: cubit.load,
        );
      }
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: () => cubit.load(silent: true),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 32.h),
        children: [
          _TripSteps(trip: trip, pickedFromLaundry: state.pickedFromLaundry),
          Gap(16.h),
          ...switch ((trip.type, trip.stage)) {
            (_, TripStage.completed) => [_CompletedView(trip: trip)],
            (_, TripStage.cancelled) => [
              const HomeEmptyState(
                emoji: '🚫',
                titleKey: 'trip_cancelled',
                subtitleKey: 'trip_cancelled_hint',
              ),
            ],
            (TripType.pickup, TripStage.collected) => _pickupCollected(trip),
            (TripType.pickup, _) => _pickupAssigned(context, trip),
            (TripType.dropoff, TripStage.arrived) => _dropoffArrived(trip),
            (TripType.dropoff, _) =>
              state.pickedFromLaundry
                  ? _dropoffToCustomer(context, trip)
                  : _dropoffAtLaundry(context, trip),
          },
        ],
      ),
    );
  }

  /// رايح للعميل يصوّر الهدوم ويستلمها
  List<Widget> _pickupAssigned(BuildContext context, DeliveryTripModel trip) {
    final cubit = context.read<ActiveTripCubit>();
    return [
      _PointActionsCard(
        emoji: '📍',
        titleKey: 'go_to_customer',
        point: trip.customer,
        fallbackName: 'customer'.tr(),
      ),
      Gap(16.h),
      _PhotosPicker(
        photos: state.photos,
        enabled: !state.isSubmitting,
        onAdd: (files) => cubit.addPhotos(files),
        onRemove: cubit.removePhoto,
      ),
      Gap(20.h),
      _SlideToConfirm(
        text: 'slide_clothes_collected'.tr(),
        enabled: state.photos.isNotEmpty && !state.isSubmitting,
        isLoading: state.isSubmitting,
        onSubmit: () => _run(context, cubit.collect()),
      ),
    ];
  }

  /// معاه الـ OTP ورايح للمغسلة، والمغسلة هي اللي هتأكد
  List<Widget> _pickupCollected(DeliveryTripModel trip) {
    return [
      _OtpCard(code: trip.otpCode, hintKey: 'show_otp_to_laundry'),
      Gap(16.h),
      _PointActionsCard(
        emoji: '🧺',
        titleKey: 'go_to_laundry',
        point: trip.laundry,
        fallbackName: 'laundry'.tr(),
      ),
      Gap(16.h),
      const _WaitingCard(textKey: 'waiting_laundry_confirmation'),
    ];
  }

  /// رحلة التسليم: رايح المغسلة ياخد الهدوم. مفيش API للخطوة دي
  List<Widget> _dropoffAtLaundry(BuildContext context, DeliveryTripModel trip) {
    final cubit = context.read<ActiveTripCubit>();
    return [
      _PointActionsCard(
        emoji: '🧺',
        titleKey: 'go_to_laundry_pickup',
        point: trip.laundry,
        fallbackName: 'laundry'.tr(),
      ),
      Gap(20.h),
      SizedBox(
        height: 54.h,
        child: ElevatedButton(
          onPressed: cubit.markPickedFromLaundry,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryColor,
            foregroundColor: AppColors.whiteColor,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.r),
            ),
          ),
          child: Text(
            'received_from_laundry'.tr(),
            style: TextStyles.boldStyle(16, color: AppColors.whiteColor),
          ),
        ),
      ),
    ];
  }

  List<Widget> _dropoffToCustomer(
    BuildContext context,
    DeliveryTripModel trip,
  ) {
    final cubit = context.read<ActiveTripCubit>();
    return [
      _PointActionsCard(
        emoji: '🏠',
        titleKey: 'go_to_customer',
        point: trip.customer,
        fallbackName: 'customer'.tr(),
      ),
      Gap(12.h),
      const _InfoNote(textKey: 'no_cash_collection'),
      Gap(20.h),
      _SlideToConfirm(
        text: 'slide_arrived'.tr(),
        enabled: !state.isSubmitting,
        isLoading: state.isSubmitting,
        onSubmit: () => _run(context, cubit.arrive()),
      ),
    ];
  }

  /// عند باب العميل ومعاه OTP العميل هيدخّله في تطبيقه
  List<Widget> _dropoffArrived(DeliveryTripModel trip) {
    return [
      _OtpCard(code: trip.otpCode, hintKey: 'show_otp_to_customer'),
      Gap(16.h),
      _PointActionsCard(
        emoji: '🏠',
        titleKey: 'customer_details',
        point: trip.customer,
        fallbackName: 'customer'.tr(),
        showNavigation: false,
      ),
      Gap(12.h),
      const _InfoNote(textKey: 'no_cash_collection'),
      Gap(16.h),
      const _WaitingCard(textKey: 'waiting_customer_confirmation'),
    ];
  }
}

/// بتستنى العملية ولو رجعت رسالة خطأ بتعرضها
Future<void> _run(BuildContext context, Future<String?> action) async {
  final error = await action;
  if (error != null && context.mounted) {
    CustomErrorOverlay.show(context: context, text: error);
  }
}

class _TripHeader extends StatelessWidget {
  final DeliveryTripModel? trip;

  const _TripHeader({required this.trip});

  @override
  Widget build(BuildContext context) {
    final trip = this.trip;
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
          padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 24.h),
          child: Row(
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
              Gap(14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'current_trip'.tr(),
                      style: TextStyles.boldStyle(
                        20,
                        color: AppColors.whiteColor,
                      ),
                    ),
                    if (trip != null) ...[
                      Gap(2.h),
                      Text(
                        '${trip.type.emoji} ${trip.type.labelKey.tr()} • ${trip.displayNumber}',
                        style: TextStyles.boldStyle(
                          13,
                          color: AppColors.whiteColor.withValues(alpha: 0.85),
                          weight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trip != null)
                Text(
                  '${formatAmount(trip.fee)} ${'currency'.tr()}',
                  style: TextStyles.boldStyle(16, color: AppColors.whiteColor),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// مؤشر الخطوات التلاتة فوق الشاشة
class _TripSteps extends StatelessWidget {
  final DeliveryTripModel trip;
  final bool pickedFromLaundry;

  const _TripSteps({required this.trip, required this.pickedFromLaundry});

  List<String> get _steps => trip.type == TripType.pickup
      ? const ['step_go_to_customer', 'step_collect', 'step_laundry_confirm']
      : const [
          'step_laundry_pickup',
          'step_go_to_customer',
          'step_customer_confirm',
        ];

  int get _current => switch ((trip.type, trip.stage)) {
    (_, TripStage.completed) => 3,
    (TripType.pickup, TripStage.collected) => 2,
    (TripType.pickup, _) => 1,
    (TripType.dropoff, TripStage.arrived) => 2,
    (TripType.dropoff, _) => pickedFromLaundry ? 1 : 0,
  };

  @override
  Widget build(BuildContext context) {
    final steps = _steps;
    final current = _current;
    return HomeCard(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
      child: Row(
        children: [
          for (int i = 0; i < steps.length; i++) ...[
            if (i > 0)
              Expanded(
                child: Container(
                  height: 2,
                  margin: EdgeInsets.only(bottom: 18.h),
                  color: i <= current
                      ? HomeColors.green
                      : AppColors.semiWhiteColor2,
                ),
              ),
            _StepDot(
              index: i,
              label: steps[i].tr(),
              isDone: i < current,
              isCurrent: i == current,
            ),
          ],
        ],
      ),
    );
  }
}

class _StepDot extends StatelessWidget {
  final int index;
  final String label;
  final bool isDone;
  final bool isCurrent;

  const _StepDot({
    required this.index,
    required this.label,
    required this.isDone,
    required this.isCurrent,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDone
        ? HomeColors.green
        : isCurrent
        ? AppColors.primaryColor
        : AppColors.semiWhiteColor2;
    return SizedBox(
      width: 72.w,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 28.r,
            height: 28.r,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: isDone
                ? Icon(Icons.check, size: 16.sp, color: AppColors.whiteColor)
                : Text(
                    '${index + 1}',
                    style: TextStyles.boldStyle(
                      12,
                      color: isCurrent
                          ? AppColors.whiteColor
                          : AppColors.greyColor,
                    ),
                  ),
          ),
          Gap(6.h),
          Text(
            label,
            maxLines: 2,
            textAlign: TextAlign.center,
            style: TextStyles.boldStyle(
              10,
              color: isCurrent ? AppColors.blackColor : AppColors.greyColor,
              weight: isCurrent ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

/// العميل أو المغسلة: الاسم والعنوان وزراير الاتصال والملاحة
class _PointActionsCard extends StatelessWidget {
  final String emoji;
  final String titleKey;
  final TripPoint point;
  final String fallbackName;
  final bool showNavigation;

  const _PointActionsCard({
    required this.emoji,
    required this.titleKey,
    required this.point,
    required this.fallbackName,
    this.showNavigation = true,
  });

  Future<void> _launch(
    BuildContext context,
    Future<void> Function() action,
  ) async {
    try {
      await action();
    } catch (_) {
      if (context.mounted) {
        CustomErrorOverlay.show(context: context, text: 'cannot_open_app'.tr());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final canNavigate = showNavigation && point.hasLocation;
    return HomeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$emoji ${titleKey.tr()}',
            style: TextStyles.boldStyle(13, color: AppColors.primaryColor),
          ),
          Gap(10.h),
          Text(
            point.name.isNotEmpty ? point.name : fallbackName,
            style: TextStyles.boldStyle(16, color: AppColors.blackColor),
          ),
          if (point.address.isNotEmpty) ...[
            Gap(4.h),
            Text(
              point.address,
              style: TextStyles.boldStyle(
                13,
                color: AppColors.greyColor,
                weight: FontWeight.w400,
              ),
            ),
          ],
          if (point.phone.isNotEmpty || canNavigate) ...[
            Gap(14.h),
            Row(
              children: [
                if (point.phone.isNotEmpty)
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.call_rounded,
                      label: 'call'.tr(),
                      color: HomeColors.green,
                      onTap: () => _launch(
                        context,
                        () => UriLauncher.launchPhone(point.phone),
                      ),
                    ),
                  ),
                if (point.phone.isNotEmpty && canNavigate) Gap(10.w),
                if (canNavigate)
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.navigation_rounded,
                      label: 'start_navigation'.tr(),
                      color: AppColors.primaryColor,
                      onTap: () => _launch(
                        context,
                        () => UriLauncher.launchNavigation(
                          point.latitude!,
                          point.longitude!,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44.h,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18.sp, color: color),
        label: Text(label, style: TextStyles.boldStyle(13, color: color)),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: color, width: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
      ),
    );
  }
}

/// صور الهدوم قبل الاستلام، بتتبعت مع collect وبتتعرض للمغسلة وقت المطابقة
class _PhotosPicker extends StatelessWidget {
  final List<File> photos;
  final bool enabled;
  final ValueChanged<List<File>> onAdd;
  final ValueChanged<int> onRemove;

  const _PhotosPicker({
    required this.photos,
    required this.enabled,
    required this.onAdd,
    required this.onRemove,
  });

  Future<void> _pick(BuildContext context) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.whiteColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(
                Icons.camera_alt,
                color: AppColors.primaryColor,
              ),
              title: Text('takePhoto'.tr(), style: TextStyles.darkBold16),
              onTap: () => Navigator.of(sheetContext).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library,
                color: AppColors.primaryColor,
              ),
              title: Text(
                'chooseFromGallery'.tr(),
                style: TextStyles.darkBold16,
              ),
              onTap: () => Navigator.of(sheetContext).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    final picker = ImagePicker();
    final picked = source == ImageSource.camera
        ? [?await picker.pickImage(source: source)]
        : await picker.pickMultiImage();
    if (picked.isEmpty) return;

    final compressor = ImageCompressHelper();
    final files = <File>[];
    for (final image in picked) {
      final original = File(image.path);
      try {
        files.add(await compressor.compressFile(original));
      } catch (_) {
        files.add(original);
      }
    }
    onAdd(files);
  }

  @override
  Widget build(BuildContext context) {
    final canAdd = enabled && photos.length < ActiveTripCubit.maxPhotos;
    return HomeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📸 ${'clothes_photos'.tr()}',
            style: TextStyles.boldStyle(13, color: AppColors.primaryColor),
          ),
          Gap(4.h),
          Text(
            'clothes_photos_hint'.tr(),
            style: TextStyles.boldStyle(
              12,
              color: AppColors.greyColor,
              weight: FontWeight.w400,
            ),
          ),
          Gap(12.h),
          Wrap(
            spacing: 10.w,
            runSpacing: 10.h,
            children: [
              for (int i = 0; i < photos.length; i++)
                _PhotoThumb(
                  file: photos[i],
                  onRemove: enabled ? () => onRemove(i) : null,
                ),
              if (canAdd)
                InkWell(
                  borderRadius: BorderRadius.circular(12.r),
                  onTap: () => _pick(context),
                  child: Container(
                    width: 72.r,
                    height: 72.r,
                    decoration: BoxDecoration(
                      color: HomeColors.lightBlue,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(
                      Icons.add_a_photo_outlined,
                      color: AppColors.primaryColor,
                      size: 26.sp,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PhotoThumb extends StatelessWidget {
  final File file;
  final VoidCallback? onRemove;

  const _PhotoThumb({required this.file, this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12.r),
          child: Image.file(file, width: 72.r, height: 72.r, fit: BoxFit.cover),
        ),
        if (onRemove != null)
          PositionedDirectional(
            top: -6,
            end: -6,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  color: HomeColors.red,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.close,
                  size: 14.sp,
                  color: AppColors.whiteColor,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _SlideToConfirm extends StatelessWidget {
  final String text;
  final bool enabled;
  final bool isLoading;
  final Future<void> Function() onSubmit;

  const _SlideToConfirm({
    required this.text,
    required this.enabled,
    required this.isLoading,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return SizedBox(
        height: 64.h,
        child: const Center(child: CircularProgressIndicator()),
      );
    }
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: SlideAction(
        text: text,
        enabled: enabled,
        height: 64.h,
        elevation: 0,
        borderRadius: 18.r,
        outerColor: HomeColors.green,
        innerColor: AppColors.whiteColor,
        sliderButtonIconPadding: 12,
        // في العربي السحب بيبقى من اليمين للشمال
        reversed: Directionality.of(context) == TextDirection.rtl,
        textStyle: TextStyles.boldStyle(15, color: AppColors.whiteColor),
        sliderButtonIcon: Icon(
          Icons.double_arrow_rounded,
          color: HomeColors.green,
          size: 22.sp,
        ),
        onSubmit: onSubmit,
      ),
    );
  }
}

/// الـ OTP بخط كبير عشان المندوب يوريه للمغسلة أو للعميل من الموبايل
class _OtpCard extends StatelessWidget {
  final String? code;
  final String hintKey;

  const _OtpCard({required this.code, required this.hintKey});

  @override
  Widget build(BuildContext context) {
    final code = this.code;
    return HomeCard(
      padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 22.h),
      child: Column(
        children: [
          Text(
            '🔐 ${'otp_code'.tr()}',
            style: TextStyles.boldStyle(14, color: AppColors.primaryColor),
          ),
          Gap(12.h),
          Text(
            code ?? '— — — —',
            textDirection: TextDirection.ltr,
            style: TextStyles.boldStyle(
              38,
              color: AppColors.blackColor,
              weight: FontWeight.w900,
            ).copyWith(letterSpacing: 10),
          ),
          Gap(10.h),
          Text(
            (code == null ? 'otp_not_available' : hintKey).tr(),
            textAlign: TextAlign.center,
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

class _WaitingCard extends StatelessWidget {
  final String textKey;

  const _WaitingCard({required this.textKey});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: HomeColors.lightOrange,
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 18.r,
            height: 18.r,
            child: const CircularProgressIndicator(
              strokeWidth: 2,
              color: HomeColors.orange,
            ),
          ),
          Gap(12.w),
          Expanded(
            child: Text(
              textKey.tr(),
              style: TextStyles.boldStyle(13, color: HomeColors.orange),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoNote extends StatelessWidget {
  final String textKey;

  const _InfoNote({required this.textKey});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: HomeColors.lightBlue,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Text(
        'ℹ️ ${textKey.tr()}',
        style: TextStyles.boldStyle(12, color: AppColors.primaryColor),
      ),
    );
  }
}

class _CompletedView extends StatelessWidget {
  final DeliveryTripModel trip;

  const _CompletedView({required this.trip});

  @override
  Widget build(BuildContext context) {
    return HomeCard(
      padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 32.h),
      child: Column(
        children: [
          Text('✅', style: TextStyle(fontSize: 56.sp)),
          Gap(16.h),
          Text(
            'trip_done'.tr(),
            textAlign: TextAlign.center,
            style: TextStyles.boldStyle(18),
          ),
          Gap(8.h),
          Text(
            'fee_added_to_wallet'.tr(
              args: ['${formatAmount(trip.fee)} ${'currency'.tr()}'],
            ),
            textAlign: TextAlign.center,
            style: TextStyles.boldStyle(14, color: HomeColors.green),
          ),
          Gap(24.h),
          SizedBox(
            width: double.infinity,
            height: 50.h,
            child: ElevatedButton(
              onPressed: () => context.pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: AppColors.whiteColor,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.r),
                ),
              ),
              child: Text(
                'back_to_home'.tr(),
                style: TextStyles.boldStyle(15, color: AppColors.whiteColor),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  final String emoji;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  const _Message({
    required this.emoji,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: TextStyle(fontSize: 48.sp)),
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
            Gap(12.h),
            TextButton(onPressed: onAction, child: Text(actionLabel.tr())),
          ],
        ),
      ),
    );
  }
}
