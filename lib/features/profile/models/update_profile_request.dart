import 'package:equatable/equatable.dart';

/// البيانات اللي بتتبعت JSON لـ PUT api/driver/profile.
/// الـ PUT بيستبدل اختيار العربية كله، فحقول car* الأربعة بتتبعت دايمًا
/// حتى لو null (الهيكل بيتشال لو ماتبعتش)، ومابنبعتش vehicleMake و vehicleModel
/// لأن السيرفر بيملاهم من الكتالوج
class UpdateProfileRequest extends Equatable {
  final String fullName;
  final String address;
  final int cityId;
  final String vehicleType;
  final int? carBodyTypeId;
  final int carMakeId;
  final int carModelId;
  final int? carTrimId;
  final int vehicleYear;
  final String vehicleColor;
  final String plateNumber;

  const UpdateProfileRequest({
    required this.fullName,
    required this.address,
    required this.cityId,
    required this.vehicleType,
    required this.carBodyTypeId,
    required this.carMakeId,
    required this.carModelId,
    required this.carTrimId,
    required this.vehicleYear,
    required this.vehicleColor,
    required this.plateNumber,
  });

  Map<String, dynamic> toJson() => {
    'fullName': fullName,
    'address': address,
    'cityId': cityId,
    'vehicleType': vehicleType,
    'carBodyTypeId': carBodyTypeId,
    'carMakeId': carMakeId,
    'carModelId': carModelId,
    'carTrimId': carTrimId,
    'vehicleYear': vehicleYear,
    'vehicleColor': vehicleColor,
    'plateNumber': plateNumber,
  };

  @override
  List<Object?> get props => [
    fullName,
    address,
    cityId,
    vehicleType,
    carBodyTypeId,
    carMakeId,
    carModelId,
    carTrimId,
    vehicleYear,
    vehicleColor,
    plateNumber,
  ];
}
