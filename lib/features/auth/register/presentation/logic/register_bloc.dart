import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lavanderia_delivery/core/bloc/base_bloc.dart';
import 'package:lavanderia_delivery/features/auth/register/data/register_data_source.dart';
import 'package:lavanderia_delivery/features/auth/register/models/register_model.dart';
import 'package:lavanderia_delivery/features/auth/register/presentation/logic/register_event.dart';

class RegisterBloc extends Bloc<RegisterEvent, BaseState<RegisterModel>> {
  final RegisterDataSource _registerDataSource;

  RegisterBloc(this._registerDataSource) : super(BaseState()) {
    on<RegisterEvent>(_onRegisterEvent);
  }

  Future<void> _onRegisterEvent(
    RegisterEvent event,
    Emitter<BaseState<RegisterModel>> emit,
  ) async {
    emit(BaseState(status: Status.loading));

    final result = await _registerDataSource.register(event.request);

    result.fold(
      (failure) => emit(
        BaseState(status: Status.failure, errorMessage: failure.message),
      ),
      (data) => emit(BaseState(status: Status.success, data: data)),
    );
  }
}
