import 'package:equatable/equatable.dart';

/// سياسة الخصوصية اللي راجعة من GET api/auth/privacy-policy
class PrivacyPolicyModel extends Equatable {
  /// HTML جاي من لوحة التحكم
  final String content;
  final DateTime? updatedAt;

  const PrivacyPolicyModel({required this.content, this.updatedAt});

  factory PrivacyPolicyModel.fromJson(Map<String, dynamic> json) {
    return PrivacyPolicyModel(
      content: json['content'] ?? '',
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? ''),
    );
  }

  @override
  List<Object?> get props => [content, updatedAt];
}
