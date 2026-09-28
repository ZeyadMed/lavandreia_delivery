import 'dart:io';

import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:lavanderia_delivery/core/common_widget/custom_success_message.dart';
import 'package:lavanderia_delivery/core/helpers/image_picker_helper.dart';
import 'package:lavanderia_delivery/core/helpers/validators.dart';
import 'package:lavanderia_delivery/core/style/app_colors.dart';
import 'package:lavanderia_delivery/core/theme/text_styles.dart';
import 'package:lavanderia_delivery/features/home/presentation/view/widget/home_colors.dart';
import 'package:lavanderia_delivery/features/profile/models/driver_profile_model.dart';

/// شاشة تعديل الملف الشخصي: بترجع البيانات الجديدة لشاشة حسابي لما المندوب يحفظ
class EditProfileScreen extends StatefulWidget {
  final DriverProfileModel profile;

  const EditProfileScreen({super.key, required this.profile});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(text: widget.profile.name);
  late final _phoneController = TextEditingController(
    text: widget.profile.phone,
  );
  late final _emailController = TextEditingController(
    text: widget.profile.email,
  );
  late final _addressController = TextEditingController(
    text: widget.profile.address,
  );
  late File? _image = widget.profile.image;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _pickImage() {
    ImagePickerHelper.showImagePicker(context, (file) {
      if (file != null) setState(() => _image = file);
    });
  }

  // TODO: هيتبعت للـ API لما يجهز
  void _save() {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final updated = widget.profile.copyWith(
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      address: _addressController.text.trim(),
      image: _image,
    );
    CustomSuccessOverlay.show(context: context, text: 'profile_updated');
    context.pop(updated);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: AppColors.backgroundColor,
        body: Column(
          children: [
            const _EditProfileHeader(),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(16.w, 24.h, 16.w, 24.h),
                children: [
                  _ProfileImagePicker(image: _image, onTap: _pickImage),
                  Gap(24.h),
                  Container(
                    padding: EdgeInsets.all(20.r),
                    decoration: BoxDecoration(
                      color: AppColors.whiteColor,
                      borderRadius: BorderRadius.circular(22.r),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _ProfileTextField(
                            label: 'full_name',
                            controller: _nameController,
                            validator: Validators.validateEmpty,
                          ),
                          _ProfileTextField(
                            label: 'phone_number',
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            validator: Validators.phoneNumberValidator,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(11),
                            ],
                          ),
                          _ProfileTextField(
                            label: 'email',
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            validator: Validators.emailValidator,
                          ),
                          _ProfileTextField(
                            label: 'address',
                            controller: _addressController,
                            validator: Validators.validateEmpty,
                          ),
                          Gap(8.h),
                          _SaveButton(onTap: _save),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditProfileHeader extends StatelessWidget {
  const _EditProfileHeader();

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
          padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 24.h),
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
              Gap(12.h),
              Text(
                'edit_profile'.tr(),
                style: TextStyles.boldStyle(22, color: AppColors.whiteColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// صورة المندوب في دايرة بإطار أزرق وتحتها "تغيير الصورة"
class _ProfileImagePicker extends StatelessWidget {
  final File? image;
  final VoidCallback onTap;

  const _ProfileImagePicker({required this.image, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          children: [
            Container(
              width: 90.r,
              height: 90.r,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: HomeColors.lightBlue,
                border: Border.all(color: AppColors.primaryColor, width: 3),
              ),
              alignment: Alignment.center,
              child: image != null
                  ? Image.file(
                      image!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    )
                  : Text('👤', style: TextStyle(fontSize: 42.sp)),
            ),
            Gap(10.h),
            Text(
              'change_photo'.tr(),
              style: TextStyles.boldStyle(14, color: AppColors.primaryColor),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? inputFormatters;

  const _ProfileTextField({
    required this.label,
    required this.controller,
    this.keyboardType,
    this.validator,
    this.inputFormatters,
  });

  static const Color _borderColor = Color(0xffE5E7EB);

  OutlineInputBorder _border(Color color, {double width = 1}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(14.r),
        borderSide: BorderSide(color: color, width: width),
      );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.tr(),
            style: TextStyles.boldStyle(14, color: AppColors.greyColor6),
          ),
          Gap(8.h),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            validator: validator,
            inputFormatters: inputFormatters,
            style: TextStyles.boldStyle(
              16,
              color: AppColors.blackColor,
              weight: FontWeight.w400,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.whiteColor,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: 15.h,
              ),
              border: _border(_borderColor),
              enabledBorder: _border(_borderColor),
              focusedBorder: _border(AppColors.primaryColor, width: 1.5),
              errorBorder: _border(HomeColors.red),
              focusedErrorBorder: _border(HomeColors.red, width: 1.5),
              errorStyle: TextStyles.boldStyle(
                12,
                color: HomeColors.red,
                weight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  final VoidCallback onTap;

  const _SaveButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(16.r);
    return Material(
      color: AppColors.primaryColor,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: SizedBox(
          height: 56.h,
          child: Center(
            child: Text(
              'save_changes'.tr(),
              style: TextStyles.boldStyle(16, color: AppColors.whiteColor),
            ),
          ),
        ),
      ),
    );
  }
}
