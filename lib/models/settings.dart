class AppSettings {
  final String currencyCode;
  final int? defaultCompanyId;
  final String language;
  final bool requireAuth;
  final String? pinCode;

  const AppSettings({
    this.currencyCode = 'RUB',
    this.defaultCompanyId,
    this.language = 'ru',
    this.requireAuth = false,
    this.pinCode,
  });

  Map<String, dynamic> toMap() {
    return {
      'currency_code': currencyCode,
      'default_company_id': defaultCompanyId,
      'language': language,
      'require_auth': requireAuth ? 1 : 0,
      'pin_code': pinCode,
    };
  }

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      currencyCode: map['currency_code'] ?? 'RUB',
      defaultCompanyId: map['default_company_id']?.toInt(),
      language: map['language'] ?? 'ru',
      requireAuth: (map['require_auth'] ?? 0) == 1,
      pinCode: map['pin_code'],
    );
  }

  AppSettings copyWith({
    String? currencyCode,
    int? defaultCompanyId,
    String? language,
    bool? requireAuth,
    String? pinCode,
  }) {
    return AppSettings(
      currencyCode: currencyCode ?? this.currencyCode,
      defaultCompanyId: defaultCompanyId ?? this.defaultCompanyId,
      language: language ?? this.language,
      requireAuth: requireAuth ?? this.requireAuth,
      pinCode: pinCode ?? this.pinCode,
    );
  }
}

class SettingKey {
  static const String currencyCode = 'currency_code';
  static const String defaultCompanyId = 'default_company_id';
  static const String language = 'language';
  static const String requireAuth = 'require_auth';
  static const String pinCode = 'pin_code';
}
