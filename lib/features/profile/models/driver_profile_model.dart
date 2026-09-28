import 'dart:io';

class DriverProfileModel {
  final String name;
  final String phone;
  final String email;
  final String address;

  /// الصورة اللي المندوب اختارها من الجهاز، لسه ماتترفعتش
  final File? image;

  const DriverProfileModel({
    required this.name,
    required this.phone,
    required this.email,
    required this.address,
    this.image,
  });

  DriverProfileModel copyWith({
    String? name,
    String? phone,
    String? email,
    String? address,
    File? image,
  }) {
    return DriverProfileModel(
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      image: image ?? this.image,
    );
  }
}
