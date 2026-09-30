import 'package:equatable/equatable.dart';

/// بيانات التواصل اللي راجعة من GET api/auth/contacts
class ContactInfoModel extends Equatable {
  final String phoneNumber1;
  final String phoneNumber2;
  final String email;

  const ContactInfoModel({
    required this.phoneNumber1,
    required this.phoneNumber2,
    required this.email,
  });

  factory ContactInfoModel.fromJson(Map<String, dynamic> json) {
    return ContactInfoModel(
      phoneNumber1: json['phoneNumber1'] ?? '',
      phoneNumber2: json['phoneNumber2'] ?? '',
      email: json['email'] ?? '',
    );
  }

  @override
  List<Object?> get props => [phoneNumber1, phoneNumber2, email];
}
