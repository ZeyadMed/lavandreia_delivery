import 'package:lavanderia_delivery/core/bloc/base_bloc.dart';
import 'package:lavanderia_delivery/core/http/either.dart';
import 'package:lavanderia_delivery/core/http/failure.dart';
import 'package:lavanderia_delivery/features/auth/register/models/car_catalog_item.dart';

/// ليستة واحدة من كتالوج العربيات (هياكل، أنواع، موديلات أو فئات).
/// الـ loader بيتحدد وقت الإنشاء عشان نفس الكيوبت يخدم الأربع ليستات
class CarOptionsCubit extends BaseCubit<CarCatalogItem> {
  CarOptionsCubit(Future<Either<Failure, List<CarCatalogItem>>> Function() load)
    : super(fetchFunction: load);
}
