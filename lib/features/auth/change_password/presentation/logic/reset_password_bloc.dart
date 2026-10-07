import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lavanderia_delivery/core/bloc/base_bloc.dart';
import 'package:lavanderia_delivery/features/auth/change_password/presentation/logic/reset_password_event.dart';
import 'package:lavanderia_delivery/features/auth/forget_password/data/forget_password_data_source.dart';

/// بيغير كلمة المرور بالكود اللي وصل من forgot-password، والـ data هي رسالة الباك
class ResetPasswordBloc extends Bloc<ResetPasswordEvent, BaseState<String>> {
  final ForgetPasswordDataSource _forgetPasswordDataSource;

  ResetPasswordBloc(this._forgetPasswordDataSource) : super(BaseState()) {
    on<ResetPasswordEvent>(_onResetPasswordEvent);
  }

  Future<void> _onResetPasswordEvent(
    ResetPasswordEvent event,
    Emitter<BaseState<String>> emit,
  ) async {
    emit(BaseState(status: Status.loading));

    final result = await _forgetPasswordDataSource.resetPassword(
      phoneNumber: event.phoneNumber,
      code: event.code,
      newPassword: event.newPassword,
    );

    result.fold(
      (failure) => emit(
        BaseState(status: Status.failure, errorMessage: failure.message),
      ),
      (message) => emit(BaseState(status: Status.success, data: message)),
    );
  }
}
