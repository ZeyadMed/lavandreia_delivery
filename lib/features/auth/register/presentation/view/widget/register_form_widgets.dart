import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:lavanderia_delivery/core/common_widget/label.dart';
import 'package:lavanderia_delivery/core/helpers/image_picker_helper.dart';
import 'package:lavanderia_delivery/core/helpers/validators.dart';
import 'package:lavanderia_delivery/core/style/app_colors.dart';
import 'package:lavanderia_delivery/core/theme/text_styles.dart';
import 'package:lavanderia_delivery/core/widget/custom_text_field.dart';
import 'package:lavanderia_delivery/features/auth/register/models/libya_governorate.dart';
import 'package:lavanderia_delivery/features/auth/register/models/register_form_data.dart';

/// عنوان صغير فوق كل خانة في شاشات التسجيل
class RegisterFieldLabel extends StatelessWidget {
  final String text;

  const RegisterFieldLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 18.h),
      child: LocalizedLabel(
        text: text,
        style: TextStyles.boldStyle(14, color: AppColors.greyColor6),
      ),
    );
  }
}

/// خانة نص بعنوانها، بتلف Customtextfield عشان كل الخطوات تبقى بنفس الشكل
class RegisterTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final bool obscureText;
  final Widget? suffix;
  final int? maxLength;
  final Function(DateTime?)? onDateSelected;

  const RegisterTextField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.keyboardType,
    this.validator,
    this.obscureText = false,
    this.suffix,
    this.maxLength,
    this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RegisterFieldLabel(label),
        Customtextfield(
          hintText: hint ?? label,
          textEditingController: controller,
          keyboardType: keyboardType,
          validator: validator,
          obscureText: obscureText,
          suffix:
              suffix ??
              (onDateSelected != null
                  ? const Icon(Icons.calendar_today_outlined, size: 20)
                  : null),
          maxLength: maxLength,
          onDateSelected: onDateSelected,
          hieght: 16.h,
        ),
      ],
    );
  }
}

/// دروب داون المحافظات الليبية
class GovernorateDropdown extends StatelessWidget {
  final LibyaGovernorate? value;
  final ValueChanged<LibyaGovernorate?> onChanged;

  const GovernorateDropdown({
    super.key,
    required this.value,
    required this.onChanged,
  });

  OutlineInputBorder _border(Color color, [double width = 0.5]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide(color: color, width: width),
      );

  @override
  Widget build(BuildContext context) {
    final languageCode = context.locale.languageCode;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const RegisterFieldLabel('governorate'),
        Gap(8.h),
        DropdownButtonFormField<LibyaGovernorate>(
          initialValue: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
          dropdownColor: AppColors.whiteColor,
          borderRadius: BorderRadius.circular(12.r),
          menuMaxHeight: 350.h,
          style: TextStyles.darkRegular16,
          hint: Text(
            'select_governorate'.tr(),
            style: TextStyles.greyColor2Regular14,
          ),
          validator: (value) =>
              value == null ? 'governorate_required'.tr() : null,
          items: LibyaGovernorate.all
              .map(
                (governorate) => DropdownMenuItem(
                  value: governorate,
                  child: Text(governorate.localizedName(languageCode)),
                ),
              )
              .toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
            contentPadding: EdgeInsets.symmetric(
              vertical: 16.h,
              horizontal: 20.w,
            ),
            fillColor: AppColors.whiteColor.withValues(alpha: 0.9),
            filled: true,
            enabledBorder: _border(Colors.grey),
            focusedBorder: _border(AppColors.primaryColor),
            errorBorder: _border(Colors.red, 1),
            focusedErrorBorder: _border(Colors.redAccent, 1),
            errorStyle: const TextStyle(
              color: Colors.redAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

/// اختيارات أفقية (زي نوع المركبة) الاختيار المحدد بيتلون بالأزرق
class RegisterOptionSelector<T> extends StatelessWidget {
  final List<T> options;
  final T selected;
  final String Function(T) labelOf;
  final ValueChanged<T> onSelected;

  const RegisterOptionSelector({
    super.key,
    required this.options,
    required this.selected,
    required this.labelOf,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 8.h),
      child: Wrap(
        spacing: 8.w,
        runSpacing: 8.h,
        children: options.map((option) {
          final isSelected = option == selected;
          return GestureDetector(
            onTap: () => onSelected(option),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.secondaryColor
                    : AppColors.whiteColor,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primaryColor
                      : AppColors.semiWhiteColor2,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: LocalizedLabel(
                text: labelOf(option),
                style: TextStyles.boldStyle(
                  14,
                  color: isSelected
                      ? AppColors.primaryColor
                      : AppColors.darkTextColor,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// اختيار لون المركبة: دواير بالألوان الأساسية + "لون آخر" بيفتح خانة يكتب فيها اللون
class VehicleColorSelector extends StatelessWidget {
  final VehicleColor? selected;
  final ValueChanged<VehicleColor> onSelected;
  final TextEditingController otherController;

  const VehicleColorSelector({
    super.key,
    required this.selected,
    required this.onSelected,
    required this.otherController,
  });

  @override
  Widget build(BuildContext context) {
    return FormField<VehicleColor>(
      initialValue: selected,
      validator: (_) => selected == null ? 'vehicle_color_required'.tr() : null,
      builder: (field) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const RegisterFieldLabel('vehicle_color'),
            Gap(10.h),
            LayoutBuilder(
              builder: (context, constraints) {
                // 5 ألوان في كل صف، العرض بيتقسم على المساحة المتاحة
                const perRow = 5;
                final spacing = 8.w;
                final itemWidth =
                    ((constraints.maxWidth - spacing * (perRow - 1)) / perRow)
                        .floorToDouble();
                return Wrap(
                  spacing: spacing,
                  runSpacing: 12.h,
                  children: VehicleColor.values.map((color) {
                    final isSelected = color == selected;
                    return GestureDetector(
                      onTap: () {
                        onSelected(color);
                        field.didChange(color);
                      },
                      child: SizedBox(
                        width: itemWidth,
                        child: Column(
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 42.w,
                              height: 42.w,
                              padding: EdgeInsets.all(3.w),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primaryColor
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: color.color ?? AppColors.whiteColor,
                                  gradient: color.color == null
                                      ? const SweepGradient(
                                          colors: [
                                            Colors.red,
                                            Colors.yellow,
                                            Colors.green,
                                            Colors.blue,
                                            Colors.purple,
                                            Colors.red,
                                          ],
                                        )
                                      : null,
                                  border: Border.all(
                                    color: AppColors.semiWhiteColor2,
                                  ),
                                ),
                                child: isSelected
                                    ? Icon(
                                        Icons.check,
                                        size: 18.sp,
                                        color:
                                            (color.color?.computeLuminance() ??
                                                    0) >
                                                0.5
                                            ? AppColors.blackColor
                                            : AppColors.whiteColor,
                                      )
                                    : null,
                              ),
                            ),
                            Gap(4.h),
                            LocalizedLabel(
                              text: color.labelKey,
                              textAlign: TextAlign.center,
                              style: TextStyles.boldStyle(
                                11,
                                color: isSelected
                                    ? AppColors.primaryColor
                                    : AppColors.darkTextColor,
                                weight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
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
            if (selected == VehicleColor.other)
              RegisterTextField(
                label: 'enter_vehicle_color',
                controller: otherController,
                validator: Validators.validateEmpty,
              ),
          ],
        );
      },
    );
  }
}

/// مربع رفع صورة بإطار متقطع، وبيتعمله validate زي أي خانة في الفورم
class UploadImageBox extends StatelessWidget {
  final String label;
  final String title;
  final File? image;
  final ValueChanged<File> onPicked;

  const UploadImageBox({
    super.key,
    required this.label,
    required this.title,
    required this.image,
    required this.onPicked,
  });

  @override
  Widget build(BuildContext context) {
    return FormField<File>(
      initialValue: image,
      validator: (_) => image == null ? 'image_required'.tr() : null,
      builder: (field) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RegisterFieldLabel(label),
            Gap(8.h),
            GestureDetector(
              onTap: () => ImagePickerHelper.showImagePicker(context, (file) {
                if (file == null) return;
                onPicked(file);
                field.didChange(file);
              }),
              child: CustomPaint(
                painter: _DashedBorderPainter(
                  color: field.hasError
                      ? Colors.redAccent
                      : AppColors.semiWhiteColor2,
                  radius: 16.r,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16.r),
                  child: Container(
                    width: double.infinity,
                    height: 130.h,
                    color: AppColors.semiWhiteColor,
                    child: image != null
                        ? Image.file(image!, fit: BoxFit.cover)
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.photo_camera_outlined,
                                size: 30.sp,
                                color: AppColors.greyColor,
                              ),
                              Gap(10.h),
                              LocalizedLabel(
                                text: title,
                                style: TextStyles.boldStyle(
                                  13,
                                  color: AppColors.greyColor,
                                ),
                              ),
                              Gap(4.h),
                              LocalizedLabel(
                                text: 'tap_to_capture_or_upload',
                                style: TextStyles.boldStyle(
                                  11,
                                  color: AppColors.greyColor4,
                                  weight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
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
        );
      },
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;

  _DashedBorderPainter({required this.color, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    const dash = 6.0;
    const gap = 4.0;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)),
      );
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + dash), paint);
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}

/// كارت في شاشة المراجعة فيه عنوان القسم وصفوف (العنوان - القيمة)
class ReviewSectionCard extends StatelessWidget {
  final String title;
  final List<MapEntry<String, String>> rows;

  const ReviewSectionCard({super.key, required this.title, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(top: 16.h),
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LocalizedLabel(
            text: title,
            style: TextStyles.boldStyle(16, color: AppColors.blackColor),
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 10.h),
            child: const Divider(height: 1, color: AppColors.semiWhiteColor2),
          ),
          ...rows.map(
            (row) => Padding(
              padding: EdgeInsets.symmetric(vertical: 6.h),
              child: Row(
                children: [
                  LocalizedLabel(
                    text: row.key,
                    style: TextStyles.greyColor2Regular14,
                  ),
                  Gap(12.w),
                  Expanded(
                    child: Label(
                      text: row.value.isEmpty ? '-' : row.value,
                      textAlign: TextAlign.end,
                      style: TextStyles.boldStyle(
                        14,
                        color: AppColors.blackColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
