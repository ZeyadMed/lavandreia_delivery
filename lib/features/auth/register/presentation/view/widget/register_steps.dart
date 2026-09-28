import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:lavanderia_delivery/core/common_widget/label.dart';
import 'package:lavanderia_delivery/core/helpers/image_picker_helper.dart';
import 'package:lavanderia_delivery/core/helpers/validators.dart';
import 'package:lavanderia_delivery/core/style/app_colors.dart';
import 'package:lavanderia_delivery/core/theme/text_styles.dart';
import 'package:lavanderia_delivery/core/widget/custom_phone_field.dart';
import 'package:lavanderia_delivery/features/auth/register/models/register_form_data.dart';
import 'package:lavanderia_delivery/features/auth/register/presentation/view/widget/register_form_widgets.dart';

/// الخطوة 1: المعلومات الشخصية
class PersonalInfoStep extends StatefulWidget {
  final RegisterFormData data;

  const PersonalInfoStep({super.key, required this.data});

  @override
  State<PersonalInfoStep> createState() => _PersonalInfoStepState();
}

class _PersonalInfoStepState extends State<PersonalInfoStep> {
  bool obscurePassword = true;
  bool obscureConfirmPassword = true;

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Gap(10.h),
        Center(
          child: GestureDetector(
            onTap: () => ImagePickerHelper.showImagePicker(context, (file) {
              if (file != null) setState(() => data.profileImage = file);
            }),
            child: Column(
              children: [
                Container(
                  width: 90.w,
                  height: 90.w,
                  clipBehavior: Clip.antiAlias,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [AppColors.primaryColor, Color(0xff2A56B8)],
                    ),
                  ),
                  child: data.profileImage != null
                      ? Image.file(data.profileImage!, fit: BoxFit.cover)
                      : Icon(
                          Icons.person,
                          size: 44.sp,
                          color: AppColors.whiteColor.withValues(alpha: 0.7),
                        ),
                ),
                Gap(10.h),
                LocalizedLabel(
                  text: 'change_photo',
                  style: TextStyles.boldStyle(
                    14,
                    color: AppColors.primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ),
        RegisterTextField(
          label: 'full_name',
          controller: data.nameController,
          keyboardType: TextInputType.name,
          validator: Validators.displayNameValidator,
        ),
        const RegisterFieldLabel('phone_number'),
        Gap(8.h),
        CustomPhoneField(
          controller: data.phoneController,
          onChanged: (phone) => data.completePhone = phone.completeNumber,
          validator: (phone) =>
              (phone == null || phone.isEmpty) ? 'phoneNumberEmpty'.tr() : null,
        ),
        RegisterTextField(
          label: 'email',
          controller: data.emailController,
          keyboardType: TextInputType.emailAddress,
          validator: Validators.emailValidator,
        ),
        RegisterTextField(
          label: 'password',
          controller: data.passwordController,
          keyboardType: TextInputType.visiblePassword,
          obscureText: obscurePassword,
          validator: Validators.passwordValidator,
          suffix: IconButton(
            onPressed: () => setState(() => obscurePassword = !obscurePassword),
            icon: Icon(
              obscurePassword ? Icons.visibility_off : Icons.visibility,
            ),
          ),
        ),
        RegisterTextField(
          label: 'confirm_password',
          controller: data.confirmPasswordController,
          keyboardType: TextInputType.visiblePassword,
          obscureText: obscureConfirmPassword,
          validator: (value) =>
              Validators.validateEmpty(value) ??
              Validators.repeatPasswordValidator(
                value: value,
                Password: data.passwordController.text,
              ),
          suffix: IconButton(
            onPressed: () => setState(
              () => obscureConfirmPassword = !obscureConfirmPassword,
            ),
            icon: Icon(
              obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
            ),
          ),
        ),
      ],
    );
  }
}

/// الخطوة 2: بيانات الهوية
class IdentityStep extends StatefulWidget {
  final RegisterFormData data;

  const IdentityStep({super.key, required this.data});

  @override
  State<IdentityStep> createState() => _IdentityStepState();
}

class _IdentityStepState extends State<IdentityStep> {
  /// الرقم الوطني الليبي 12 رقم
  String? _nationalIdValidator(String? value) {
    if (value == null || value.isEmpty) return 'nationalIdEmpty'.tr();
    if (!RegExp(r'^\d{12}$').hasMatch(value)) {
      return 'invalid_libyan_national_id'.tr();
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RegisterTextField(
          label: 'national_id',
          controller: data.nationalIdController,
          keyboardType: TextInputType.number,
          validator: _nationalIdValidator,
        ),
        RegisterTextField(
          label: 'birth_date',
          controller: data.birthDateController,
          validator: Validators.validateEmpty,
          onDateSelected: (date) => data.birthDate = date,
        ),
        GovernorateDropdown(
          value: data.governorate,
          onChanged: (value) => setState(() => data.governorate = value),
        ),
        RegisterTextField(
          label: 'address',
          controller: data.addressController,
          keyboardType: TextInputType.streetAddress,
          validator: Validators.validateEmpty,
        ),
        UploadImageBox(
          label: 'id_front_image',
          title: 'front_side',
          image: data.idFrontImage,
          onPicked: (file) => setState(() => data.idFrontImage = file),
        ),
        UploadImageBox(
          label: 'id_back_image',
          title: 'back_side',
          image: data.idBackImage,
          onPicked: (file) => setState(() => data.idBackImage = file),
        ),
      ],
    );
  }
}

/// الخطوة 3: رخصة القيادة (من غير رقم ونوع الرخصة)
class LicenseStep extends StatefulWidget {
  final RegisterFormData data;

  const LicenseStep({super.key, required this.data});

  @override
  State<LicenseStep> createState() => _LicenseStepState();
}

class _LicenseStepState extends State<LicenseStep> {
  String? _expiryValidator(String? value) {
    final empty = Validators.validateEmpty(value);
    if (empty != null) return empty;
    final issue = widget.data.licenseIssueDate;
    final expiry = widget.data.licenseExpiryDate;
    if (issue != null && expiry != null && !expiry.isAfter(issue)) {
      return 'expiry_after_issue'.tr();
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RegisterTextField(
          label: 'issue_date',
          controller: data.licenseIssueDateController,
          validator: Validators.validateEmpty,
          onDateSelected: (date) => data.licenseIssueDate = date,
        ),
        RegisterTextField(
          label: 'expiry_date',
          controller: data.licenseExpiryDateController,
          validator: _expiryValidator,
          onDateSelected: (date) => data.licenseExpiryDate = date,
        ),
        UploadImageBox(
          label: 'license_front_image',
          title: 'front_side',
          image: data.licenseFrontImage,
          onPicked: (file) => setState(() => data.licenseFrontImage = file),
        ),
        UploadImageBox(
          label: 'license_back_image',
          title: 'back_side',
          image: data.licenseBackImage,
          onPicked: (file) => setState(() => data.licenseBackImage = file),
        ),
      ],
    );
  }
}

/// الخطوة 4: بيانات المركبة
class VehicleStep extends StatefulWidget {
  final RegisterFormData data;

  const VehicleStep({super.key, required this.data});

  @override
  State<VehicleStep> createState() => _VehicleStepState();
}

class _VehicleStepState extends State<VehicleStep> {
  String? _yearValidator(String? value) {
    final empty = Validators.validateEmpty(value);
    if (empty != null) return empty;
    final year = int.tryParse(value!);
    if (year == null || year < 1980 || year > DateTime.now().year + 1) {
      return 'invalid_year'.tr();
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const RegisterFieldLabel('vehicle_type'),
        RegisterOptionSelector<VehicleType>(
          options: VehicleType.values,
          selected: data.vehicleType,
          labelOf: (type) => type.labelKey,
          onSelected: (type) => setState(() => data.vehicleType = type),
        ),
        RegisterTextField(
          label: 'vehicle_brand',
          controller: data.vehicleBrandController,
          validator: Validators.validateEmpty,
        ),
        RegisterTextField(
          label: 'vehicle_model',
          controller: data.vehicleModelController,
          validator: Validators.validateEmpty,
        ),
        RegisterTextField(
          label: 'manufacture_year',
          controller: data.manufactureYearController,
          keyboardType: TextInputType.number,
          validator: _yearValidator,
        ),
        VehicleColorSelector(
          selected: data.vehicleColor,
          otherController: data.vehicleColorController,
          onSelected: (color) => setState(() => data.vehicleColor = color),
        ),
        RegisterTextField(
          label: 'plate_number',
          controller: data.plateNumberController,
          validator: Validators.validateEmpty,
        ),
        UploadImageBox(
          label: 'vehicle_image',
          title: 'vehicle_image',
          image: data.vehicleImage,
          onPicked: (file) => setState(() => data.vehicleImage = file),
        ),
      ],
    );
  }
}

/// الخطوة 5: مراجعة البيانات
class ReviewStep extends StatelessWidget {
  final RegisterFormData data;

  const ReviewStep({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final languageCode = context.locale.languageCode;
    return Column(
      children: [
        ReviewSectionCard(
          title: 'register_personal_info',
          rows: [
            MapEntry('full_name', data.nameController.text),
            MapEntry('phone_number', data.completePhone),
            MapEntry('email', data.emailController.text),
          ],
        ),
        ReviewSectionCard(
          title: 'register_identity_info',
          rows: [
            MapEntry('national_id', data.nationalIdController.text),
            MapEntry(
              'governorate',
              data.governorate?.localizedName(languageCode) ?? '',
            ),
          ],
        ),
        ReviewSectionCard(
          title: 'license_data',
          rows: [
            MapEntry('issue_date', data.licenseIssueDateController.text),
            MapEntry('expiry_date', data.licenseExpiryDateController.text),
          ],
        ),
        ReviewSectionCard(
          title: 'register_vehicle_info',
          rows: [
            MapEntry('vehicle_type', data.vehicleType.labelKey.tr()),
            MapEntry('vehicle_brand', data.vehicleBrandController.text),
            MapEntry('vehicle_model', data.vehicleModelController.text),
            MapEntry(
              'vehicle_color',
              data.vehicleColor == VehicleColor.other
                  ? data.vehicleColorValue
                  : data.vehicleColor?.labelKey.tr() ?? '',
            ),
            MapEntry('plate_number', data.plateNumberController.text),
          ],
        ),
      ],
    );
  }
}
