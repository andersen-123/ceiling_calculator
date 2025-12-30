class AppConstants {
  // Приложение
  static const String appName = 'Калькулятор потолков';
  static const String appVersion = '1.0.0';
  
  // База данных
  static const String databaseName = 'ceiling_calculator.db';
  static const int databaseVersion = 1;
  
  // Валюты
  static const List<String> supportedCurrencies = [
    'RUB', 'USD', 'EUR', 'BYN', 'KZT', 'UZS',
  ];
  
  // Единицы измерения по умолчанию
  static const Map<String, String> defaultUnits = {
    'm2': 'м²',
    'mp': 'м.п.',
    'pcs': 'шт.',
    'kg': 'кг',
    'l': 'л',
  };
  
  // Типы потолков
  static const List<String> ceilingTypes = [
    'Гарпун',
    'Вставка по периметру',
    'Теневой',
    'Парящий',
    'Клипсовая',
  ];
  
  // Статусы предложений
  static const Map<String, String> quoteStatuses = {
    'draft': 'Черновик',
    'sent': 'Отправлено',
    'approved': 'Согласовано',
    'completed': 'Выполнено',
  };
  
  // Шаблоны условий оплаты
  static const List<String> paymentTemplates = [
    '50% предоплата за 3 дня до начала работ',
    '100% предоплата',
    '30% предоплата, 70% после завершения работ',
    'Оплата по факту выполнения работ',
  ];
  
  // Шаблоны описаний работ
  static const List<String> workDescriptionTemplates = [
    'MSD Premium белый матовый с монтажом',
    'Монтаж закладных под светильники',
    'Установка многоуровневого потолка',
    'Монтаж светильников',
    'Обвод труб и коммуникаций',
  ];
  
  // Шаблоны описаний оборудования
  static const List<String> equipmentDescriptionTemplates = [
    'Светильник LED 6W',
    'Светильник LED 12W',
    'Трековая система',
    'Профиль алюминиевый',
    'Закладная для люстры',
  ];
  
  // Форматы файлов
  static const String pdfExtension = '.pdf';
  static const String excelExtension = '.xlsx';
  static const String backupExtension = '.backup';
  
  // Ограничения
  static const int maxDescriptionLength = 500;
  static const int maxNoteLength = 200;
  static const int maxCustomerNameLength = 100;
  static const int maxAddressLength = 200;
  static const double maxQuantity = 999999.99;
  static const double maxPrice = 999999.99;
}
