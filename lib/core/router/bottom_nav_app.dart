import 'package:dio/dio.dart';
import 'package:lavanderia_delivery/core/common_widget/custom_error_message.dart';
import 'package:lavanderia_delivery/core/service_locator/service_locator.dart';
import 'package:lavanderia_delivery/core/style/app_colors.dart';
import 'package:lavanderia_delivery/core/theme/text_styles.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lavanderia_delivery/features/home/presentation/view/home_screen.dart';
import 'package:lavanderia_delivery/features/notifications/presentation/view/notifications_screen.dart';
import 'package:lavanderia_delivery/features/profile/presentation/view/profile_screen.dart';
import 'package:lavanderia_delivery/features/trips_history/presentation/view/trips_history_screen.dart';

class BottomNavApp extends StatefulWidget {
  const BottomNavApp({super.key});

  @override
  State<BottomNavApp> createState() => _BottomNavAppState();
}

class _BottomNavAppState extends State<BottomNavApp> {
  int _selectedIndex = 0;
  DateTime? _lastBackPressed;
  //final List<Widget?> _pages = List.filled(4, null);
  final Map<int, Widget> _cachedPages = {};

  /// الترتيب: الرئيسية - الرحلات - الإشعارات - حسابي
  /// وفي العربي الصف بيتقلب لوحده فالرئيسية بتظهر على اليمين
  final List<_BottomNavItemData> _items = const [
    _BottomNavItemData(
      labelKey: 'home',
      unselectedIcon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
    ),
    _BottomNavItemData(
      labelKey: 'trips',
      unselectedIcon: Icons.east_rounded,
      selectedIcon: Icons.east_rounded,
    ),
    _BottomNavItemData(
      labelKey: 'notifications',
      unselectedIcon: Icons.notifications_none_rounded,
      selectedIcon: Icons.notifications_rounded,
    ),
    _BottomNavItemData(
      labelKey: 'profile',
      unselectedIcon: Icons.person_outline_rounded,
      selectedIcon: Icons.person_rounded,
    ),
  ];

  @override
  void initState() {
    getIt<Dio>().options.headers['Accept-Language'] = 'ar';
    super.initState();
    // Only load home page initially
    _getPage(0);
  }

  Widget _getPage(int index) {
    if (_cachedPages.containsKey(index)) {
      return _cachedPages[index]!;
    }

    Widget page;
    switch (index) {
      case 0:
        page = const HomeScreen();
        break;
      case 1:
        page = const TripsHistoryScreen();
        break;
      case 2:
        page = const NotificationsScreen();
        break;
      case 3:
        page = ProfileScreen(onOpenTab: _onItemTapped);
        break;
      default:
        page = const SizedBox.shrink();
    }

    _cachedPages[index] = page;
    return page;
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _getPage(index);
    });

    // if (index != previousIndex) {
    //   WidgetsBinding.instance.addPostFrameCallback((_) {
    //     if (!mounted) return;
    //     try {
    //       switch (index) {
    //         case 0:
    //           context.read<GetPropertyBloc>().add(
    //                 const LoadFirstPage<GetProperty>(params: null, query: null),
    //               );
    //           break;
    //         case 1:
    //           context.read<GetFavouriteBloc>().add(
    //                 LoadFirstPage<GetFavouriteModel>(params: null, query: null),
    //               );
    //           break;
    //         case 2:
    //           context.read<GetBookingBloc>().add(
    //                 LoadFirstPage<GetBooking>(params: null, query: null),
    //               );
    //           break;
    //       }
    //     } catch (_) {}
    //   });
    // }
  }

  Future<bool> _onWillPop() async {
    if (_selectedIndex != 0) {
      setState(() {
        _selectedIndex = 0;
      });
      return false;
    } else {
      final now = DateTime.now();
      if (_lastBackPressed == null ||
          now.difference(_lastBackPressed!) > const Duration(seconds: 2)) {
        _lastBackPressed = now;
        CustomErrorOverlay.show(context: context, text: "pressAgain".tr());
        return false;
      }
      return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color scaffoldColor = isDarkMode
        ? const Color(0xFF111827)
        : AppColors.backgroundColor;

    final Color navBarColor = isDarkMode
        ? const Color(0xFF111827)
        : AppColors.whiteColor;
    final Color selectedItemColor = isDarkMode
        ? const Color(0xFF8EA2FF)
        : AppColors.primaryColor;
    final Color unselectedItemColor = isDarkMode
        ? const Color(0xFF8B95AA)
        : AppColors.greyColor;

    // Build children list with only loaded pages
    final children = <Widget>[];
    for (int i = 0; i < _items.length; i++) {
      if (_cachedPages.containsKey(i)) {
        children.add(_cachedPages[i]!);
      } else {
        children.add(const SizedBox.shrink());
      }
    }

    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: scaffoldColor,
        body: IndexedStack(index: _selectedIndex, children: children),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: navBarColor,
            border: Border(
              top: BorderSide(
                color: isDarkMode ? Colors.white12 : const Color(0xFFE8ECF3),
              ),
            ),
          ),
          padding: EdgeInsets.only(bottom: 0, left: 4.w, right: 4.w),
          child: SafeArea(
            top: false,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(_items.length, (index) {
                final isSelected = _selectedIndex == index;
                final item = _items[index];

                return Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _onItemTapped(index),
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 10.h),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isSelected
                                ? item.selectedIcon
                                : item.unselectedIcon,
                            size: 24.sp,
                            color: isSelected
                                ? selectedItemColor
                                : unselectedItemColor,
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            item.labelKey.tr(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyles.blackBold14.copyWith(
                              fontSize: 11.sp,
                              color: isSelected
                                  ? selectedItemColor
                                  : unselectedItemColor,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomNavItemData {
  final String labelKey;
  final IconData unselectedIcon;
  final IconData selectedIcon;

  const _BottomNavItemData({
    required this.labelKey,
    required this.unselectedIcon,
    required this.selectedIcon,
  });
}
