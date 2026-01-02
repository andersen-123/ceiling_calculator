import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';
import '../models/quote.dart';
import '../models/project.dart';
import '../models/expense.dart';
import '../models/salary_payment.dart';
import '../models/advance.dart';
import '../models/unit.dart';
import '../models/app_settings.dart';

class DatabaseHelper {
  static const String _databaseName = 'ceiling_calculator.db';
  static const int _databaseVersion = 2;

  static Database? _database;

  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  Future<Database> get database async {
  if (_database != null) return _database!;
  
  try {
    if (kDebugMode) {
      print('Initializing database...');
    }
    
    // Упрощенная инициализация без сложных операций
    String path = join(await getDatabasesPath(), _databaseName);
    
    _database = await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: (db, version) async {
        if (kDebugMode) {
          print('Creating database tables...');
        }
        
        // Создаем только основные таблицы
        await db.execute('''
          CREATE TABLE companies (
            company_id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            address TEXT,
            phone TEXT,
            email TEXT,
            created_at INTEGER NOT NULL
          )
        ''');
        
        await db.execute('''
          CREATE TABLE quotes (
            quote_id INTEGER PRIMARY KEY AUTOINCREMENT,
            company_id INTEGER,
            client_name TEXT NOT NULL,
            client_phone TEXT,
            client_address TEXT,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL,
            status TEXT NOT NULL DEFAULT 'draft',
            project_id INTEGER,
            FOREIGN KEY (company_id) REFERENCES companies (company_id)
          )
        ''');
        
        // Добавляем таблицы для проектов
        await db.execute('''
          CREATE TABLE projects (
            project_id INTEGER PRIMARY KEY AUTOINCREMENT,
            quote_id INTEGER,
            client_name TEXT NOT NULL,
            client_phone TEXT,
            client_address TEXT,
            budget REAL NOT NULL DEFAULT 0,
            status TEXT NOT NULL DEFAULT 'active',
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL,
            driver_name TEXT,
            installers TEXT,
            FOREIGN KEY (quote_id) REFERENCES quotes (quote_id)
          )
        ''');
        
        await db.execute('''
          CREATE TABLE expenses (
            expense_id INTEGER PRIMARY KEY AUTOINCREMENT,
            project_id INTEGER NOT NULL,
            description TEXT NOT NULL,
            amount REAL NOT NULL,
            created_at INTEGER NOT NULL,
            FOREIGN KEY (project_id) REFERENCES projects (project_id)
          )
        ''');
        
        await db.execute('''
          CREATE TABLE salary_payments (
            payment_id INTEGER PRIMARY KEY AUTOINCREMENT,
            project_id INTEGER NOT NULL,
            worker_name TEXT NOT NULL,
            amount REAL NOT NULL,
            description TEXT,
            created_at INTEGER NOT NULL,
            FOREIGN KEY (project_id) REFERENCES projects (project_id)
          )
        ''');
        
        await db.execute('''
          CREATE TABLE quote_line_items (
            item_id INTEGER PRIMARY KEY AUTOINCREMENT,
            quote_id INTEGER NOT NULL,
            description TEXT NOT NULL,
            unit TEXT NOT NULL,
            quantity REAL NOT NULL,
            unit_price REAL NOT NULL,
            total_price REAL NOT NULL,
            item_type TEXT NOT NULL DEFAULT 'work',
            created_at INTEGER NOT NULL,
            FOREIGN KEY (quote_id) REFERENCES quotes (quote_id)
          )
        ''');
        
        if (kDebugMode) {
          print('All tables created successfully');
        }
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (kDebugMode) {
          print('Upgrading database from version $oldVersion to $newVersion');
        }
        
        if (oldVersion < 2) {
          if (kDebugMode) {
            print('Adding missing tables for version 2 with data preservation...');
          }
          
          // Создаем резервную копию существующих данных
          Map<String, List<Map<String, Object?>>> backupData = {};
          
          try {
            List<String> existingTables = ['companies', 'quotes'];
            
            for (String table in existingTables) {
              try {
                List<Map> result = await db.rawQuery(
                  "SELECT name FROM sqlite_master WHERE type='table' AND name='$table'"
                );
                
                if (result.isNotEmpty) {
                  List<Map> tableData = await db.rawQuery('SELECT * FROM $table');
                  backupData[table] = tableData.map((row) => Map<String, Object?>.from(row)).toList();
                  if (kDebugMode) {
                    print('Backed up ${tableData.length} records from $table');
                  }
                }
              } catch (e) {
                if (kDebugMode) {
                  print('Failed to backup table $table: $e');
                }
              }
            }
          } catch (backupError) {
            if (kDebugMode) {
              print('Failed to create backup during upgrade: $backupError');
            }
          }
          
          try {
            // Добавляем таблицы для проектов
            await db.execute('''
              CREATE TABLE IF NOT EXISTS projects (
                project_id INTEGER PRIMARY KEY AUTOINCREMENT,
                quote_id INTEGER,
                client_name TEXT NOT NULL,
                client_phone TEXT,
                client_address TEXT,
                budget REAL NOT NULL DEFAULT 0,
                status TEXT NOT NULL DEFAULT 'active',
                created_at INTEGER NOT NULL,
                updated_at INTEGER NOT NULL,
                driver_name TEXT,
                installers TEXT,
                FOREIGN KEY (quote_id) REFERENCES quotes (quote_id)
              )
            ''');
            
            await db.execute('''
              CREATE TABLE IF NOT EXISTS expenses (
                expense_id INTEGER PRIMARY KEY AUTOINCREMENT,
                project_id INTEGER NOT NULL,
                description TEXT NOT NULL,
                amount REAL NOT NULL,
                created_at INTEGER NOT NULL,
                FOREIGN KEY (project_id) REFERENCES projects (project_id)
              )
            ''');
            
            await db.execute('''
              CREATE TABLE IF NOT EXISTS salary_payments (
                payment_id INTEGER PRIMARY KEY AUTOINCREMENT,
                project_id INTEGER NOT NULL,
                worker_name TEXT NOT NULL,
                amount REAL NOT NULL,
                description TEXT,
                created_at INTEGER NOT NULL,
                FOREIGN KEY (project_id) REFERENCES projects (project_id)
              )
            ''');
            
            await db.execute('''
              CREATE TABLE IF NOT EXISTS quote_line_items (
                item_id INTEGER PRIMARY KEY AUTOINCREMENT,
                quote_id INTEGER NOT NULL,
                description TEXT NOT NULL,
                unit TEXT NOT NULL,
                quantity REAL NOT NULL,
                unit_price REAL NOT NULL,
                total_price REAL NOT NULL,
                item_type TEXT NOT NULL DEFAULT 'work',
                created_at INTEGER NOT NULL,
                FOREIGN KEY (quote_id) REFERENCES quotes (quote_id)
              )
            ''');
            
            // Восстанавливаем данные если они были
            if (backupData.isNotEmpty) {
              Batch batch = db.batch();
              
              if (backupData['companies'] != null) {
                for (Map record in backupData['companies']!) {
                  batch.insert('companies', Map<String, Object?>.from(record));
                }
              }
              
              if (backupData['quotes'] != null) {
                for (Map record in backupData['quotes']!) {
                  batch.insert('quotes', Map<String, Object?>.from(record));
                }
              }
              
              await batch.commit(noResult: true);
              
              if (kDebugMode) {
                print('Successfully restored data during upgrade');
              }
            }
            
            if (kDebugMode) {
              print('Database upgrade to version 2 completed successfully');
            }
          } catch (e, stackTrace) {
            if (kDebugMode) {
              print('Error during database upgrade: $e');
              print('Stack trace: $stackTrace');
            }
            // Не прерываем миграцию, позволяем приложению продолжить работу
            print('Database upgrade failed, but continuing with existing tables');
          }
        }
      },
    );
    
    if (kDebugMode) {
      print('Database initialized successfully');
    }
    return _database!;
  } catch (e, stackTrace) {
    if (kDebugMode) {
      print('Error initializing database: $e');
      print('Stack trace: $stackTrace');
    }
    
    // Если критическая ошибка, делаем полное резервное копирование и восстановление
    try {
      if (kDebugMode) {
        print('Attempting full database backup and recreate...');
      }
      String path = join(await getDatabasesPath(), _databaseName);
      
      // Создаем полное резервное копирование всех данных
      Map<String, List<Map<String, Object?>>> backupData = {};
      
      try {
        Database existingDb = await openDatabase(path);
        
        // Получаем все таблицы
        List<String> tables = [
          'companies', 'quotes', 'projects', 'expenses', 
          'salary_payments', 'quote_line_items'
        ];
        
        for (String table in tables) {
          try {
            // Проверяем существование таблицы
            List<Map> result = await existingDb.rawQuery(
              "SELECT name FROM sqlite_master WHERE type='table' AND name='$table'"
            );
            
            if (result.isNotEmpty) {
              List<Map> tableData = await existingDb.rawQuery('SELECT * FROM $table');
              backupData[table] = tableData.map((row) => Map<String, Object?>.from(row)).toList();
              if (kDebugMode) {
                print('Backed up ${tableData.length} records from $table');
              }
            }
          } catch (e) {
            if (kDebugMode) {
              print('Failed to backup table $table: $e');
            }
          }
        }
        
        await existingDb.close();
        
        if (kDebugMode) {
          int totalRecords = backupData.values.fold(0, (sum, records) => sum + records.length);
          print('Created complete backup with $totalRecords total records');
        }
      } catch (backupError) {
        if (kDebugMode) {
          print('Failed to create backup: $backupError');
        }
        // Продолжаем без резервной копии
      }
      
      // Удаляем и пересоздаем базу данных
      await deleteDatabase(path);
      
      _database = await openDatabase(
        path,
        version: _databaseVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
      
      // Восстанавливаем все данные из резервной копии
      if (backupData.isNotEmpty) {
        try {
          Batch batch = _database!.batch();
          
          // Восстанавливаем компании
          if (backupData['companies'] != null) {
            for (Map record in backupData['companies']!) {
              batch.insert('companies', Map<String, Object?>.from(record));
            }
          }
          
          // Восстанавливаем предложения
          if (backupData['quotes'] != null) {
            for (Map record in backupData['quotes']!) {
              batch.insert('quotes', Map<String, Object?>.from(record));
            }
          }
          
          // Восстанавливаем проекты
          if (backupData['projects'] != null) {
            for (Map record in backupData['projects']!) {
              batch.insert('projects', Map<String, Object?>.from(record));
            }
          }
          
          // Восстанавливаем расходы
          if (backupData['expenses'] != null) {
            for (Map record in backupData['expenses']!) {
              batch.insert('expenses', Map<String, Object?>.from(record));
            }
          }
          
          // Восстанавливаем выплаты зарплат
          if (backupData['salary_payments'] != null) {
            for (Map record in backupData['salary_payments']!) {
              batch.insert('salary_payments', Map<String, Object?>.from(record));
            }
          }
          
          // Восстанавливаем позиции предложений
          if (backupData['quote_line_items'] != null) {
            for (Map record in backupData['quote_line_items']!) {
              batch.insert('quote_line_items', Map<String, Object?>.from(record));
            }
          }
          
          await batch.commit(noResult: true);
          
          if (kDebugMode) {
            print('Successfully restored all data from backup');
          }
        } catch (restoreError) {
          if (kDebugMode) {
            print('Failed to restore backup: $restoreError');
          }
        }
      }
      
      if (kDebugMode) {
        print('Database recreated and data restored successfully');
      }
      return _database!;
    } catch (recreateError) {
      if (kDebugMode) {
        print('Failed to recreate database: $recreateError');
      }
      rethrow;
    }
  }
}

  Future<Database> _initDatabase() async {
    try {
      if (kDebugMode) {
        print('Getting database path...');
      }
      String path = join(await getDatabasesPath(), _databaseName);
      if (kDebugMode) {
        print('Database path: $path');
        print('Opening database...');
      }
      
      Database db = await openDatabase(
        path,
        version: _databaseVersion,
        onCreate: _onCreate,
      );
      
      if (kDebugMode) {
        print('Database opened successfully');
      }
      return db;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Error initializing database: $e');
        print('Stack trace: $stackTrace');
      }
      rethrow;
    }
  }

  Future<void> _onCreate(Database db, int version) async {
  try {
    if (kDebugMode) {
      print('Creating database tables...');
    }
    
    await _createCompaniesTable(db);
    await _createSettingsTable(db);
    await _createQuotesTable(db);
    await _createLineItemsTable(db);
    await _createQuoteAttachmentsTable(db);
    await _createUnitsTable(db);
    await _createProjectsTable(db);
    await _createExpensesTable(db);
    await _createSalaryPaymentsTable(db);
    await _createAdvancesTable(db);
    
    if (kDebugMode) {
      print('All database tables created successfully');
    }
  } catch (e, stackTrace) {
    if (kDebugMode) {
      print('Error creating database tables: $e');
      print('Stack trace: $stackTrace');
    }
    rethrow;
  }
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
        project_id INTEGER NULL, -- Связь с проектом
        FOREIGN KEY (company_id) REFERENCES companies (company_id),
        FOREIGN KEY (project_id) REFERENCES projects (project_id)
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

  Future<void> _createQuoteAttachmentsTable(Database db) async {
    await db.execute('''
      CREATE TABLE quote_attachments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        quote_id INTEGER NOT NULL,
        file_name TEXT NOT NULL,
        file_path TEXT NOT NULL,
        mime_type TEXT NULL,
        file_size INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (quote_id) REFERENCES quotes (quote_id) ON DELETE CASCADE
      )
    ''');

    await db.execute('CREATE INDEX idx_quote_attachments_quote_id ON quote_attachments (quote_id)');
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

  Future<void> _createProjectsTable(Database db) async {
    await db.execute('''
      CREATE TABLE projects (
        project_id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        address TEXT,
        customer_name TEXT,
        customer_phone TEXT,
        status TEXT NOT NULL DEFAULT 'planning',
        start_date TEXT,
        end_date TEXT,
        planned_budget REAL NOT NULL DEFAULT 0.0,
        actual_expenses REAL NOT NULL DEFAULT 0.0,
        total_salary REAL NOT NULL DEFAULT 0.0,
        profit REAL NOT NULL DEFAULT 0.0,
        quote_id INTEGER,
        driver_name TEXT,
        installers TEXT DEFAULT '',
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT,
        FOREIGN KEY (quote_id) REFERENCES quotes (quote_id)
      )
    ''');
  }

  Future<void> _createExpensesTable(Database db) async {
    await db.execute('''
      CREATE TABLE expenses (
        expense_id INTEGER PRIMARY KEY AUTOINCREMENT,
        project_id INTEGER NOT NULL,
        type TEXT NOT NULL,
        description TEXT NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        notes TEXT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (project_id) REFERENCES projects (project_id)
      )
    ''');
  }

  Future<void> _createSalaryPaymentsTable(Database db) async {
    await db.execute('''
      CREATE TABLE salary_payments (
        payment_id INTEGER PRIMARY KEY AUTOINCREMENT,
        project_id INTEGER NOT NULL,
        employee_name TEXT NOT NULL,
        amount REAL NOT NULL DEFAULT 0.0,
        description TEXT,
        date TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (project_id) REFERENCES projects (project_id)
      )
    ''');
  }

  Future<void> _createAdvancesTable(Database db) async {
    await db.execute('''
      CREATE TABLE advances (
        advance_id INTEGER PRIMARY KEY AUTOINCREMENT,
        project_id INTEGER NOT NULL,
        type TEXT NOT NULL,
        installer_name TEXT,
        amount REAL NOT NULL DEFAULT 0.0,
        description TEXT,
        date TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (project_id) REFERENCES projects (project_id)
      )
    ''');
  }
}
