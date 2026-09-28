import 'package:easy_localization/easy_localization.dart';
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
import 'package:lavanderia_delivery/features/auth/logout/presentation/logic/logout_bloc.dart';
import 'package:lavanderia_delivery/features/auth/logout/presentation/logic/logout_event.dart';
import 'package:lavanderia_delivery/features/home/presentation/view/widget/home_colors.dart';
import 'package:lavanderia_delivery/features/profile/models/driver_profile_model.dart';
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

  // TODO: هتتجاب من بيانات المندوب لما الـ API يجهز
  DriverProfileModel _profile = const DriverProfileModel(
    name: 'أحمد محمد علي',
    phone: '01012345678',
    email: 'ahmed@example.com',
    address: 'مدينة نصر، القاهرة',
  );
  static const String _vehicleModel = 'تويوتا كورولا 2020';
  static const String _plateNumber = 'أ ب ج 123';
  static const String _vehicleColor = 'أبيض';

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<LogoutBloc>(),
      child: BlocListener<LogoutBloc, BaseState<void>>(
        listener: (context, state) {
          if (state.isSuccess) context.go(AppRouter.login);
        },
        child: Scaffold(
          backgroundColor: AppColors.backgroundColor,
          body: Column(
            children: [
              ProfileHeader(
                name: _profile.name,
                phone: _profile.phone,
                image: _profile.image,
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 24.h),
                  children: [
                    const VehicleCard(
                      model: _vehicleModel,
                      plateNumber: _plateNumber,
                      color: _vehicleColor,
                    ),
                    Gap(16.h),
                    ProfileMenuCard(items: _menuItems(context)),
                    Gap(16.h),
                    BlocBuilder<LogoutBloc, BaseState<void>>(
                      builder: (context, state) => ProfileLogoutButton(
                        isLoading: state.isLoading,
                        onTap: () => _confirmLogout(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// بيفتح شاشة التعديل وبيستنى البيانات الجديدة ترجع منها عشان الهيدر يتحدث
  Future<void> _openEditProfile() async {
    final updated = await context.push<DriverProfileModel>(
      AppRouter.updateProfileScreen,
      extra: _profile,
    );
    if (updated != null && mounted) setState(() => _profile = updated);
  }

  List<ProfileMenuItem> _menuItems(BuildContext context) => [
    ProfileMenuItem(
      emoji: '✏️',
      titleKey: 'edit_profile',
      onTap: _openEditProfile,
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
    final shouldLogout = await showDialog<bool>(
      context: blocContext,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.whiteColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Text('logout'.tr(), style: TextStyles.boldStyle(17)),
        content: Text(
          'logout_confirm'.tr(),
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
              'logout'.tr(),
              style: TextStyles.boldStyle(14, color: HomeColors.red),
            ),
          ),
        ],
      ),
    );

    // الـ bloc بيبعت الـ refreshToken للباك ويمسح الكاش،
    // والتوجيه للوجين بيحصل في الـ BlocListener
    if (shouldLogout == true && blocContext.mounted) {
      blocContext.read<LogoutBloc>().add(const LogoutEvent());
    }
  }
}
