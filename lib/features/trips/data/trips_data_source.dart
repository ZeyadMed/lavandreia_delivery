import 'dart:io';

import 'package:lavanderia_delivery/core/helpers/generic_data_source.dart';
import 'package:lavanderia_delivery/core/http/either.dart';
import 'package:lavanderia_delivery/core/http/endpoints.dart';
import 'package:lavanderia_delivery/core/http/failure.dart';
import 'package:lavanderia_delivery/features/trips/models/delivery_trip_model.dart';
import 'package:lavanderia_delivery/features/trips/models/paged_model.dart';
import 'package:lavanderia_delivery/features/trips/models/trip_otp_model.dart';
import 'package:lavanderia_delivery/features/trips/models/trip_request_model.dart';

abstract interface class TripsDataSource {
  Future<Either<Failure, PagedModel<DeliveryTripModel>>> getAvailableTrips({
    required TripType type,
    required double latitude,
    required double longitude,
    required double radiusKm,
    required int pageIndex,
    required int pageSize,
  });

  Future<Either<Failure, void>> requestTrip({
    required int tripId,
    required double latitude,
    required double longitude,
    required double radiusKm,
  });

  Future<Either<Failure, PagedModel<TripRequestModel>>> getMyRequests({
    required int pageIndex,
    required int pageSize,
  });

  Future<Either<Failure, PagedModel<DeliveryTripModel>>> getMyTrips({
    required int pageIndex,
    required int pageSize,
  });

  Future<Either<Failure, TripOtpModel>> collect({
    required int tripId,
    required List<File> photos,
  });

  Future<Either<Failure, TripOtpModel>> arrive(int tripId);

  Future<Either<Failure, void>> setAvailability(bool isAvailable);
}

class TripsDataSourceImpl implements TripsDataSource {
  final GenericDataSource _genericDataSource;
  TripsDataSourceImpl(this._genericDataSource);

  @override
  Future<Either<Failure, PagedModel<DeliveryTripModel>>> getAvailableTrips({
    required TripType type,
    required double latitude,
    required double longitude,
    required double radiusKm,
    required int pageIndex,
    required int pageSize,
  }) {
    return _genericDataSource.fetchResult<PagedModel<DeliveryTripModel>>(
      endpoint: Endpoints.availableTrips,
      queryParameters: {
        'type': type.apiValue,
        'lat': latitude,
        'lng': longitude,
        'radiusKm': radiusKm,
        'PageIndex': pageIndex,
        'PageSize': pageSize,
      },
      fromJson: (json) => PagedModel.fromJson(
        json,
        itemFromJson: DeliveryTripModel.fromJson,
        pageIndex: pageIndex,
        pageSize: pageSize,
      ),
    );
  }

  @override
  Future<Either<Failure, void>> requestTrip({
    required int tripId,
    required double latitude,
    required double longitude,
    required double radiusKm,
  }) async {
    // postData<Null> بيعمل cast للريسبونس نفسه لـ Null فبيفشل، فبناخده Map ونسيبه
    final result = await _genericDataSource.postData<Map<String, dynamic>>(
      endpoint: Endpoints.requestTrip(tripId),
      data: {
        'latitude': latitude,
        'longitude': longitude,
        'radiusKm': radiusKm,
      },
      fromJson: (json) => json,
    );
    return result.fold((failure) => Left(failure), (_) => const Right(null));
  }

  @override
  Future<Either<Failure, PagedModel<TripRequestModel>>> getMyRequests({
    required int pageIndex,
    required int pageSize,
  }) {
    return _genericDataSource.fetchResult<PagedModel<TripRequestModel>>(
      endpoint: Endpoints.tripRequests,
      queryParameters: {'PageIndex': pageIndex, 'PageSize': pageSize},
      fromJson: (json) => PagedModel.fromJson(
        json,
        itemFromJson: TripRequestModel.fromJson,
        pageIndex: pageIndex,
        pageSize: pageSize,
      ),
    );
  }

  @override
  Future<Either<Failure, PagedModel<DeliveryTripModel>>> getMyTrips({
    required int pageIndex,
    required int pageSize,
  }) {
    return _genericDataSource.fetchResult<PagedModel<DeliveryTripModel>>(
      endpoint: Endpoints.driverTrips,
      queryParameters: {'PageIndex': pageIndex, 'PageSize': pageSize},
      fromJson: (json) => PagedModel.fromJson(
        json,
        itemFromJson: DeliveryTripModel.fromJson,
        pageIndex: pageIndex,
        pageSize: pageSize,
      ),
    );
  }

  @override
  Future<Either<Failure, TripOtpModel>> collect({
    required int tripId,
    required List<File> photos,
  }) {
    return _genericDataSource.postFormData<TripOtpModel>(
      endpoint: Endpoints.collectTrip(tripId),
      data: {'photos': photos},
      repeatListKeys: true,
      fromJson: TripOtpModel.fromJson,
    );
  }

  @override
  Future<Either<Failure, TripOtpModel>> arrive(int tripId) {
    return _genericDataSource.postData<TripOtpModel>(
      endpoint: Endpoints.arriveTrip(tripId),
      fromJson: TripOtpModel.fromJson,
    );
  }

  @override
  Future<Either<Failure, void>> setAvailability(bool isAvailable) async {
    final result = await _genericDataSource.updateData<Null>(
      endpoint: Endpoints.driverAvailability,
      data: {'isAvailable': isAvailable},
    );
    return result.fold((failure) => Left(failure), (_) => const Right(null));
  }
}
