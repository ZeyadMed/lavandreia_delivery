import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:lavanderia_delivery/core/bloc/base_bloc.dart';
import 'package:lavanderia_delivery/core/service_locator/service_locator.dart';
import 'package:lavanderia_delivery/core/style/app_colors.dart';
import 'package:lavanderia_delivery/core/theme/text_styles.dart';
import 'package:lavanderia_delivery/features/auth/register/data/car_catalog_data_source.dart';
import 'package:lavanderia_delivery/features/auth/register/models/car_catalog_item.dart';
import 'package:lavanderia_delivery/features/auth/register/presentation/logic/car_options_cubit.dart';
import 'package:lavanderia_delivery/features/auth/register/presentation/view/car_option_picker_screen.dart';

const _chipColor = Color(0xffF2F2F7);
const _disabledColor = Color(0xff8E8E93);

/// اختيار العربية من الكتالوج: كارت الهيكل (chips بصور) وكارت فيه
/// النوع ← الموديل ← الفئة، كل صف بيفتح CarOptionPickerScreen.
/// النوع والموديل إجباريين، والفئة بتستخبى لو الموديل ملوش فئات
class CarCatalogSelector extends StatefulWidget {
  final CarSelection value;
  final ValueChanged<CarSelection> onChanged;

  const CarCatalogSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  State<CarCatalogSelector> createState() => _CarCatalogSelectorState();
}

class _CarCatalogSelectorState extends State<CarCatalogSelector> {
  final _catalog = getIt<CarCatalogDataSource>();
  late final _bodyTypesCubit = CarOptionsCubit(_catalog.getBodyTypes)
    ..fetchData();

  /// فئات الموديل الحالي، عشان نعرف نظهر صف الفئة ولا لأ
  CarOptionsCubit? _trimsCubit;

  @override
  void initState() {
    super.initState();
    _loadTrims(widget.value.model);
  }

  @override
  void didUpdateWidget(covariant CarCatalogSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value.model?.id != widget.value.model?.id) {
      _loadTrims(widget.value.model);
    }
  }

  void _loadTrims(CarCatalogItem? model) {
    _trimsCubit?.close();
    _trimsCubit = model == null
        ? null
        : (CarOptionsCubit(() => _catalog.getTrims(model.id))..fetchData());
  }

  @override
  void dispose() {
    _bodyTypesCubit.close();
    _trimsCubit?.close();
    super.dispose();
  }

  Future<void> _pickMake(FormFieldState<CarSelection> field) async {
    final make = await CarOptionPickerScreen.show(
      context,
      title: 'car_make',
      selected: widget.value.make,
      createCubit: () => CarOptionsCubit(_catalog.getMakes),
    );
    if (make != null) _change(field, widget.value.withMake(make));
  }

  Future<void> _pickModel(FormFieldState<CarSelection> field) async {
    final make = widget.value.make;
    if (make == null) return;
    final model = await CarOptionPickerScreen.show(
      context,
      title: 'car_model',
      selected: widget.value.model,
      createCubit: () => CarOptionsCubit(() => _catalog.getModels(make.id)),
    );
    if (model != null) _change(field, widget.value.withModel(model));
  }

  Future<void> _pickTrim(FormFieldState<CarSelection> field) async {
    final model = widget.value.model;
    if (model == null) return;
    final trim = await CarOptionPickerScreen.show(
      context,
      title: 'car_trim',
      selected: widget.value.trim,
      createCubit: () => CarOptionsCubit(() => _catalog.getTrims(model.id)),
    );
    if (trim != null) _change(field, widget.value.withTrim(trim));
  }

  void _change(FormFieldState<CarSelection> field, CarSelection value) {
    widget.onChanged(value);
    field.didChange(value);
    // الخطأ بيختفي أول ما الاختيار يكمل
    if (field.hasError) field.validate();
  }

  static String? _validate(CarSelection? value) {
    if (value?.make == null) return 'car_make_required'.tr();
    if (value?.model == null) return 'car_model_required'.tr();
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final value = widget.value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Gap(18.h),
        BlocProvider.value(
          value: _bodyTypesCubit,
          child: _BodyTypeCard(
            selected: value.bodyType,
            // الهيكل اختياري، فالضغط على المختار تاني بيلغيه
            onSelected: (type) => widget.onChanged(
              value.withBodyType(type.id == value.bodyType?.id ? null : type),
            ),
          ),
        ),
        Gap(14.h),
        FormField<CarSelection>(
          initialValue: value,
          validator: _validate,
          builder: (field) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _WhiteCard(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                borderColor: field.hasError ? Colors.redAccent : null,
                child: Column(
                  children: [
                    _PickerRow(
                      label: 'car_make',
                      value: value.make?.name,
                      enabled: true,
                      onTap: () => _pickMake(field),
                    ),
                    const _DashedDivider(),
                    _PickerRow(
                      label: 'car_model',
                      value: value.model?.name,
                      enabled: value.make != null,
                      onTap: () => _pickModel(field),
                    ),
                    if (_trimsCubit != null)
                      BlocBuilder<CarOptionsCubit, BaseState<CarCatalogItem>>(
                        bloc: _trimsCubit,
                        builder: (context, state) {
                          final hasTrims =
                              value.trim != null ||
                              (state.isSuccess && state.items.isNotEmpty);
                          if (!hasTrims) return const SizedBox.shrink();
                          return Column(
                            children: [
                              const _DashedDivider(),
                              _PickerRow(
                                label: 'car_trim',
                                value: value.trim?.name,
                                enabled: true,
                                onTap: () => _pickTrim(field),
                              ),
                            ],
                          );
                        },
                      ),
                  ],
                ),
              ),
              if (field.hasError)
                Padding(
                  padding: EdgeInsetsDirectional.only(start: 12.w, top: 6.h),
                  child: Text(
                    field.errorText!,
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 12.sp,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WhiteCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? borderColor;

  const _WhiteCard({
    required this.child,
    required this.padding,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(16.r),
        border: borderColor == null ? null : Border.all(color: borderColor!),
      ),
      child: child,
    );
  }
}

/// كارت "نوع الهيكل": chips رمادي فيها صورة العربية والاسم
class _BodyTypeCard extends StatelessWidget {
  final CarCatalogItem? selected;
  final ValueChanged<CarCatalogItem> onSelected;

  const _BodyTypeCard({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CarOptionsCubit, BaseState<CarCatalogItem>>(
      builder: (context, state) {
        // الهيكل اختياري، فلو مفيش هياكل أو حصل خطأ الكارت بيستخبى
        if (state.isFailure || state.isEmpty) return const SizedBox.shrink();
        return _WhiteCard(
          padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 18.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'car_body_type'.tr(),
                style: TextStyles.boldStyle(17, color: AppColors.blackColor),
              ),
              Gap(14.h),
              if (!state.isSuccess)
                const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primaryColor,
                  ),
                )
              else
                Wrap(
                  spacing: 10.w,
                  runSpacing: 10.h,
                  children: state.items
                      .map(
                        (type) => _BodyTypeChip(
                          type: type,
                          isSelected: type.id == selected?.id,
                          onTap: () => onSelected(type),
                        ),
                      )
                      .toList(),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _BodyTypeChip extends StatelessWidget {
  final CarCatalogItem type;
  final bool isSelected;
  final VoidCallback onTap;

  const _BodyTypeChip({
    required this.type,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fallback = Icon(
      Icons.directions_car_filled_outlined,
      size: 22.r,
      color: isSelected ? AppColors.primaryColor : _disabledColor,
    );
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 9.h),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.secondaryColor : _chipColor,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(
            color: isSelected ? AppColors.primaryColor : _chipColor,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 34.w,
              height: 18.h,
              child: type.imageUrl == null
                  ? fallback
                  : CachedNetworkImage(
                      imageUrl: type.imageUrl!,
                      fit: BoxFit.contain,
                      errorWidget: (_, _, _) => fallback,
                    ),
            ),
            Gap(8.w),
            Text(
              type.name,
              style: TextStyles.boldStyle(
                15,
                color: isSelected
                    ? AppColors.primaryColor
                    : AppColors.blackColor,
                weight: isSelected ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// صف: العنوان في البداية و"اختر" (أو الاختيار) وسهم أزرق في النهاية.
/// الصف المقفول (الموديل قبل النوع) عنوانه رمادي
class _PickerRow extends StatelessWidget {
  final String label;
  final String? value;
  final bool enabled;
  final VoidCallback onTap;

  const _PickerRow({
    required this.label,
    required this.value,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      child: SizedBox(
        height: 54.h,
        child: Row(
          children: [
            Text(
              label.tr(),
              style: TextStyles.boldStyle(
                16,
                color: enabled ? AppColors.blackColor : _disabledColor,
              ),
            ),
            Gap(16.w),
            Expanded(
              child: Text(
                value ?? 'choose'.tr(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
                style: TextStyles.boldStyle(
                  16,
                  color: enabled ? AppColors.blackColor : _disabledColor,
                  weight: FontWeight.w400,
                ),
              ),
            ),
            Gap(10.w),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 15.r,
              color: AppColors.primaryColor,
            ),
          ],
        ),
      ),
    );
  }
}

class _DashedDivider extends StatelessWidget {
  const _DashedDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10.w),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const dash = 4.0;
          const gap = 3.0;
          final count = (constraints.maxWidth / (dash + gap)).floor();
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(
              count,
              (_) => const SizedBox(
                width: dash,
                height: 1,
                child: ColoredBox(color: Color(0xffE5E5EA)),
              ),
            ),
          );
        },
      ),
    );
  }
}
