import 'package:flutter_test/flutter_test.dart';
import 'package:lavanderia_delivery/features/auth/register/models/car_catalog_item.dart';
import 'package:lavanderia_delivery/features/profile/models/driver_profile_model.dart';
import 'package:lavanderia_delivery/features/profile/models/update_profile_request.dart';

void main() {
  const body = CarCatalogItem(id: 1, name: 'صالون / سيدان');
  const toyota = CarCatalogItem(id: 1, name: 'تويوتا');
  const corolla = CarCatalogItem(id: 101, name: 'كورولا');
  const xli = CarCatalogItem(id: 10101, name: 'XLI');
  const full = CarSelection(
    bodyType: body,
    make: toyota,
    model: corolla,
    trim: xli,
  );

  group('CarSelection', () {
    test('changing the make clears model and trim but keeps body type', () {
      final next = full.withMake(const CarCatalogItem(id: 2, name: 'نيسان'));
      expect(next.bodyType, body);
      expect(next.make?.id, 2);
      expect(next.model, isNull);
      expect(next.trim, isNull);
    });

    test('changing the model clears the trim only', () {
      final next = full.withModel(const CarCatalogItem(id: 102, name: 'كامري'));
      expect(next.make, toyota);
      expect(next.model?.id, 102);
      expect(next.trim, isNull);
    });

    test('re-picking the same make or model keeps everything', () {
      expect(full.withMake(toyota), full);
      expect(full.withModel(corolla), full);
    });
  });

  test('catalog item reads imageUrl or logoUrl', () {
    expect(
      CarCatalogItem.fromJson({'id': 3, 'name': 'x', 'logoUrl': 'a.png'})
          .imageUrl,
      'a.png',
    );
    expect(
      CarCatalogItem.fromJson({'id': 3, 'name': 'x', 'imageUrl': null})
          .imageUrl,
      isNull,
    );
  });

  test('profile fills the catalog selection, old accounts get none', () {
    final profile = DriverProfileModel.fromJson({
      'carBodyTypeId': 1,
      'carBodyTypeName': 'صالون / سيدان',
      'carMakeId': 1,
      'carModelId': 101,
      'carTrimId': 10101,
      'vehicleMake': 'تويوتا',
      'vehicleModel': 'كورولا',
      'vehicleTrim': 'XLI',
    });
    expect(profile.carSelection, full);

    final legacy = DriverProfileModel.fromJson({
      'vehicleMake': 'تويوتا',
      'vehicleModel': 'كورولا',
    });
    expect(legacy.carSelection, const CarSelection());
  });

  test('PUT always sends the four car ids, nulls included, no make text', () {
    const request = UpdateProfileRequest(
      fullName: 'a',
      address: 'b',
      cityId: 1,
      vehicleType: 'Car',
      carBodyTypeId: null,
      carMakeId: 1,
      carModelId: 101,
      carTrimId: null,
      vehicleYear: 2020,
      vehicleColor: 'white',
      plateNumber: '123',
    );
    final json = request.toJson();
    expect(json.containsKey('carBodyTypeId'), isTrue);
    expect(json.containsKey('carTrimId'), isTrue);
    expect(json['carMakeId'], 1);
    expect(json['carModelId'], 101);
    expect(json.containsKey('vehicleMake'), isFalse);
    expect(json.containsKey('vehicleModel'), isFalse);
  });
}
