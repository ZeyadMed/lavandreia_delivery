import 'package:equatable/equatable.dart';
import 'package:lavanderia_delivery/features/trips/models/delivery_trip_model.dart';
import 'package:lavanderia_delivery/features/trips/models/json_reader.dart';

enum TripRequestStatus {
  pending,
  approved,
  rejected;

  static TripRequestStatus parse(dynamic value) {
    if (value is num) {
      return TripRequestStatus.values[value.toInt().clamp(0, 2)];
    }
    final text = value?.toString().toLowerCase() ?? '';
    if (text.contains('approv') || text.contains('accept')) return approved;
    if (text.contains('reject') || text.contains('cancel')) return rejected;
    return pending;
  }
}

/// طلب المندوب على رحلة، من GET api/driver/trips/requests
class TripRequestModel extends Equatable {
  final int id;
  final int tripId;
  final TripRequestStatus status;
  final DeliveryTripModel? trip;
  final DateTime? createdAt;

  const TripRequestModel({
    required this.id,
    required this.tripId,
    required this.status,
    this.trip,
    this.createdAt,
  });

  factory TripRequestModel.fromJson(Map<String, dynamic> json) {
    final tripJson = json.pickMap(['trip', 'deliveryTrip']);
    final trip = tripJson == null ? null : DeliveryTripModel.fromJson(tripJson);
    return TripRequestModel(
      id: json.pickInt(['id', 'requestId']) ?? 0,
      tripId: json.pickInt(['tripId', 'deliveryTripId']) ?? trip?.id ?? 0,
      status: TripRequestStatus.parse(json.pick(['status', 'requestStatus'])),
      trip: trip,
      createdAt: json.pickDate(['createdAt', 'requestedAt']),
    );
  }

  @override
  List<Object?> get props => [id, tripId, status, trip, createdAt];
}
