import 'package:lavanderia_delivery/core/helpers/generic_data_source.dart';
import 'package:lavanderia_delivery/core/http/either.dart';
import 'package:lavanderia_delivery/core/http/endpoints.dart';
import 'package:lavanderia_delivery/core/http/failure.dart';
import 'package:lavanderia_delivery/features/profile/models/contact_info_model.dart';
import 'package:lavanderia_delivery/features/profile/models/privacy_policy_model.dart';

/// بيانات عامة بتتغير من لوحة التحكم: التواصل وسياسة الخصوصية
abstract interface class AppInfoDataSource {
  Future<Either<Failure, ContactInfoModel>> getContacts();
  Future<Either<Failure, PrivacyPolicyModel>> getPrivacyPolicy();
}

class AppInfoDataSourceImpl implements AppInfoDataSource {
  final GenericDataSource _genericDataSource;
  AppInfoDataSourceImpl(this._genericDataSource);

  @override
  Future<Either<Failure, ContactInfoModel>> getContacts() async {
    return _genericDataSource.fetchResult<ContactInfoModel>(
      endpoint: Endpoints.contacts,
      fromJson: ContactInfoModel.fromJson,
    );
  }

  @override
  Future<Either<Failure, PrivacyPolicyModel>> getPrivacyPolicy() async {
    return _genericDataSource.fetchResult<PrivacyPolicyModel>(
      endpoint: Endpoints.privacyPolicy,
      fromJson: PrivacyPolicyModel.fromJson,
    );
  }
}
