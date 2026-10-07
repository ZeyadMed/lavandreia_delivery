import 'package:equatable/equatable.dart';

class ForgetPasswordEvent extends Equatable {
  final String phoneNumber;

  const ForgetPasswordEvent({required this.phoneNumber});

  @override
  List<Object?> get props => [phoneNumber];
}
