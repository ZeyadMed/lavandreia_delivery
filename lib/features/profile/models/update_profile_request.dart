import 'package:equatable/equatable.dart';

/// البيانات اللي بتتبعت JSON لـ PUT api/driver/profile
class UpdateProfileRequest extends Equatable {
  final String fullName;
  final String address;
  final int cityId;
  final String vehicleType;
  final String vehicleMake;
  final String vehicleModel;
  final int vehicleYear;
  final String vehicleColor;
  final String plateNumber;

  const UpdateProfileRequest({
    required this.fullName,
    required this.address,
    required this.cityId,
    required this.vehicleType,
    required this.vehicleMake,
    required this.vehicleModel,
    required this.vehicleYear,
    required this.vehicleColor,
    required this.plateNumber,
  });

  Map<String, dynamic> toJson() => {
    'fullName': fullName,
    'address': address,
    'cityId': cityId,
    'vehicleType': vehicleType,
    'vehicleMake': vehicleMake,
    'vehicleModel': vehicleModel,
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
    vehicleMake,
    vehicleModel,
    vehicleYear,
    vehicleColor,
    plateNumber,
  ];
}
