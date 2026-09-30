import 'package:lavanderia_delivery/features/trips/models/json_reader.dart';

/// الريسبونس بتاع collect و arrive: الـ OTP اللي المندوب بيوريه للمغسلة أو للعميل
class TripOtpModel {
  final String otpCode;
  final String message;

  const TripOtpModel({required this.otpCode, this.message = ''});

  /// postData بيبعت الريسبونس كامل، فبندور في data وفي الروت
  factory TripOtpModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    final otp = data is String || data is num
        ? data.toString()
        : json.pickString(['otpCode', 'otp', 'code'], inside: ['data']);
    final message = json['message'];
    return TripOtpModel(
      otpCode: otp,
      message: message is String ? message : '',
    );
  }
}
