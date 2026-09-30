import 'package:lavanderia_delivery/core/bloc/genaric_pagination.dart';
import 'package:lavanderia_delivery/core/http/either.dart';
import 'package:lavanderia_delivery/core/http/failure.dart';
import 'package:lavanderia_delivery/features/wallet/data/wallet_data_source.dart';
import 'package:lavanderia_delivery/features/wallet/models/wallet_transaction_model.dart';

/// حركات المحفظة بالصفحات. الصفحة كبيرة شوية عشان إحصائيات الأسبوع والشهر
/// بتتحسب منها لو الباك مابيرجعهاش مع الرصيد
class WalletTransactionsCubit
    extends GenericPaginationCubit<WalletTransactionModel> {
  final WalletDataSource _dataSource;

  static const int _pageSize = 50;

  WalletTransactionsCubit(this._dataSource);

  @override
  Future<Either<Failure, dynamic>> loadPage(int page) {
    return _dataSource.getTransactions(pageIndex: page, pageSize: _pageSize);
  }
}
