import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lavanderia_delivery/core/bloc/base_bloc.dart';
import 'package:lavanderia_delivery/features/wallet/data/wallet_data_source.dart';
import 'package:lavanderia_delivery/features/wallet/models/wallet_model.dart';

/// رصيد المحفظة لشاشة الأرباح
class WalletCubit extends Cubit<BaseState<WalletModel>> {
  final WalletDataSource _dataSource;

  WalletCubit(this._dataSource) : super(const BaseState<WalletModel>());

  Future<void> getWallet() async {
    emit(state.copyWith(status: Status.loading));

    final result = await _dataSource.getWallet();
    if (isClosed) return;
    result.fold(
      (failure) => emit(
        state.copyWith(status: Status.failure, errorMessage: failure.message),
      ),
      (data) => emit(state.copyWith(status: Status.success, data: data)),
    );
  }
}
