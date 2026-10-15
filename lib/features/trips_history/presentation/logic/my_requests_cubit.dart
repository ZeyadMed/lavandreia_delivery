import 'dart:async';

import 'package:lavanderia_delivery/core/bloc/genaric_pagination.dart';
import 'package:lavanderia_delivery/core/http/either.dart';
import 'package:lavanderia_delivery/core/http/failure.dart';
import 'package:lavanderia_delivery/core/realtime/realtime_event.dart';
import 'package:lavanderia_delivery/core/realtime/realtime_service.dart';
import 'package:lavanderia_delivery/features/trips/data/trips_data_source.dart';
import 'package:lavanderia_delivery/features/trips/models/trip_request_model.dart';

/// طلباتنا على الرحلات بالصفحات لتاب "طلباتي"، وبتتحدث لما المغسلة ترد
class MyRequestsCubit extends GenericPaginationCubit<TripRequestModel> {
  final TripsDataSource _dataSource;
  StreamSubscription<RealtimeEvent>? _subscription;

  static const int _pageSize = 20;

  MyRequestsCubit(this._dataSource, RealtimeService realtime) {
    _subscription = realtime.events.listen(_onRealtimeEvent);
  }

  void _onRealtimeEvent(RealtimeEvent event) {
    if (isClosed) return;
    if (event.isTripRequestResolved || event.isResync) refresh();
  }

  @override
  Future<Either<Failure, dynamic>> loadPage(int page) {
    return _dataSource.getMyRequests(pageIndex: page, pageSize: _pageSize);
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
