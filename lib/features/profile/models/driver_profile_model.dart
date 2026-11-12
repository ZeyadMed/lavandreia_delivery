import 'package:equatable/equatable.dart';
import 'package:lavanderia_delivery/features/auth/register/models/car_catalog_item.dart';
import 'package:lavanderia_delivery/features/auth/register/models/register_form_data.dart';

/// بيانات المندوب اللي راجعة من GET api/driver/profile
class DriverProfileModel extends Equatable {
  final int id;
  final String fullName;
  final String phoneNumber;
  final String? profileImageUrl;
  final String nationalId;
  final DateTime? dateOfBirth;
  final int cityId;
  final String cityName;
  final String address;
  final DateTime? licenseIssueDate;
  final DateTime? licenseExpiryDate;
  final String vehicleType;
  final String vehicleMake;
  final String vehicleModel;

  /// الفئة وحقول car* ممكن تبقى null للحسابات القديمة قبل الكتالوج
  final String? vehicleTrim;
  final int? carBodyTypeId;
  final String? carBodyTypeName;
  final String? carBodyTypeImageUrl;
  final int? carMakeId;
  final int? carModelId;
  final int? carTrimId;
  final int vehicleYear;
  final String vehicleColor;
  final String plateNumber;
  final String? vehicleImageUrl;
  final bool phoneNumberConfirmed;
  final bool isActive;
  final bool isAvailable;
  final DateTime? createdAt;

  const DriverProfileModel({
    required this.id,
    required this.fullName,
    required this.phoneNumber,
    this.profileImageUrl,
    required this.nationalId,
    this.dateOfBirth,
    required this.cityId,
    required this.cityName,
    required this.address,
    this.licenseIssueDate,
    this.licenseExpiryDate,
    required this.vehicleType,
    required this.vehicleMake,
    required this.vehicleModel,
    this.vehicleTrim,
    this.carBodyTypeId,
    this.carBodyTypeName,
    this.carBodyTypeImageUrl,
    this.carMakeId,
    this.carModelId,
    this.carTrimId,
    required this.vehicleYear,
    required this.vehicleColor,
    required this.plateNumber,
    this.vehicleImageUrl,
    required this.phoneNumberConfirmed,
    required this.isActive,
    required this.isAvailable,
    this.createdAt,
  });

  factory DriverProfileModel.fromJson(Map<String, dynamic> json) {
    return DriverProfileModel(
      id: json['id'] ?? 0,
      fullName: json['fullName'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      profileImageUrl: json['profileImageUrl'],
      nationalId: json['nationalId'] ?? '',
      dateOfBirth: DateTime.tryParse(json['dateOfBirth'] ?? ''),
      cityId: json['cityId'] ?? 0,
      cityName: json['cityName'] ?? '',
      address: json['address'] ?? '',
      licenseIssueDate: DateTime.tryParse(json['licenseIssueDate'] ?? ''),
      licenseExpiryDate: DateTime.tryParse(json['licenseExpiryDate'] ?? ''),
      vehicleType: json['vehicleType'] ?? '',
      vehicleMake: json['vehicleMake'] ?? '',
      vehicleModel: json['vehicleModel'] ?? '',
      vehicleTrim: json['vehicleTrim'],
      carBodyTypeId: json['carBodyTypeId'],
      carBodyTypeName: json['carBodyTypeName'],
      carBodyTypeImageUrl: json['carBodyTypeImageUrl'],
      carMakeId: json['carMakeId'],
      carModelId: json['carModelId'],
      carTrimId: json['carTrimId'],
      vehicleYear: json['vehicleYear'] ?? 0,
      vehicleColor: json['vehicleColor'] ?? '',
      plateNumber: json['plateNumber'] ?? '',
      vehicleImageUrl: json['vehicleImageUrl'],
      phoneNumberConfirmed: json['phoneNumberConfirmed'] ?? false,
      isActive: json['isActive'] ?? false,
      isAvailable: json['isAvailable'] ?? false,
      createdAt: DateTime.tryParse(json['createdAt'] ?? ''),
    );
  }

  /// الاختيار الحالي من الكتالوج عشان يتملا في شاشة التعديل.
  /// الموديل والفئة من غير النوع مالهمش معنى فبيتشالوا
  CarSelection get carSelection {
    final make = CarCatalogItem.fromProfile(carMakeId, vehicleMake);
    final model = make == null
        ? null
        : CarCatalogItem.fromProfile(carModelId, vehicleModel);
    return CarSelection(
      bodyType: CarCatalogItem.fromProfile(
        carBodyTypeId,
        carBodyTypeName,
        carBodyTypeImageUrl,
      ),
      make: make,
      model: model,
      trim: model == null
          ? null
          : CarCatalogItem.fromProfile(carTrimId, vehicleTrim),
    );
  }

  /// الباك بيرجع النوع "Car" والـ enum بتاعنا car، فبنقارن من غير حالة الحروف
  VehicleType get vehicleTypeEnum => VehicleType.values.firstWhere(
    (type) => type.name.toLowerCase() == vehicleType.toLowerCase(),
    orElse: () => VehicleType.car,
  );

  /// اللون بيتحفظ بالـ key للألوان الأساسية (black) أو بالنص اللي المندوب كتبه
  VehicleColor get vehicleColorEnum => VehicleColor.values.firstWhere(
    (color) =>
        color != VehicleColor.other &&
        color.name.toLowerCase() == vehicleColor.toLowerCase(),
    orElse: () => VehicleColor.other,
  );

  @override
  List<Object?> get props => [
    id,
    fullName,
    phoneNumber,
    profileImageUrl,
    nationalId,
    dateOfBirth,
    cityId,
    cityName,
    address,
    licenseIssueDate,
    licenseExpiryDate,
    vehicleType,
    vehicleMake,
    vehicleModel,
    vehicleTrim,
    carBodyTypeId,
    carBodyTypeName,
    carBodyTypeImageUrl,
    carMakeId,
    carModelId,
    carTrimId,
    vehicleYear,
    vehicleColor,
    plateNumber,
    vehicleImageUrl,
    phoneNumberConfirmed,
    isActive,
    isAvailable,
    createdAt,
  ];
}
