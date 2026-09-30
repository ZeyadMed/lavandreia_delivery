import 'package:lavanderia_delivery/core/helpers/generic_data_source.dart';
import 'package:lavanderia_delivery/core/http/either.dart';
import 'package:lavanderia_delivery/core/http/endpoints.dart';
import 'package:lavanderia_delivery/core/http/failure.dart';
import 'package:lavanderia_delivery/features/trips/models/paged_model.dart';
import 'package:lavanderia_delivery/features/wallet/models/wallet_model.dart';
import 'package:lavanderia_delivery/features/wallet/models/wallet_transaction_model.dart';

abstract interface class WalletDataSource {
  Future<Either<Failure, WalletModel>> getWallet();
  Future<Either<Failure, PagedModel<WalletTransactionModel>>> getTransactions({
    required int pageIndex,
    required int pageSize,
  });
}

class WalletDataSourceImpl implements WalletDataSource {
  final GenericDataSource _genericDataSource;
  WalletDataSourceImpl(this._genericDataSource);

  @override
  Future<Either<Failure, WalletModel>> getWallet() {
    return _genericDataSource.fetchResult<WalletModel>(
      endpoint: Endpoints.driverWallet,
      fromJson: WalletModel.fromJson,
    );
  }

  @override
  Future<Either<Failure, PagedModel<WalletTransactionModel>>> getTransactions({
    required int pageIndex,
    required int pageSize,
  }) {
    return _genericDataSource.fetchResult<PagedModel<WalletTransactionModel>>(
      endpoint: Endpoints.walletTransactions,
      queryParameters: {'PageIndex': pageIndex, 'PageSize': pageSize},
      fromJson: (json) => PagedModel.fromJson(
        json,
        itemFromJson: WalletTransactionModel.fromJson,
        pageIndex: pageIndex,
        pageSize: pageSize,
      ),
    );
  }
}
