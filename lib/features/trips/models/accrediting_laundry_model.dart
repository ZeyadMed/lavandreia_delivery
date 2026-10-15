import 'package:equatable/equatable.dart';
import 'package:lavanderia_delivery/features/trips/models/json_reader.dart';

/// مغسلة معتمدة المندوب (AccreditingLaundryDto). الاعتماد بيتعمل من تطبيق
/// المغسلة بس، فالمندوب بيعرضه وخلاص
class AccreditingLaundryModel extends Equatable {
  final int laundryId;
  final String laundryName;

  const AccreditingLaundryModel({
    required this.laundryId,
    required this.laundryName,
  });

  factory AccreditingLaundryModel.fromJson(Map<String, dynamic> json) {
    return AccreditingLaundryModel(
      laundryId: json.pickInt(['laundryId', 'id']) ?? 0,
      laundryName: json.pickString(['laundryName', 'name']).trim(),
    );
  }

  /// driverAccreditedBy دايمًا list، ولو ناقص (باك قديم) أو مش list بنرجع []
  static List<AccreditingLaundryModel> listFromJson(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(AccreditingLaundryModel.fromJson)
        .where((laundry) => laundry.laundryName.isNotEmpty)
        .toList();
  }

  @override
  List<Object?> get props => [laundryId, laundryName];
}
