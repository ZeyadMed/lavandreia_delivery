import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:lavanderia_delivery/core/bloc/base_bloc.dart';
import 'package:lavanderia_delivery/core/style/app_colors.dart';
import 'package:lavanderia_delivery/core/theme/text_styles.dart';
import 'package:lavanderia_delivery/features/auth/register/models/car_catalog_item.dart';
import 'package:lavanderia_delivery/features/auth/register/presentation/logic/car_options_cubit.dart';

/// شاشة كاملة لاختيار عنصر واحد من الكتالوج (النوع أو الموديل أو الفئة):
/// زرار قفل، عنوان، بحث، ليستة بمربعات اختيار، وزرار تأكيد تحت.
/// بترجع العنصر اللي اتختار، أو null لو المستخدم قفل من غير تأكيد
class CarOptionPickerScreen extends StatelessWidget {
  final String title;
  final CarOptionsCubit Function() createCubit;
  final CarCatalogItem? selected;

  const CarOptionPickerScreen({
    super.key,
    required this.title,
    required this.createCubit,
    this.selected,
  });

  static Future<CarCatalogItem?> show(
    BuildContext context, {
    required String title,
    required CarOptionsCubit Function() createCubit,
    CarCatalogItem? selected,
  }) {
    FocusScope.of(context).unfocus();
    return Navigator.of(context).push<CarCatalogItem>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => CarOptionPickerScreen(
          title: title,
          createCubit: createCubit,
          selected: selected,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => createCubit()..fetchData(),
      child: _PickerView(title: title, initial: selected),
    );
  }
}

class _PickerView extends StatefulWidget {
  final String title;
  final CarCatalogItem? initial;

  const _PickerView({required this.title, required this.initial});

  @override
  State<_PickerView> createState() => _PickerViewState();
}

class _PickerViewState extends State<_PickerView> {
  late CarCatalogItem? _selected = widget.initial;
  String _query = '';

  List<CarCatalogItem> _filter(List<CarCatalogItem> items) {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return items;
    return items
        .where((item) => item.name.toLowerCase().contains(query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: AppColors.whiteColor,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: Padding(
                  padding: EdgeInsetsDirectional.only(end: 8.w, top: 4.h),
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.close,
                      size: 26.sp,
                      color: AppColors.blackColor,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Text(
                  widget.title.tr(),
                  style: TextStyles.boldStyle(20, color: AppColors.blackColor),
                ),
              ),
              Gap(16.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 14.w),
                child: _SearchField(
                  onChanged: (value) => setState(() => _query = value),
                ),
              ),
              Gap(10.h),
              Expanded(
                child: BlocBuilder<CarOptionsCubit, BaseState<CarCatalogItem>>(
                  builder: (context, state) {
                    if (state.isFailure) {
                      return _LoadError(
                        message: state.errorMessage ?? '',
                        onRetry: () =>
                            context.read<CarOptionsCubit>().fetchData(),
                      );
                    }
                    if (!state.isSuccess) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primaryColor,
                        ),
                      );
                    }
                    final items = _filter(state.items);
                    if (items.isEmpty) {
                      return Center(
                        child: Text(
                          'no_results'.tr(),
                          style: TextStyles.greyColor2Regular14,
                        ),
                      );
                    }
                    return ListView.builder(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return _OptionRow(
                          name: item.name,
                          isSelected: item.id == _selected?.id,
                          onTap: () => setState(() => _selected = item),
                        );
                      },
                    );
                  },
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(14.w, 10.h, 14.w, 16.h),
                child: _ConfirmButton(
                  onTap: _selected == null
                      ? null
                      : () => Navigator.of(context).pop(_selected),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final ValueChanged<String> onChanged;

  const _SearchField({required this.onChanged});

  static const _borderColor = Color(0xffE5E5EA);

  OutlineInputBorder _border(Color color) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(12.r),
    borderSide: BorderSide(color: color),
  );

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      style: TextStyles.boldStyle(
        15,
        color: AppColors.blackColor,
        weight: FontWeight.w400,
      ),
      decoration: InputDecoration(
        isDense: true,
        hintText: 'catalog_search'.tr(),
        hintStyle: TextStyles.boldStyle(
          14,
          color: AppColors.greyColor6,
          weight: FontWeight.w400,
        ),
        prefixIcon: Icon(
          Icons.search,
          size: 22.sp,
          color: AppColors.blackColor,
        ),
        prefixIconConstraints: BoxConstraints(minWidth: 40.w),
        contentPadding: EdgeInsets.symmetric(vertical: 13.h),
        filled: true,
        fillColor: AppColors.whiteColor,
        border: _border(_borderColor),
        enabledBorder: _border(_borderColor),
        focusedBorder: _border(AppColors.primaryColor),
      ),
    );
  }
}

/// صف في الليستة: مربع اختيار وبعده الاسم، وخط فاصل بعرض الشاشة
class _OptionRow extends StatelessWidget {
  final String name;
  final bool isSelected;
  final VoidCallback onTap;

  const _OptionRow({
    required this.name,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsetsDirectional.fromSTEB(28.w, 9.h, 16.w, 9.h),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xffEDEDF0))),
        ),
        child: Row(
          children: [
            _CheckBox(isSelected: isSelected),
            Gap(6.w),
            Expanded(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyles.boldStyle(
                  16,
                  color: AppColors.blackColor,
                  weight: FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckBox extends StatelessWidget {
  final bool isSelected;

  const _CheckBox({required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 22.r,
      height: 22.r,
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primaryColor : AppColors.whiteColor,
        borderRadius: BorderRadius.circular(5.r),
        border: Border.all(
          color: isSelected ? AppColors.primaryColor : const Color(0xffD1D1D6),
          width: 1.5,
        ),
      ),
      child: isSelected
          ? Icon(Icons.check, size: 16.r, color: AppColors.whiteColor)
          : null,
    );
  }
}

class _ConfirmButton extends StatelessWidget {
  final VoidCallback? onTap;

  const _ConfirmButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(10.r);
    return Material(
      color: onTap == null
          ? AppColors.primaryColor.withValues(alpha: 0.4)
          : AppColors.primaryColor,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: SizedBox(
          height: 50.h,
          child: Center(
            child: Text(
              'confirm_selection'.tr(),
              style: TextStyles.boldStyle(18, color: AppColors.whiteColor),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _LoadError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyles.greyColor2Regular14,
            ),
            TextButton(
              onPressed: onRetry,
              child: Text(
                'retry'.tr(),
                style: TextStyles.boldStyle(14, color: AppColors.primaryColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
