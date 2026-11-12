import 'package:equatable/equatable.dart';

/// عنصر من كتالوج العربيات: هيكل أو نوع (ماركة) أو موديل أو فئة.
/// كلهم { id, name } والهيكل بيرجع imageUrl والنوع logoUrl
class CarCatalogItem extends Equatable {
  final int id;
  final String name;
  final String? imageUrl;

  const CarCatalogItem({required this.id, required this.name, this.imageUrl});

  factory CarCatalogItem.fromJson(Map<String, dynamic> json) {
    final image = json['imageUrl'] ?? json['logoUrl'];
    return CarCatalogItem(
      id: json['id'] ?? 0,
      name: json['name']?.toString() ?? '',
      imageUrl: image is String && image.isNotEmpty ? image : null,
    );
  }

  /// من البروفايل: الـ id والاسم بييجوا في حقول منفصلة، والقديم ممكن يبقى null
  static CarCatalogItem? fromProfile(int? id, String? name, [String? image]) =>
      id == null
      ? null
      : CarCatalogItem(id: id, name: name ?? '', imageUrl: image);

  @override
  List<Object?> get props => [id, name, imageUrl];
}

/// اختيار العربية بالترتيب: الهيكل ← النوع ← الموديل ← الفئة.
/// تغيير النوع بيمسح الموديل والفئة، وتغيير الموديل بيمسح الفئة
class CarSelection extends Equatable {
  /// اختياري
  final CarCatalogItem? bodyType;

  /// إجباري، ومعاه الموديل
  final CarCatalogItem? make;
  final CarCatalogItem? model;

  /// اختياري، ومابيظهرش لو الموديل ملوش فئات
  final CarCatalogItem? trim;

  const CarSelection({this.bodyType, this.make, this.model, this.trim});

  CarSelection withBodyType(CarCatalogItem? value) =>
      CarSelection(bodyType: value, make: make, model: model, trim: trim);

  CarSelection withMake(CarCatalogItem value) => value.id == make?.id
      ? this
      : CarSelection(bodyType: bodyType, make: value);

  CarSelection withModel(CarCatalogItem value) => value.id == model?.id
      ? this
      : CarSelection(bodyType: bodyType, make: make, model: value);

  CarSelection withTrim(CarCatalogItem? value) =>
      CarSelection(bodyType: bodyType, make: make, model: model, trim: value);

  @override
  List<Object?> get props => [bodyType, make, model, trim];
}
