import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:lavanderia_delivery/features/auth/register/models/city_model.dart';
import 'package:lavanderia_delivery/features/auth/register/models/driver_register_request.dart';

enum VehicleType {
  car('vehicle_car'),
  motorcycle('vehicle_motorcycle'),
  scooter('vehicle_scooter'),
  van('vehicle_van');

  /// مفتاح الترجمة اللي بيتعرض للمستخدم
  final String labelKey;
  const VehicleType(this.labelKey);
}

/// ألوان المركبة الأساسية، و other لما المستخدم يكتب اللون بنفسه
enum VehicleColor {
  white('color_white', Color(0xFFFFFFFF)),
  black('color_black', Color(0xFF000000)),
  silver('color_silver', Color(0xFFC0C0C0)),
  grey('color_grey', Color(0xFF808080)),
  red('color_red', Color(0xFFD32F2F)),
  blue('color_blue', Color(0xFF1976D2)),
  green('color_green', Color(0xFF388E3C)),
  yellow('color_yellow', Color(0xFFFBC02D)),
  brown('color_brown', Color(0xFF6D4C41)),
  beige('color_beige', Color(0xFFE8D8B8)),
  other('color_other', null);

  /// مفتاح الترجمة اللي بيتعرض للمستخدم
  final String labelKey;

  /// لون الدائرة اللي بتتعرض (null للـ other)
  final Color? color;
  const VehicleColor(this.labelKey, this.color);
}

/// كل بيانات خطوات التسجيل الخمسة في مكان واحد، عشان الداتا تفضل موجودة
/// لما المستخدم يرجع خطوة ولما نعرضها في شاشة المراجعة
class RegisterFormData {
  // الخطوة 1: المعلومات الشخصية
  File? profileImage;
  final nameController = TextEditingController();
  final phoneController = TextEditingController();

  /// الرقم كامل بكود الدولة (+218...)
  String completePhone = '';
  final passwordController = TextEditingController();

  // الخطوة 2: بيانات الهوية
  final nationalIdController = TextEditingController();
  final birthDateController = TextEditingController();
  DateTime? birthDate;

  /// من api/auth/cities، والـ id بتاعها هو اللي بيتبعت في CityId
  CityModel? city;
  final addressController = TextEditingController();
  File? idFrontImage;
  File? idBackImage;

  // الخطوة 3: رخصة القيادة
  final licenseIssueDateController = TextEditingController();
  final licenseExpiryDateController = TextEditingController();
  DateTime? licenseIssueDate;
  DateTime? licenseExpiryDate;
  File? licenseFrontImage;
  File? licenseBackImage;

  // الخطوة 4: بيانات المركبة
  VehicleType vehicleType = VehicleType.car;
  final vehicleBrandController = TextEditingController();
  final vehicleModelController = TextEditingController();
  final manufactureYearController = TextEditingController();
  VehicleColor? vehicleColor;

  /// اللون اللي المستخدم بيكتبه لما يختار "لون آخر"
  final vehicleColorController = TextEditingController();

  /// قيمة اللون اللي بتتبعت: الـ key للألوان الأساسية أو النص اللي اتكتب
  String get vehicleColorValue => vehicleColor == VehicleColor.other
      ? vehicleColorController.text.trim()
      : vehicleColor?.name ?? '';
  final plateNumberController = TextEditingController();
  File? vehicleImage;

  /// بتتنادى بعد ما كل الخطوات تعدي الـ validate، فالحقول الإجبارية مش null
  DriverRegisterRequest toRequest() => DriverRegisterRequest(
    fullName: nameController.text.trim(),
    phoneNumber: completePhone,
    password: passwordController.text,
    profileImage: profileImage!,
    nationalId: nationalIdController.text.trim(),
    dateOfBirth: birthDate!,
    cityId: city!.id,
    address: addressController.text.trim(),
    nationalIdFrontImage: idFrontImage!,
    nationalIdBackImage: idBackImage!,
    licenseIssueDate: licenseIssueDate!,
    licenseExpiryDate: licenseExpiryDate!,
    licenseFrontImage: licenseFrontImage!,
    licenseBackImage: licenseBackImage!,
    vehicleType: vehicleType.name,
    vehicleMake: vehicleBrandController.text.trim(),
    vehicleModel: vehicleModelController.text.trim(),
    vehicleYear: int.parse(manufactureYearController.text.trim()),
    vehicleColor: vehicleColorValue,
    plateNumber: plateNumberController.text.trim(),
    vehicleImage: vehicleImage!,
  );

  void dispose() {
    for (final controller in [
      nameController,
      phoneController,
      passwordController,
      nationalIdController,
      birthDateController,
      addressController,
      licenseIssueDateController,
      licenseExpiryDateController,
      vehicleBrandController,
      vehicleModelController,
      manufactureYearController,
      vehicleColorController,
      plateNumberController,
    ]) {
      controller.dispose();
    }
  }
}
