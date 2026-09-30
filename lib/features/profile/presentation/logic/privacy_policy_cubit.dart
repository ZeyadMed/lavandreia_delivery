import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lavanderia_delivery/core/bloc/base_bloc.dart';
import 'package:lavanderia_delivery/features/profile/data/app_info_data_source.dart';
import 'package:lavanderia_delivery/features/profile/models/privacy_policy_model.dart';

/// بتجيب سياسة الخصوصية لشاشة سياسة الخصوصية
class PrivacyPolicyCubit extends Cubit<BaseState<PrivacyPolicyModel>> {
  final AppInfoDataSource _dataSource;

  PrivacyPolicyCubit(this._dataSource)
    : super(const BaseState<PrivacyPolicyModel>());

  Future<void> getPrivacyPolicy() async {
    emit(state.copyWith(status: Status.loading));

    final result = await _dataSource.getPrivacyPolicy();

    result.fold(
      (failure) => emit(
        state.copyWith(status: Status.failure, errorMessage: failure.message),
      ),
      (data) => emit(state.copyWith(status: Status.success, data: data)),
    );
  }
}
