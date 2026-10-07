import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lavanderia_delivery/core/bloc/base_bloc.dart';
import 'package:lavanderia_delivery/features/auth/forget_password/data/forget_password_data_source.dart';
import 'package:lavanderia_delivery/features/auth/forget_password/presentation/logic/forget_password_event.dart';

/// بيطلب كود استعادة كلمة المرور، والـ data هي رسالة الباك
class ForgetPasswordBloc extends Bloc<ForgetPasswordEvent, BaseState<String>> {
  final ForgetPasswordDataSource _forgetPasswordDataSource;

  ForgetPasswordBloc(this._forgetPasswordDataSource) : super(BaseState()) {
    on<ForgetPasswordEvent>(_onForgetPasswordEvent);
  }

  Future<void> _onForgetPasswordEvent(
    ForgetPasswordEvent event,
    Emitter<BaseState<String>> emit,
  ) async {
    emit(BaseState(status: Status.loading));

    final result = await _forgetPasswordDataSource.forgotPassword(
      phoneNumber: event.phoneNumber,
    );

    result.fold(
      (failure) => emit(
        BaseState(status: Status.failure, errorMessage: failure.message),
      ),
      (message) => emit(BaseState(status: Status.success, data: message)),
    );
  }
}
