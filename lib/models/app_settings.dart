class AppSettings {
  final String currencyCode;
  final int? defaultCompanyId;
  final String language;
  final bool requireAuth;

  AppSettings({
    this.currencyCode = 'RUB',
    this.defaultCompanyId,
    this.language = 'ru',
    this.requireAuth = false,
  });
}

enum SettingKey {
  currencyCode,
  defaultCompanyId,
  language,
  requireAuth,
}
