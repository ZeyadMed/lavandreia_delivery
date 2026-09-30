import 'package:equatable/equatable.dart';
import 'package:lavanderia_delivery/features/auth/register/models/driver_register_request.dart';

class RegisterEvent extends Equatable {
  final DriverRegisterRequest request;

  const RegisterEvent(this.request);

  @override
  List<Object?> get props => [request];
}
