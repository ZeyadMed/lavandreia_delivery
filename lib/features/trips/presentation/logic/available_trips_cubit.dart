import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:lavanderia_delivery/core/bloc/genaric_pagination.dart';
import 'package:lavanderia_delivery/core/helpers/location_service.dart';
import 'package:lavanderia_delivery/core/http/either.dart';
import 'package:lavanderia_delivery/core/http/failure.dart';
import 'package:lavanderia_delivery/core/realtime/realtime_event.dart';
import 'package:lavanderia_delivery/core/realtime/realtime_service.dart';
import 'package:lavanderia_delivery/features/trips/data/trips_data_source.dart';
import 'package:lavanderia_delivery/features/trips/models/delivery_trip_model.dart';
import 'package:lavanderia_delivery/features/trips/models/paged_model.dart';
import 'package:lavanderia_delivery/features/trips/models/trip_request_model.dart';

/// الرحلات المتاحة حوالين المندوب بالصفحات، تاب للاستلام وتاب للتسليم.
///
/// الموقع بيتجاب مع أول صفحة وكل refresh، والرحلات اللي طلبناها ولسه
/// مستنية المغسلة بتتعلّم عشان الكارت يعرض "في انتظار الموافقة"
class AvailableTripsCubit extends GenericPaginationCubit<DeliveryTripModel> {
  final TripsDataSource _dataSource;
  final LocationService _locationService;
  StreamSubscription<RealtimeEvent>? _subscription;

  static const int _pageSize = 20;

  /// TODO: نأكد مع الباك الـ default والـ max بتوع النطاق
  static const double radiusKm = 10;

  AvailableTripsCubit(
    this._dataSource,
    this._locationService,
    RealtimeService realtime,
  ) {
    _subscription = realtime.events.listen((event) {
      // رحلة جديدة نزلت، أو المغسلة اختارت مندوب فالرحلة خرجت من المتاح
      if (event.isNewTrip || event.isTripRequestResolved) refresh();
    });
  }

  TripType _type = TripType.pickup;
  LocationResult? _location;
  final Set<int> _requestedTripIds = {};

  TripType get type => _type;

  /// null لحد ما نحاول نجيب الموقع أول مرة
  LocationStatus? get locationStatus => _location?.status;

  void changeType(TripType type) {
    if (type == _type) return;
    _type = type;
    applyFilter(metadata: {'type': type.apiValue});
  }

  /// الـ refresh بيجيب الموقع من جديد لأن المندوب بيتحرك
  @override
  Future<void> refresh() {
    _location = null;
    return super.refresh();
  }

  @override
  Future<Either<Failure, dynamic>> loadPage(int page) async {
    if (_location?.isSuccess != true) {
      _location = await _locationService.getCurrentPosition();
    }
    final location = _location!;
    if (!location.isSuccess) {
      return Left(UnknownFailure(message: _locationMessage(location.status)));
    }

    if (page == 1) await _loadPendingRequests();

    final result = await _dataSource.getAvailableTrips(
      type: _type,
      latitude: location.latitude!,
      longitude: location.longitude!,
      radiusKm: radiusKm,
      pageIndex: page,
      pageSize: _pageSize,
    );
    return result.fold(
      (failure) => Left(failure),
      (paged) => Right(
        PagedModel<DeliveryTripModel>(
          items: paged.items.map(_markRequested).toList(),
          pagination: paged.pagination,
        ),
      ),
    );
  }

  /// طلباتنا اللي لسه Pending، عشان الـ badge يفضل ظاهر بعد ما التطبيق يتقفل ويتفتح
  Future<void> _loadPendingRequests() async {
    final result = await _dataSource.getMyRequests(pageIndex: 1, pageSize: 50);
    result.fold((_) {}, (paged) {
      _requestedTripIds
        ..clear()
        ..addAll(
          paged.items
              .where((request) => request.status == TripRequestStatus.pending)
              .map((request) => request.tripId),
        );
    });
  }

  DeliveryTripModel _markRequested(DeliveryTripModel trip) =>
      trip.isRequestedByMe || !_requestedTripIds.contains(trip.id)
      ? trip
      : trip.copyWith(isRequestedByMe: true);

  /// بترجع رسالة الخطأ أو null لو الطلب اتبعت
  Future<String?> requestTrip(DeliveryTripModel trip) async {
    final location = _location;
    if (location == null || !location.isSuccess) {
      return _locationMessage(location?.status ?? LocationStatus.failed);
    }

    final result = await _dataSource.requestTrip(
      tripId: trip.id,
      latitude: location.latitude!,
      longitude: location.longitude!,
      radiusKm: radiusKm,
    );
    return result.fold((failure) => failure.message, (_) {
      _requestedTripIds.add(trip.id);
      if (!isClosed) {
        emit(
          state.copyWith(
            items: [
              for (final item in state.items)
                item.id == trip.id
                    ? item.copyWith(isRequestedByMe: true)
                    : item,
            ],
          ),
        );
      }
      return null;
    });
  }

  Future<void> openLocationSettings() {
    return _location?.status == LocationStatus.serviceDisabled
        ? _locationService.openLocationSettings()
        : _locationService.openSettings();
  }

  String _locationMessage(LocationStatus status) => switch (status) {
    LocationStatus.serviceDisabled => 'location_service_disabled'.tr(),
    LocationStatus.denied ||
    LocationStatus.deniedForever => 'location_permission_required'.tr(),
    _ => 'location_failed'.tr(),
  };

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
