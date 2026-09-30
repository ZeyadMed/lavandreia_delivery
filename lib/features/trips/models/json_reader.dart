/// قراية مرنة للـ JSON لأن الـ swagger مش موضح شكل الريسبونس بتاع الرحلات
/// والمحفظة، فبندور على أكتر من اسم للحقل الواحد لحد ما نثبت الشكل الحقيقي
extension JsonReader on Map<String, dynamic> {
  /// أول قيمة مش null من المفاتيح دي، في الروت أو جوه الـ maps المتداخلة
  dynamic pick(List<String> keys, {List<String> inside = const []}) {
    for (final key in keys) {
      final value = this[key];
      if (value != null) return value;
    }
    for (final parent in inside) {
      final nested = this[parent];
      if (nested is Map<String, dynamic>) {
        final value = nested.pick(keys);
        if (value != null) return value;
      }
    }
    return null;
  }

  Map<String, dynamic>? pickMap(List<String> keys) {
    final value = pick(keys);
    return value is Map<String, dynamic> ? value : null;
  }

  String pickString(List<String> keys, {List<String> inside = const []}) =>
      pick(keys, inside: inside)?.toString() ?? '';

  int? pickInt(List<String> keys, {List<String> inside = const []}) =>
      asInt(pick(keys, inside: inside));

  double? pickDouble(List<String> keys, {List<String> inside = const []}) =>
      asDouble(pick(keys, inside: inside));

  DateTime? pickDate(List<String> keys, {List<String> inside = const []}) {
    final value = pick(keys, inside: inside);
    return value == null
        ? null
        : DateTime.tryParse(value.toString())?.toLocal();
  }
}

int? asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

double? asDouble(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

/// الليستة في الريسبونسات المتقسمة صفحات بتيجي في items أو data أو في الروت
List<Map<String, dynamic>> readList(dynamic json) {
  final raw = json is List
      ? json
      : json is Map<String, dynamic>
      ? json['items'] ?? json['data'] ?? json['trips'] ?? json['transactions']
      : null;
  if (raw is! List) return const [];
  return raw.whereType<Map<String, dynamic>>().toList();
}
