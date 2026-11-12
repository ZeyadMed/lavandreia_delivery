import 'package:lavanderia_delivery/core/helpers/generic_data_source.dart';
import 'package:lavanderia_delivery/core/http/either.dart';
import 'package:lavanderia_delivery/core/http/endpoints.dart';
import 'package:lavanderia_delivery/core/http/failure.dart';
import 'package:lavanderia_delivery/features/auth/register/models/car_catalog_item.dart';

/// كتالوج العربيات اللي المندوب بيختار منه في التسجيل وتعديل البروفايل.
/// الليستات صغيرة فبنجيبها كاملة والبحث بيحصل محلي في شاشة الاختيار
abstract interface class CarCatalogDataSource {
  Future<Either<Failure, List<CarCatalogItem>>> getBodyTypes();
  Future<Either<Failure, List<CarCatalogItem>>> getMakes();
  Future<Either<Failure, List<CarCatalogItem>>> getModels(int makeId);
  Future<Either<Failure, List<CarCatalogItem>>> getTrims(int modelId);
}

class CarCatalogDataSourceImpl implements CarCatalogDataSource {
  final GenericDataSource _genericDataSource;
  CarCatalogDataSourceImpl(this._genericDataSource);

  Future<Either<Failure, List<CarCatalogItem>>> _fetch(String endpoint) =>
      _genericDataSource.fetchData<CarCatalogItem>(
        endpoint: endpoint,
        // مفتوحة، والتسجيل بيحصل قبل ما يبقى فيه توكن
        headers: {'Authorization': null},
        fromJson: CarCatalogItem.fromJson,
      );

  @override
  Future<Either<Failure, List<CarCatalogItem>>> getBodyTypes() =>
      _fetch(Endpoints.carBodyTypes);

  @override
  Future<Either<Failure, List<CarCatalogItem>>> getMakes() =>
      _fetch(Endpoints.carMakes);

  @override
  Future<Either<Failure, List<CarCatalogItem>>> getModels(int makeId) =>
      _fetch(Endpoints.carModels(makeId));

  @override
  Future<Either<Failure, List<CarCatalogItem>>> getTrims(int modelId) =>
      _fetch(Endpoints.carTrims(modelId));
}
