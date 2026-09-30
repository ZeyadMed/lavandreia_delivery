import 'package:equatable/equatable.dart';

class LoginEvent extends Equatable {
  final String phoneNumber;
  final String password;

  const LoginEvent({required this.phoneNumber, required this.password});

  @override
  List<Object?> get props => [phoneNumber, password];
}
