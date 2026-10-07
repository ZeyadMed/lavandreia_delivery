import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lavanderia_delivery/core/bloc/base_bloc.dart';
import 'package:lavanderia_delivery/core/http/either.dart';
import 'package:lavanderia_delivery/core/http/session.dart';
import 'package:lavanderia_delivery/features/profile/data/profile_data_source.dart';

/// بتحذف الحساب من الباك، وبعدها بتمسح الجلسة زي الخروج بالظبط
class DeleteAccountCubit extends Cubit<BaseState<void>> {
  final ProfileDataSource _profileDataSource;

  DeleteAccountCubit(this._profileDataSource) : super(const BaseState<void>());

  Future<void> deleteAccount() async {
    emit(const BaseState(status: Status.loading));

    final result = await _profileDataSource.deleteAccount();

    // عكس الخروج، لو الحذف فشل مابنمسحش الجلسة عشان الحساب لسه موجود
    if (result.isError) {
      emit(
        BaseState(status: Status.failure, errorMessage: result.throwError().message),
      );
      return;
    }

    await Session.clear();
    emit(const BaseState(status: Status.success));
  }
}
