import 'package:lavanderia_delivery/core/bloc/genaric_pagination.dart';
import 'package:lavanderia_delivery/core/http/either.dart';
import 'package:lavanderia_delivery/core/http/failure.dart';
import 'package:lavanderia_delivery/features/trips/data/trips_data_source.dart';
import 'package:lavanderia_delivery/features/trips/models/delivery_trip_model.dart';

/// رحلات المندوب كلها بالصفحات (الشغالة والمنتهية) لشاشة الرحلات.
/// الـ API مفيهوش فلتر بالحالة، فالفلتر بيتطبق في الشاشة على اللي اتحمل
class MyTripsCubit extends GenericPaginationCubit<DeliveryTripModel> {
  final TripsDataSource _dataSource;

  static const int _pageSize = 20;

  MyTripsCubit(this._dataSource);

  @override
  Future<Either<Failure, dynamic>> loadPage(int page) {
    return _dataSource.getMyTrips(pageIndex: page, pageSize: _pageSize);
  }
}
