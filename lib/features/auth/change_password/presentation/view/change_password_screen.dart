import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:lavanderia_delivery/core/bloc/base_bloc.dart';
import 'package:lavanderia_delivery/core/common_widget/label.dart';
import 'package:lavanderia_delivery/core/common_widget/otp_text_field.dart';
import 'package:lavanderia_delivery/core/extensions/context_extension.dart';
import 'package:lavanderia_delivery/core/helpers/validators.dart';
import 'package:lavanderia_delivery/core/router/app_router.dart';
import 'package:lavanderia_delivery/core/service_locator/service_locator.dart';
import 'package:lavanderia_delivery/core/style/app_colors.dart';
import 'package:lavanderia_delivery/core/style/assets.dart';
import 'package:lavanderia_delivery/core/theme/text_styles.dart';
import 'package:lavanderia_delivery/core/widget/custom_button.dart';
import 'package:lavanderia_delivery/core/widget/custom_text_field.dart';
import 'package:lavanderia_delivery/features/auth/change_password/presentation/logic/reset_password_bloc.dart';
import 'package:lavanderia_delivery/features/auth/change_password/presentation/logic/reset_password_event.dart';

class ChangePasswordScreen extends StatefulWidget {
  /// الرقم اللي اتبعتله الكود من شاشة نسيت كلمة المرور،
  /// وبيتبعت مع الكود وكلمة المرور الجديدة في reset-password
  final String phoneNumber;

  const ChangePasswordScreen({super.key, required this.phoneNumber});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  final _formKey = GlobalKey<FormState>();

  static const int _otpLength = 6;

  @override
  void dispose() {
    _codeController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onSubmit(BuildContext context) {
    if (!_formKey.currentState!.validate()) return;

    // حقل الكود مش FormField فبنتحقق منه هنا
    final code = _codeController.text.trim();
    if (code.length < _otpLength) {
      context.showErrorMessage('otp_required'.tr());
      return;
    }

    context.read<ResetPasswordBloc>().add(
      ResetPasswordEvent(
        phoneNumber: widget.phoneNumber,
        code: code,
        newPassword: _newPasswordController.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<ResetPasswordBloc>(),
      child: Scaffold(
        backgroundColor: AppColors.secondaryColor,
        body: BlocConsumer<ResetPasswordBloc, BaseState<String>>(
          listener: (context, state) {
            if (state.isSuccess) {
              context.showSuccessMessage(state.data ?? '');
              context.go(AppRouter.login);
            }
            if (state.isFailure) {
              context.showErrorMessage(state.errorMessage ?? '');
            }
          },
          builder: (context, state) {
            // بقت أطول بحقل الكود، فبتسكرول لما الكيبورد يفتح
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(25.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // App Logo
                      Image.asset(
                        Assets.assetsImagesLogo,
                        width: double.infinity,
                        height: context.screenHeight * 0.2,
                        color: AppColors.blackColor,
                      ),
                      Gap(40.h),
                      // Header
                      LocalizedLabel(
                        text: "change_password_title",
                        style: TextStyles.blackBold32,
                      ),

                      Gap(10.h),

                      // Description
                      LocalizedLabel(
                        text: "change_password_desc",
                        maxLines: 3,
                        style: TextStyles.blackRegular16.copyWith(
                          color: AppColors.lightTextColor,
                        ),
                      ),

                      Gap(30.h),

                      // OTP Field — الكود اللي وصل من forgot-password
                      OtpTextField(
                        pinController: _codeController,
                        length: _otpLength,
                      ),

                      Gap(20.h),

                      // New Password Field
                      Customtextfield(
                        textEditingController: _newPasswordController,
                        hintText: 'new_password'.tr(),
                        keyboardType: TextInputType.visiblePassword,
                        prefix: const Icon(Icons.lock_outlined),
                        validator: Validators.passwordValidator,
                        obscureText: _obscureNewPassword,
                        suffix: IconButton(
                          onPressed: () {
                            setState(
                              () => _obscureNewPassword = !_obscureNewPassword,
                            );
                          },
                          icon: Icon(
                            _obscureNewPassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                        ),
                      ),

                      Gap(10.h),

                      // Confirm New Password Field
                      Customtextfield(
                        textEditingController: _confirmPasswordController,
                        hintText: 'confirm_new_password'.tr(),
                        keyboardType: TextInputType.visiblePassword,
                        prefix: const Icon(Icons.lock_outlined),
                        validator: (value) => Validators.repeatPasswordValidator(
                          value: value,
                          Password: _newPasswordController.text,
                        ),
                        obscureText: _obscureConfirmPassword,
                        suffix: IconButton(
                          onPressed: () {
                            setState(
                              () => _obscureConfirmPassword =
                                  !_obscureConfirmPassword,
                            );
                          },
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                        ),
                      ),

                      Gap(30.h),

                      // Change Password Button
                      state.isLoading
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: AppColors.primaryColor,
                              ),
                            )
                          : CustomButton(
                              onPressed: () => _onSubmit(context),
                              title: "change_password_btn".tr(),
                            ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
