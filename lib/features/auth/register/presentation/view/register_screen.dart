import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:lavanderia_delivery/core/bloc/base_bloc.dart';
import 'package:lavanderia_delivery/core/extensions/context_extension.dart';
import 'package:lavanderia_delivery/core/router/app_router.dart';
import 'package:lavanderia_delivery/core/service_locator/service_locator.dart';
import 'package:lavanderia_delivery/core/style/app_colors.dart';
import 'package:lavanderia_delivery/core/widget/custom_button.dart';
import 'package:lavanderia_delivery/features/auth/otp/models/otp_args.dart';
import 'package:lavanderia_delivery/features/auth/register/models/register_form_data.dart';
import 'package:lavanderia_delivery/features/auth/register/models/register_model.dart';
import 'package:lavanderia_delivery/features/auth/register/presentation/logic/city_cubit.dart';
import 'package:lavanderia_delivery/features/auth/register/presentation/logic/register_bloc.dart';
import 'package:lavanderia_delivery/features/auth/register/presentation/logic/register_event.dart';
import 'package:lavanderia_delivery/features/auth/register/presentation/view/widget/register_step_header.dart';
import 'package:lavanderia_delivery/features/auth/register/presentation/view/widget/register_steps.dart';

/// تسجيل المندوب على 5 خطوات: المعلومات الشخصية، الهوية، الرخصة، المركبة، المراجعة
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  static const _titles = [
    'register_personal_info',
    'register_identity_info',
    'register_license_info',
    'register_vehicle_info',
    'register_review',
  ];

  final _data = RegisterFormData();
  final _pageController = PageController();

  /// فورم لكل خطوة، ماعدا المراجعة ملهاش validate
  final _formKeys = List.generate(4, (_) => GlobalKey<FormState>());
  int _currentStep = 0;

  bool get _isLastStep => _currentStep == _titles.length - 1;

  @override
  void dispose() {
    _data.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _goToStep(int step) {
    FocusScope.of(context).unfocus();
    setState(() => _currentStep = step);
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _onNext(BuildContext context) {
    if (_isLastStep) {
      _onSubmit(context);
      return;
    }
    if (!_formKeys[_currentStep].currentState!.validate()) return;
    // الصورة الشخصية مش جوه FormField فبنتأكد منها هنا
    if (_currentStep == 0 && _data.profileImage == null) {
      context.showErrorMessage('image_required'.tr());
      return;
    }
    _goToStep(_currentStep + 1);
  }

  void _onBack() {
    if (_currentStep > 0) {
      _goToStep(_currentStep - 1);
    } else if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRouter.login);
    }
  }

  void _onSubmit(BuildContext context) {
    context.read<RegisterBloc>().add(RegisterEvent(_data.toRequest()));
  }

  Widget _stepBody(int index) {
    final step = switch (index) {
      0 => PersonalInfoStep(data: _data),
      1 => IdentityStep(data: _data),
      2 => LicenseStep(data: _data),
      3 => VehicleStep(data: _data),
      _ => ReviewStep(data: _data),
    };
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 24.h),
      child: index < _formKeys.length
          ? Form(key: _formKeys[index], child: step)
          : step,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<RegisterBloc>()),
        BlocProvider(create: (_) => getIt<CityCubit>()..getCities()),
      ],
      child: PopScope(
        canPop: _currentStep == 0,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _goToStep(_currentStep - 1);
        },
        child: Scaffold(
          backgroundColor: AppColors.brandBgColor,
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 8.h),
                  child: RegisterStepHeader(
                    title: _titles[_currentStep],
                    currentStep: _currentStep,
                    totalSteps: _titles.length,
                    onBack: _onBack,
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _titles.length,
                    itemBuilder: (context, index) => _stepBody(index),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(5.w, 8.h, 5.w, 12.h),
                  child: BlocConsumer<RegisterBloc, BaseState<RegisterModel>>(
                    listener: (context, state) {
                      if (state.isSuccess) {
                        context.showSuccessMessage(state.data?.message ?? '');
                        // replacement عشان الرجوع مايفتحش التسجيل تاني
                        // بعد ما الحساب اتعمل
                        final phone = state.data?.phoneNumber ?? '';
                        context.pushReplacement(
                          AppRouter.verifyOtp,
                          extra: OtpArgs(
                            phoneNumber: phone.isNotEmpty
                                ? phone
                                : _data.completePhone,
                            purpose: OtpPurpose.register,
                          ),
                        );
                      }
                      if (state.isFailure) {
                        context.showErrorMessage(state.errorMessage ?? '');
                      }
                    },
                    builder: (context, state) => state.isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primaryColor,
                            ),
                          )
                        : CustomButton(
                            onPressed: () => _onNext(context),
                            title: _isLastStep ? 'submit_register' : 'next',
                            borderRadius: 16.r,
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
