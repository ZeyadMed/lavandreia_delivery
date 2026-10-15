import 'package:lavanderia_delivery/features/trips/models/accrediting_laundry_model.dart';
import 'package:lavanderia_delivery/features/trips/models/delivery_trip_model.dart';
import 'package:lavanderia_delivery/features/trips/models/trip_request_model.dart';

extension AccreditationList on List<AccreditingLaundryModel> {
  /// الرحلة مافيهاش laundryId لسه، فبنقارن بالاسم. أول ما يرجع نقارن بيه هنا بس
  bool includesLaundry(String laundryName) {
    final name = _normalize(laundryName);
    if (name.isEmpty) return false;
    return any((laundry) => _normalize(laundry.laundryName) == name);
  }

  static String _normalize(String value) =>
      value.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
}

extension TripAccreditation on DeliveryTripModel {
  /// المغسلة بتاعة الرحلة معتمدة السواق المعيّن عليها
  bool get isAccreditedByTripLaundry =>
      driverAccreditedBy.includesLaundry(laundry.name);
}

extension RequestAccreditation on TripRequestModel {
  /// المغسلة صاحبة الرحلة اللي طلبناها معتمدانا
  bool get isAccreditedByTripLaundry =>
      driverAccreditedBy.includesLaundry(trip?.laundry.name ?? '');
}

/// مصدر قسم "معتمد من" لحد ما الحقل يرجع في البروفايل: الرحلة الحالية،
/// ولو مفيش آخر رحلة، ولو مفيش آخر طلب. الاعتماد بيتحسب وقت الريسبونس
/// فأي واحد فيهم بيجيب آخر بيانات، ولو مفيش ولا واحد يبقى مش معتمدين
List<AccreditingLaundryModel> resolveDriverAccreditation({
  DeliveryTripModel? currentTrip,
  DeliveryTripModel? latestTrip,
  TripRequestModel? latestRequest,
}) =>
    currentTrip?.driverAccreditedBy ??
    latestTrip?.driverAccreditedBy ??
    latestRequest?.driverAccreditedBy ??
    const [];
