import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/company.dart';
import '../models/quote.dart';
import '../models/line_item.dart';
import '../models/settings.dart';

class DatabaseHelper {
  static const String _databaseName = 'ceiling_calculator.db';
  static const int _databaseVersion = 1;

  static Database? _database;

  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await _createCompaniesTable(db);
    await _createSettingsTable(db);
    await _createQuotesTable(db);
    await _createLineItemsTable(db);
    await _createUnitsTable(db);
    await _insertDefaultData(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Миграции базы данных для будущих версий
  }

  Future<void> _createCompaniesTable(Database db) async {
    await db.execute('''
      CREATE TABLE companies (
        company_id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        logo_path TEXT NULL,
        phone TEXT NULL,
        email TEXT NULL,
        website TEXT NULL,
        address TEXT NULL,
        footer_note TEXT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> _createSettingsTable(Database db) async {
    await db.execute('''
      CREATE TABLE settings (
        setting_key TEXT PRIMARY KEY,
        setting_value TEXT NOT NULL
      )
    ''');
  }

  Future<void> _createQuotesTable(Database db) async {
    await db.execute('''
      CREATE TABLE quotes (
        quote_id INTEGER PRIMARY KEY AUTOINCREMENT,
        company_id INTEGER NOT NULL,
        customer_name TEXT NOT NULL,
        customer_phone TEXT NULL,
        customer_email TEXT NULL,
        object_name TEXT NULL,
        address TEXT NULL,
        area_s REAL NULL,
        perimeter_p REAL NULL,
        height_h REAL NULL,
        ceiling_system TEXT NULL,
        status TEXT NOT NULL DEFAULT 'draft',
        payment_terms TEXT NULL,
        installation_terms TEXT NULL,
        notes TEXT NULL,
        currency_code TEXT NOT NULL DEFAULT 'RUB',
        subtotal_work REAL NOT NULL DEFAULT 0,
        subtotal_equipment REAL NOT NULL DEFAULT 0,
        total_amount REAL NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        deleted_at TEXT NULL,
        FOREIGN KEY (company_id) REFERENCES companies (company_id)
      )
    ''');

    await db.execute('CREATE INDEX idx_quotes_status ON quotes (status)');
    await db.execute('CREATE INDEX idx_quotes_customer_name ON quotes (customer_name)');
    await db.execute('CREATE INDEX idx_quotes_address ON quotes (address)');
    await db.execute('CREATE INDEX idx_quotes_created_at ON quotes (created_at)');
  }

  Future<void> _createLineItemsTable(Database db) async {
    await db.execute('''
      CREATE TABLE line_items (
        line_item_id INTEGER PRIMARY KEY AUTOINCREMENT,
        quote_id INTEGER NOT NULL,
        position INTEGER NOT NULL,
        section TEXT NOT NULL,
        description TEXT NOT NULL,
        unit TEXT NOT NULL,
        quantity REAL NOT NULL DEFAULT 0,
        price REAL NOT NULL DEFAULT 0,
        amount REAL NOT NULL DEFAULT 0,
        note TEXT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (quote_id) REFERENCES quotes (quote_id) ON DELETE CASCADE
      )
    ''');

    await db.execute('CREATE INDEX idx_line_items_quote_id ON line_items (quote_id)');
    await db.execute('CREATE INDEX idx_line_items_section ON line_items (section)');
  }

  Future<void> _createUnitsTable(Database db) async {
    await db.execute('''
      CREATE TABLE units (
        unit_code TEXT PRIMARY KEY,
        display_name TEXT NOT NULL,
        sort_order INTEGER NOT NULL
      )
    ''');

    for (final unit in Unit.defaultUnits) {
      await db.insert('units', {
        'unit_code': unit.code,
        'display_name': unit.displayName,
        'sort_order': unit.sortOrder,
      });
    }
  }

  Future<void> _insertDefaultData(Database db) async {
    // Вставка компании по умолчанию
    await db.insert('companies', {
      'name': 'Моя компания',
      'phone': '+7 (999) 123-45-67',
      'email': 'info@example.com',
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });

    // Вставка настроек по умолчанию
    final defaultSettings = AppSettings();
    final companyId = Sqflite.firstIntValue(
      await db.rawQuery('SELECT company_id FROM companies LIMIT 1'),
    );

    await db.insert('settings', {
      'setting_key': SettingKey.currencyCode,
      'setting_value': defaultSettings.currencyCode,
    });

    await db.insert('settings', {
      'setting_key': SettingKey.defaultCompanyId,
      'setting_value': companyId?.toString() ?? '1',
    });

    await db.insert('settings', {
      'setting_key': SettingKey.language,
      'setting_value': defaultSettings.language,
    });

    await db.insert('settings', {
      'setting_key': SettingKey.requireAuth,
      'setting_value': defaultSettings.requireAuth ? '1' : '0',
    });
  }

  Future<int> insert(String table, Map<String, dynamic> values) async {
    final db = await database;
    return await db.insert(table, values);
  }

  Future<List<Map<String, dynamic>>> query(String table, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<dynamic>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    final db = await database;
    return await db.query(
      table,
      distinct: distinct,
      columns: columns,
      where: where,
      whereArgs: whereArgs,
      groupBy: groupBy,
      having: having,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );
  }

  Future<int> update(String table, Map<String, dynamic> values, {
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    final db = await database;
    return await db.update(table, values, where: where, whereArgs: whereArgs);
  }

  Future<int> delete(String table, {
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    final db = await database;
    return await db.delete(table, where: where, whereArgs: whereArgs);
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
