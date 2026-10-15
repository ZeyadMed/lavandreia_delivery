import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lavanderia_delivery/core/bloc/base_bloc.dart';
import 'package:lavanderia_delivery/core/http/either.dart';
import 'package:lavanderia_delivery/core/http/failure.dart';
import 'package:lavanderia_delivery/features/trips/data/trips_data_source.dart';
import 'package:lavanderia_delivery/features/trips/models/accrediting_laundry_model.dart';
import 'package:lavanderia_delivery/features/trips/models/delivery_trip_model.dart';
import 'package:lavanderia_delivery/features/trips/models/driver_accreditation.dart';
import 'package:lavanderia_delivery/features/trips/models/trip_request_model.dart';

/// المغاسل اللي معتمدانا لقسم "معتمد من" في حسابي. مفيش endpoint للاعتمادية،
/// فبناخدها من الرحلة الحالية، ولو مفيش من آخر رحلة، ولو مفيش من آخر طلب.
/// لما الحقل يرجع في البروفايل يبقى هو المصدر الوحيد هنا
class DriverAccreditationCubit
    extends Cubit<BaseState<List<AccreditingLaundryModel>>> {
  final TripsDataSource _dataSource;

  DriverAccreditationCubit(this._dataSource)
    : super(const BaseState<List<AccreditingLaundryModel>>());

  Future<void> load() async {
    emit(state.copyWith(status: Status.loading));

    final current = await _dataSource.getCurrentTrip();
    if (_failed(current)) return;
    final currentTrip = current.getOrThrow();

    DeliveryTripModel? latestTrip;
    TripRequestModel? latestRequest;
    if (currentTrip == null) {
      final trips = await _dataSource.getMyTrips(pageIndex: 1, pageSize: 1);
      if (_failed(trips)) return;
      latestTrip = trips.getOrThrow().items.firstOrNull;
    }
    if (currentTrip == null && latestTrip == null) {
      final requests = await _dataSource.getMyRequests(
        pageIndex: 1,
        pageSize: 1,
      );
      if (_failed(requests)) return;
      latestRequest = requests.getOrThrow().items.firstOrNull;
    }

    emit(
      state.copyWith(
        status: Status.success,
        data: resolveDriverAccreditation(
          currentTrip: currentTrip,
          latestTrip: latestTrip,
          latestRequest: latestRequest,
        ),
      ),
    );
  }

  /// لو فشل بنوقف، والقسم مايظهرش بدل ما يقول إننا مش معتمدين
  bool _failed(Either<Failure, dynamic> result) {
    if (isClosed) return true;
    if (result.isSuccess) return false;
    final failure = result.throwError();
    emit(state.copyWith(status: Status.failure, errorMessage: failure.message));
    return true;
  }
}
