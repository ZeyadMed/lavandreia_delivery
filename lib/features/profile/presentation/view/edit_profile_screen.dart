import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:lavanderia_delivery/core/bloc/base_bloc.dart';
import 'package:lavanderia_delivery/core/common_widget/custom_error_message.dart';
import 'package:lavanderia_delivery/core/common_widget/custom_success_message.dart';
import 'package:lavanderia_delivery/core/helpers/validators.dart';
import 'package:lavanderia_delivery/core/service_locator/service_locator.dart';
import 'package:lavanderia_delivery/core/style/app_colors.dart';
import 'package:lavanderia_delivery/core/theme/text_styles.dart';
import 'package:lavanderia_delivery/features/auth/register/models/city_model.dart';
import 'package:lavanderia_delivery/features/auth/register/models/register_form_data.dart';
import 'package:lavanderia_delivery/features/auth/register/presentation/logic/city_cubit.dart';
import 'package:lavanderia_delivery/features/auth/register/presentation/view/widget/register_form_widgets.dart';
import 'package:lavanderia_delivery/features/home/presentation/view/widget/home_colors.dart';
import 'package:lavanderia_delivery/features/profile/models/driver_profile_model.dart';
import 'package:lavanderia_delivery/features/profile/models/update_profile_request.dart';
import 'package:lavanderia_delivery/features/profile/presentation/logic/update_profile_cubit.dart';

/// شاشة تعديل الملف الشخصي: بتبعت التعديلات لـ PUT api/driver/profile
/// وبترجع true لشاشة حسابي لما الحفظ ينجح عشان تجيب البيانات من جديد
class EditProfileScreen extends StatelessWidget {
  final DriverProfileModel profile;

  const EditProfileScreen({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<UpdateProfileCubit>()),
        BlocProvider(create: (_) => getIt<CityCubit>()..getCities()),
      ],
      child: _EditProfileView(profile: profile),
    );
  }
}

class _EditProfileView extends StatefulWidget {
  final DriverProfileModel profile;

  const _EditProfileView({required this.profile});

  @override
  State<_EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<_EditProfileView> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(
    text: widget.profile.fullName,
  );
  late final _addressController = TextEditingController(
    text: widget.profile.address,
  );
  late final _makeController = TextEditingController(
    text: widget.profile.vehicleMake,
  );
  late final _modelController = TextEditingController(
    text: widget.profile.vehicleModel,
  );
  late final _yearController = TextEditingController(
    text: widget.profile.vehicleYear > 0 ? '${widget.profile.vehicleYear}' : '',
  );
  late final _plateController = TextEditingController(
    text: widget.profile.plateNumber,
  );
  late VehicleType _vehicleType = widget.profile.vehicleTypeEnum;
  late VehicleColor? _vehicleColor = widget.profile.vehicleColor.isEmpty
      ? null
      : widget.profile.vehicleColorEnum;

  /// النص اللي بيتكتب لما اللون "لون آخر"
  late final _otherColorController = TextEditingController(
    text: _vehicleColor == VehicleColor.other
        ? widget.profile.vehicleColor
        : '',
  );

  /// بتتحدد بعد ما المدن توصل، عشان الدروب داون مايتعرضش بقيمة مش في الليستة
  CityModel? _city;

  @override
  void dispose() {
    for (final controller in [
      _nameController,
      _addressController,
      _makeController,
      _modelController,
      _yearController,
      _plateController,
      _otherColorController,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  String? _yearValidator(String? value) {
    final empty = Validators.validateEmpty(value);
    if (empty != null) return empty;
    final year = int.tryParse(value!);
    if (year == null || year < 1980 || year > DateTime.now().year + 1) {
      return 'invalid_year'.tr();
    }
    return null;
  }

  void _onCitiesLoaded(BuildContext context, BaseState<CityModel> state) {
    if (!state.isSuccess || _city != null) return;
    final match = state.items.where((city) => city.id == widget.profile.cityId);
    if (match.isNotEmpty) setState(() => _city = match.first);
  }

  void _save(BuildContext context) {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final color = _vehicleColor == VehicleColor.other
        ? _otherColorController.text.trim()
        : _vehicleColor!.name;

    context.read<UpdateProfileCubit>().updateProfile(
      UpdateProfileRequest(
        fullName: _nameController.text.trim(),
        address: _addressController.text.trim(),
        cityId: _city!.id,
        // الباك بيرجع النوع بحرف كابيتال (Car) فبنبعته بنفس الشكل
        vehicleType:
            _vehicleType.name[0].toUpperCase() + _vehicleType.name.substring(1),
        vehicleMake: _makeController.text.trim(),
        vehicleModel: _modelController.text.trim(),
        vehicleYear: int.parse(_yearController.text.trim()),
        vehicleColor: color,
        plateNumber: _plateController.text.trim(),
      ),
    );
  }

  void _onUpdateState(BuildContext context, BaseState<void> state) {
    if (state.isSuccess) {
      CustomSuccessOverlay.show(context: context, text: 'profile_updated');
      context.pop(true);
    } else if (state.isFailure) {
      CustomErrorOverlay.show(context: context, text: state.errorMessage ?? '');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<UpdateProfileCubit, BaseState<void>>(
          listener: _onUpdateState,
        ),
        BlocListener<CityCubit, BaseState<CityModel>>(
          listener: _onCitiesLoaded,
        ),
      ],
      child: GestureDetector(
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
                    _ProfileImage(imageUrl: widget.profile.profileImageUrl),
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
                            CityDropdown(
                              value: _city,
                              onChanged: (city) => setState(() => _city = city),
                            ),
                            Gap(16.h),
                            _ProfileTextField(
                              label: 'address',
                              controller: _addressController,
                              validator: Validators.validateEmpty,
                            ),
                            const RegisterFieldLabel('vehicle_type'),
                            RegisterOptionSelector<VehicleType>(
                              options: VehicleType.values,
                              selected: _vehicleType,
                              labelOf: (type) => type.labelKey,
                              onSelected: (type) =>
                                  setState(() => _vehicleType = type),
                            ),
                            Gap(16.h),
                            _ProfileTextField(
                              label: 'vehicle_brand',
                              controller: _makeController,
                              validator: Validators.validateEmpty,
                            ),
                            _ProfileTextField(
                              label: 'vehicle_model',
                              controller: _modelController,
                              validator: Validators.validateEmpty,
                            ),
                            _ProfileTextField(
                              label: 'manufacture_year',
                              controller: _yearController,
                              keyboardType: TextInputType.number,
                              validator: _yearValidator,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(4),
                              ],
                            ),
                            VehicleColorSelector(
                              selected: _vehicleColor,
                              otherController: _otherColorController,
                              onSelected: (color) =>
                                  setState(() => _vehicleColor = color),
                            ),
                            Gap(16.h),
                            _ProfileTextField(
                              label: 'plate_number',
                              controller: _plateController,
                              validator: Validators.validateEmpty,
                            ),
                            Gap(8.h),
                            BlocBuilder<UpdateProfileCubit, BaseState<void>>(
                              builder: (context, state) => _SaveButton(
                                isLoading: state.isLoading,
                                onTap: () => _save(context),
                              ),
                            ),
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

/// صورة المندوب في دايرة بإطار أزرق، للعرض بس لأن الـ PUT مابيستقبلش صورة
class _ProfileImage extends StatelessWidget {
  final String? imageUrl;

  const _ProfileImage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final placeholder = Text('👤', style: TextStyle(fontSize: 42.sp));
    return Center(
      child: Container(
        width: 90.r,
        height: 90.r,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: HomeColors.lightBlue,
          border: Border.all(color: AppColors.primaryColor, width: 3),
        ),
        alignment: Alignment.center,
        child: imageUrl != null && imageUrl!.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: imageUrl!,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorWidget: (_, _, _) => placeholder,
              )
            : placeholder,
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
  final bool isLoading;
  final VoidCallback onTap;

  const _SaveButton({required this.isLoading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(16.r);
    return Material(
      color: AppColors.primaryColor,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        // بنقفل الزرار وقت الطلب عشان مايتبعتش مرتين
        onTap: isLoading ? null : onTap,
        child: SizedBox(
          height: 56.h,
          child: Center(
            child: isLoading
                ? SizedBox(
                    width: 22.r,
                    height: 22.r,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppColors.whiteColor,
                    ),
                  )
                : Text(
                    'save_changes'.tr(),
                    style: TextStyles.boldStyle(
                      16,
                      color: AppColors.whiteColor,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
