import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:equatable/equatable.dart';

/// بيانات تسجيل المندوب اللي بتتبعت form-data لـ api/auth/driver/register
class DriverRegisterRequest extends Equatable {
  final String fullName;
  final String phoneNumber;
  final String password;
  final File profileImage;
  final String nationalId;
  final DateTime dateOfBirth;
  final int cityId;
  final String address;
  final File nationalIdFrontImage;
  final File nationalIdBackImage;
  final DateTime licenseIssueDate;
  final DateTime licenseExpiryDate;
  final File licenseFrontImage;
  final File licenseBackImage;
  final String vehicleType;

  /// السيرفر بيملا vehicleMake و vehicleModel بنفسه من الكتالوج
  final int? carBodyTypeId;
  final int carMakeId;
  final int carModelId;
  final int? carTrimId;
  final int vehicleYear;
  final String vehicleColor;
  final String plateNumber;
  final File vehicleImage;

  const DriverRegisterRequest({
    required this.fullName,
    required this.phoneNumber,
    required this.password,
    required this.profileImage,
    required this.nationalId,
    required this.dateOfBirth,
    required this.cityId,
    required this.address,
    required this.nationalIdFrontImage,
    required this.nationalIdBackImage,
    required this.licenseIssueDate,
    required this.licenseExpiryDate,
    required this.licenseFrontImage,
    required this.licenseBackImage,
    required this.vehicleType,
    this.carBodyTypeId,
    required this.carMakeId,
    required this.carModelId,
    this.carTrimId,
    required this.vehicleYear,
    required this.vehicleColor,
    required this.plateNumber,
    required this.vehicleImage,
  });

  /// التواريخ yyyy-MM-dd بأرقام انجليزي عشان الباك يفكها كـ DateTime
  static String _date(DateTime date) =>
      DateFormat('yyyy-MM-dd', 'en').format(date);

  /// الـ File بيتحول MultipartFile جوه postFormData
  Map<String, dynamic> toFormData() => {
    'FullName': fullName,
    'PhoneNumber': phoneNumber,
    'Password': password,
    'ProfileImage': profileImage,
    'NationalId': nationalId,
    'DateOfBirth': _date(dateOfBirth),
    'CityId': cityId,
    'Address': address,
    'NationalIdFrontImage': nationalIdFrontImage,
    'NationalIdBackImage': nationalIdBackImage,
    'LicenseIssueDate': _date(licenseIssueDate),
    'LicenseExpiryDate': _date(licenseExpiryDate),
    'LicenseFrontImage': licenseFrontImage,
    'LicenseBackImage': licenseBackImage,
    'VehicleType': vehicleType,
    'CarBodyTypeId': ?carBodyTypeId,
    'CarMakeId': carMakeId,
    'CarModelId': carModelId,
    'CarTrimId': ?carTrimId,
    'VehicleYear': vehicleYear,
    'VehicleColor': vehicleColor,
    'PlateNumber': plateNumber,
    'VehicleImage': vehicleImage,
  };

  @override
  List<Object?> get props => [
    fullName,
    phoneNumber,
    password,
    profileImage.path,
    nationalId,
    dateOfBirth,
    cityId,
    address,
    nationalIdFrontImage.path,
    nationalIdBackImage.path,
    licenseIssueDate,
    licenseExpiryDate,
    licenseFrontImage.path,
    licenseBackImage.path,
    vehicleType,
    carBodyTypeId,
    carMakeId,
    carModelId,
    carTrimId,
    vehicleYear,
    vehicleColor,
    plateNumber,
    vehicleImage.path,
  ];
}
