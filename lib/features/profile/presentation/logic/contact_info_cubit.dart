import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lavanderia_delivery/core/bloc/base_bloc.dart';
import 'package:lavanderia_delivery/features/profile/data/app_info_data_source.dart';
import 'package:lavanderia_delivery/features/profile/models/contact_info_model.dart';

/// بتجيب أرقام التواصل والإيميل لشاشة تواصل معنا
class ContactInfoCubit extends Cubit<BaseState<ContactInfoModel>> {
  final AppInfoDataSource _dataSource;

  ContactInfoCubit(this._dataSource)
    : super(const BaseState<ContactInfoModel>());

  Future<void> getContacts() async {
    emit(state.copyWith(status: Status.loading));

    final result = await _dataSource.getContacts();

    result.fold(
      (failure) => emit(
        state.copyWith(status: Status.failure, errorMessage: failure.message),
      ),
      (data) => emit(state.copyWith(status: Status.success, data: data)),
    );
  }
}
