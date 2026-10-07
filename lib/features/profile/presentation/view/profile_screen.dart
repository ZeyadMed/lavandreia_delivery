import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:lavanderia_delivery/core/bloc/base_bloc.dart';
import 'package:lavanderia_delivery/core/common_widget/label.dart';
import 'package:lavanderia_delivery/core/extensions/context_extension.dart';
import 'package:lavanderia_delivery/core/router/app_router.dart';
import 'package:lavanderia_delivery/core/service_locator/service_locator.dart';
import 'package:lavanderia_delivery/core/style/app_colors.dart';
import 'package:lavanderia_delivery/core/theme/text_styles.dart';
import 'package:lavanderia_delivery/features/auth/logout/presentation/logic/logout_bloc.dart';
import 'package:lavanderia_delivery/features/auth/logout/presentation/logic/logout_event.dart';
import 'package:lavanderia_delivery/features/auth/register/models/register_form_data.dart';
import 'package:lavanderia_delivery/features/home/presentation/view/widget/home_colors.dart';
import 'package:lavanderia_delivery/features/profile/models/driver_profile_model.dart';
import 'package:lavanderia_delivery/features/profile/presentation/logic/delete_account_cubit.dart';
import 'package:lavanderia_delivery/features/profile/presentation/logic/profile_cubit.dart';
import 'package:lavanderia_delivery/features/profile/presentation/view/widget/profile_widgets.dart';

/// شاشة حسابي: هيدر فيه بيانات المندوب، كارت المركبة، القايمة، وزرار الخروج
class ProfileScreen extends StatefulWidget {
  /// بيتنادى لما المستخدم يختار صفحة موجودة في البوتوم ناف
  /// (الرحلات أو الإشعارات) عشان نبدّل التاب بدل ما نفتح صفحة جديدة
  final ValueChanged<int>? onOpenTab;

  const ProfileScreen({super.key, this.onOpenTab});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // ترتيب التابات في البوتوم ناف
  static const int _tripsTabIndex = 1;
  static const int _notificationsTabIndex = 2;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<LogoutBloc>()),
        BlocProvider(create: (_) => getIt<DeleteAccountCubit>()),
        BlocProvider(create: (_) => getIt<ProfileCubit>()..getProfile()),
      ],
      child: MultiBlocListener(
        listeners: [
          BlocListener<LogoutBloc, BaseState<void>>(
            listener: (context, state) {
              if (state.isSuccess) context.go(AppRouter.login);
            },
          ),
          BlocListener<DeleteAccountCubit, BaseState<void>>(
            listener: (context, state) {
              if (state.isSuccess) {
                context.showSuccessMessage('account_deleted'.tr());
                context.go(AppRouter.login);
              }
              if (state.isFailure) {
                context.showErrorMessage(state.errorMessage ?? '');
              }
            },
          ),
        ],
        child: Scaffold(
          backgroundColor: AppColors.backgroundColor,
          body: BlocBuilder<ProfileCubit, BaseState<DriverProfileModel>>(
            builder: (context, state) {
              final profile = state.data;
              return Column(
                children: [
                  ProfileHeader(
                    name: profile?.fullName ?? '',
                    phone: profile?.phoneNumber ?? '',
                    imageUrl: profile?.profileImageUrl,
                    isVerified: profile?.phoneNumberConfirmed ?? false,
                  ),
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 24.h),
                      children: [
                        if (profile != null)
                          VehicleCard(
                            model: [
                              profile.vehicleMake,
                              profile.vehicleModel,
                              if (profile.vehicleYear > 0)
                                '${profile.vehicleYear}',
                            ].join(' '),
                            plateNumber: profile.plateNumber,
                            color: _vehicleColorLabel(profile),
                          )
                        else if (state.isFailure)
                          _ProfileLoadError(
                            message: state.errorMessage ?? '',
                            onRetry: () =>
                                context.read<ProfileCubit>().getProfile(),
                          )
                        else
                          const Center(child: CircularProgressIndicator()),
                        Gap(16.h),
                        ProfileMenuCard(items: _menuItems(context, profile)),
                        Gap(16.h),
                        BlocBuilder<LogoutBloc, BaseState<void>>(
                          builder: (context, state) => ProfileLogoutButton(
                            isLoading: state.isLoading,
                            onTap: () => _confirmLogout(context),
                          ),
                        ),
                        Gap(8.h),
                        BlocBuilder<DeleteAccountCubit, BaseState<void>>(
                          builder: (context, state) =>
                              ProfileDeleteAccountButton(
                                isLoading: state.isLoading,
                                onTap: () => _confirmDeleteAccount(context),
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  /// الألوان الأساسية بتتحفظ بالـ key فبنترجمها، والـ "لون آخر" بيتعرض زي ما اتكتب
  String _vehicleColorLabel(DriverProfileModel profile) {
    final color = profile.vehicleColorEnum;
    return color == VehicleColor.other
        ? profile.vehicleColor
        : color.labelKey.tr();
  }

  /// بيفتح شاشة التعديل، ولو المندوب حفظ بنجيب البيانات من الباك تاني
  /// عشان اسم المدينة وأي حاجة اتغيرت تتعرض زي ما اتحفظت فعلاً
  Future<void> _openEditProfile(
    BuildContext blocContext,
    DriverProfileModel profile,
  ) async {
    final updated = await context.push<bool>(
      AppRouter.updateProfileScreen,
      extra: profile,
    );
    if (updated == true && blocContext.mounted) {
      blocContext.read<ProfileCubit>().getProfile();
    }
  }

  List<ProfileMenuItem> _menuItems(
    BuildContext context,
    DriverProfileModel? profile,
  ) => [
    ProfileMenuItem(
      emoji: '✏️',
      titleKey: 'edit_profile',
      // مفيش حاجة نعدلها قبل ما البيانات توصل
      onTap: profile == null ? null : () => _openEditProfile(context, profile),
    ),
    ProfileMenuItem(
      emoji: '📋',
      titleKey: 'documents',
      onTap: () => context.push(AppRouter.documentsScreen),
    ),
    ProfileMenuItem(
      emoji: '💰',
      titleKey: 'earnings',
      onTap: () => context.push(AppRouter.earningsScreen),
    ),
    ProfileMenuItem(
      emoji: '🔔',
      titleKey: 'notifications',
      onTap: () => widget.onOpenTab?.call(_notificationsTabIndex),
    ),
    ProfileMenuItem(
      emoji: '🕘',
      titleKey: 'previous_trips',
      onTap: () => widget.onOpenTab?.call(_tripsTabIndex),
    ),
    ProfileMenuItem(
      emoji: '🛡️',
      titleKey: 'privacy_policy',
      onTap: () => context.push(AppRouter.privacyPolicy),
    ),
    ProfileMenuItem(
      emoji: '📞',
      titleKey: 'contact_us',
      onTap: () => context.push(AppRouter.contactUsScreen),
    ),
  ];

  /// بنأكد قبل الخروج عشان مايخرجش بالغلط
  Future<void> _confirmLogout(BuildContext blocContext) async {
    final shouldLogout = await _confirm(
      blocContext,
      titleKey: 'logout',
      messageKey: 'logout_confirm',
      confirmKey: 'logout',
    );

    // الـ bloc بيبعت الـ refreshToken للباك ويمسح الكاش،
    // والتوجيه للوجين بيحصل في الـ BlocListener
    if (shouldLogout && blocContext.mounted) {
      blocContext.read<LogoutBloc>().add(const LogoutEvent());
    }
  }

  /// الحذف نهائي فلازم تأكيد صريح قبل ما نبعت الطلب
  Future<void> _confirmDeleteAccount(BuildContext blocContext) async {
    final shouldDelete = await _confirm(
      blocContext,
      titleKey: 'delete_account',
      messageKey: 'delete_account_confirm',
      confirmKey: 'delete_account',
    );

    // الكيوبت بيمسح الجلسة بعد الحذف، والتوجيه للوجين في الـ BlocListener
    if (shouldDelete && blocContext.mounted) {
      blocContext.read<DeleteAccountCubit>().deleteAccount();
    }
  }

  /// دايلوج تأكيد زرار التأكيد فيه أحمر، بيرجع true لو المستخدم وافق
  Future<bool> _confirm(
    BuildContext context, {
    required String titleKey,
    required String messageKey,
    required String confirmKey,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.whiteColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Text(titleKey.tr(), style: TextStyles.boldStyle(17)),
        content: Text(
          messageKey.tr(),
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
              confirmKey.tr(),
              style: TextStyles.boldStyle(14, color: HomeColors.red),
            ),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }
}

/// بتظهر مكان كارت المركبة لو البيانات ماوصلتش، مع زرار يعيد الطلب
class _ProfileLoadError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ProfileLoadError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        LocalizedLabel(
          text: message,
          textAlign: TextAlign.center,
          style: TextStyles.boldStyle(
            14,
            color: AppColors.greyColor,
            weight: FontWeight.w400,
          ),
        ),
        TextButton(
          onPressed: onRetry,
          child: Text(
            'try_again'.tr(),
            style: TextStyles.boldStyle(14, color: AppColors.primaryColor),
          ),
        ),
      ],
    );
  }
}
