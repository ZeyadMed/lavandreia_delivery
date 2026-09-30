import 'package:equatable/equatable.dart';

class VerifyPhoneEvent extends Equatable {
  final String phoneNumber;
  final String code;

  const VerifyPhoneEvent({required this.phoneNumber, required this.code});

  @override
  List<Object?> get props => [phoneNumber, code];
}
