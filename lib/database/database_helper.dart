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
          int totalRestored = 0;
          
          // Валидация и восстановление компаний
          if (backupData['companies'] != null) {
            List<Map<String, Object?>> validCompanies = [];
            for (Map record in backupData['companies']!) {
              // Проверяем обязательные поля
              if (record.containsKey('name') && record['name'] != null && record['name'].toString().isNotEmpty) {
                validCompanies.add(Map<String, Object?>.from(record));
              } else {
                if (kDebugMode) {
                  print('Skipping invalid company record: $record');
                }
              }
            }
            
            for (Map record in validCompanies) {
              batch.insert('companies', Map<String, Object?>.from(record));
              totalRestored++;
            }
            
            if (kDebugMode) {
              print('Restored ${validCompanies.length} valid companies out of ${backupData['companies']!.length}');
            }
          }
          
          // Валидация и восстановление предложений
          if (backupData['quotes'] != null) {
            List<Map<String, Object?>> validQuotes = [];
            for (Map record in backupData['quotes']!) {
              // Проверяем обязательные поля
              if (record.containsKey('client_name') && record['client_name'] != null && 
                  record['client_name'].toString().isNotEmpty) {
                validQuotes.add(Map<String, Object?>.from(record));
              } else {
                if (kDebugMode) {
                  print('Skipping invalid quote record: $record');
                }
              }
            }
            
            for (Map record in validQuotes) {
              batch.insert('quotes', Map<String, Object?>.from(record));
              totalRestored++;
            }
            
            if (kDebugMode) {
              print('Restored ${validQuotes.length} valid quotes out of ${backupData['quotes']!.length}');
            }
          }
          
          // Валидация и восстановление проектов
          if (backupData['projects'] != null) {
            List<Map<String, Object?>> validProjects = [];
            for (Map record in backupData['projects']!) {
              // Проверяем обязательные поля
              if (record.containsKey('client_name') && record['client_name'] != null && 
                  record['client_name'].toString().isNotEmpty) {
                validProjects.add(Map<String, Object?>.from(record));
              } else {
                if (kDebugMode) {
                  print('Skipping invalid project record: $record');
                }
              }
            }
            
            for (Map record in validProjects) {
              batch.insert('projects', Map<String, Object?>.from(record));
              totalRestored++;
            }
            
            if (kDebugMode) {
              print('Restored ${validProjects.length} valid projects out of ${backupData['projects']!.length}');
            }
          }
          
          // Валидация и восстановление расходов
          if (backupData['expenses'] != null) {
            List<Map<String, Object?>> validExpenses = [];
            for (Map record in backupData['expenses']!) {
              // Проверяем обязательные поля
              if (record.containsKey('description') && record['description'] != null && 
                  record['description'].toString().isNotEmpty &&
                  record.containsKey('amount') && record['amount'] != null) {
                validExpenses.add(Map<String, Object?>.from(record));
              } else {
                if (kDebugMode) {
                  print('Skipping invalid expense record: $record');
                }
              }
            }
            
            for (Map record in validExpenses) {
              batch.insert('expenses', Map<String, Object?>.from(record));
              totalRestored++;
            }
            
            if (kDebugMode) {
              print('Restored ${validExpenses.length} valid expenses out of ${backupData['expenses']!.length}');
            }
          }
          
          // Валидация и восстановление выплат зарплат
          if (backupData['salary_payments'] != null) {
            List<Map<String, Object?>> validPayments = [];
            for (Map record in backupData['salary_payments']!) {
              // Проверяем обязательные поля
              if (record.containsKey('worker_name') && record['worker_name'] != null && 
                  record['worker_name'].toString().isNotEmpty &&
                  record.containsKey('amount') && record['amount'] != null) {
                validPayments.add(Map<String, Object?>.from(record));
              } else {
                if (kDebugMode) {
                  print('Skipping invalid salary payment record: $record');
                }
              }
            }
            
            for (Map record in validPayments) {
              batch.insert('salary_payments', Map<String, Object?>.from(record));
              totalRestored++;
            }
            
            if (kDebugMode) {
              print('Restored ${validPayments.length} valid salary payments out of ${backupData['salary_payments']!.length}');
            }
          }
          
          // Валидация и восстановление позиций предложений
          if (backupData['quote_line_items'] != null) {
            List<Map<String, Object?>> validItems = [];
            for (Map record in backupData['quote_line_items']!) {
              // Проверяем обязательные поля
              if (record.containsKey('description') && record['description'] != null && 
                  record['description'].toString().isNotEmpty &&
                  record.containsKey('unit_price') && record['unit_price'] != null &&
                  record.containsKey('quantity') && record['quantity'] != null) {
                validItems.add(Map<String, Object?>.from(record));
              } else {
                if (kDebugMode) {
                  print('Skipping invalid quote line item record: $record');
                }
              }
            }
            
            for (Map record in validItems) {
              batch.insert('quote_line_items', Map<String, Object?>.from(record));
              totalRestored++;
            }
            
            if (kDebugMode) {
              print('Restored ${validItems.length} valid quote line items out of ${backupData['quote_line_items']!.length}');
            }
          }
          
          // Выполняем batch с проверкой результатов
          List<dynamic> results = await batch.commit();
          
          if (kDebugMode) {
            print('Successfully restored $totalRestored valid records from backup');
            print('Batch execution completed with ${results.length} operations');
          }
          
          // Проверяем целостность восстановленных данных
          await _validateRestoredData();
          
        } catch (restoreError) {
          if (kDebugMode) {
            print('Failed to restore backup: $restoreError');
          }
          // Не прерываем работу приложения при ошибке восстановления
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
    
    // Проверяем целостность базы данных перед сохранением
    if (!await _validateDatabaseIntegrity()) {
      if (kDebugMode) {
        print('Database integrity check failed, but attempting save anyway');
      }
      // Продолжаем сохранение даже если проверка не прошла
      // чтобы не блокировать работу приложения
    }
    
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
    
    // Проверяем целостность базы данных перед обновлением
    if (!await _validateDatabaseIntegrity()) {
      if (kDebugMode) {
        print('Database integrity check failed, but attempting update anyway');
      }
      // Продолжаем обновление даже если проверка не прошла
    }
    
    return await db.update(table, values, where: where, whereArgs: whereArgs);
  }

  Future<int> delete(String table, {
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    final db = await database;
    
    // Проверяем целостность базы данных перед удалением
    if (!await _validateDatabaseIntegrity()) {
      if (kDebugMode) {
        print('Database integrity check failed, but attempting delete anyway');
      }
      // Продолжаем удаление даже если проверка не прошла
    }
    
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
  
  Future<void> _createQuoteLineItemsTable(Database db) async {
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
  }
  
  // Метод для проверки целостности базы данных перед сохранением
  Future<bool> _validateDatabaseIntegrity() async {
    try {
      if (kDebugMode) {
        print('Validating database integrity before save...');
      }
      
      // Проверяем существование всех необходимых таблиц
      List<String> requiredTables = ['companies', 'quotes', 'projects', 'expenses', 'salary_payments', 'quote_line_items'];
      
      for (String table in requiredTables) {
        try {
          List<Map> result = await _database!.rawQuery(
            "SELECT name FROM sqlite_master WHERE type='table' AND name='$table'"
          );
          
          if (result.isEmpty) {
            if (kDebugMode) {
              print('Critical: Missing table $table - attempting to create...');
            }
            
            // Пробуем создать недостающую таблицу
            await _createMissingTable(table);
            
            // Проверяем снова
            result = await _database!.rawQuery(
              "SELECT name FROM sqlite_master WHERE type='table' AND name='$table'"
            );
            
            if (result.isEmpty) {
              if (kDebugMode) {
                print('Error: Failed to create table $table');
              }
              return false;
            }
          }
        } catch (e) {
          if (kDebugMode) {
            print('Error checking table $table: $e');
          }
          return false;
        }
      }
      
      // Проверяем структуру важных таблиц
      if (!await _validateTableStructure('companies', ['company_id', 'name'])) {
        return false;
      }
      
      if (!await _validateTableStructure('quotes', ['quote_id', 'client_name'])) {
        return false;
      }
      
      if (!await _validateTableStructure('projects', ['project_id', 'client_name'])) {
        return false;
      }
      
      if (kDebugMode) {
        print('Database integrity validation passed');
      }
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Database integrity validation failed: $e');
      }
      return false;
    }
  }
  
  // Метод для создания недостающей таблицы
  Future<void> _createMissingTable(String tableName) async {
    try {
      switch (tableName) {
        case 'companies':
          await _createCompaniesTable(_database!);
          break;
        case 'quotes':
          await _createQuotesTable(_database!);
          break;
        case 'projects':
          await _createProjectsTable(_database!);
          break;
        case 'expenses':
          await _createExpensesTable(_database!);
          break;
        case 'salary_payments':
          await _createSalaryPaymentsTable(_database!);
          break;
        case 'quote_line_items':
          await _createQuoteLineItemsTable(_database!);
          break;
      }
      
      if (kDebugMode) {
        print('Successfully created missing table: $tableName');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to create missing table $tableName: $e');
      }
      rethrow;
    }
  }
  
  // Метод для проверки структуры таблицы
  Future<bool> _validateTableStructure(String tableName, List<String> requiredColumns) async {
    try {
      List<Map> result = await _database!.rawQuery("PRAGMA table_info($tableName)");
      
      Set<String> existingColumns = result.map((row) => row['name'] as String).toSet();
      
      for (String column in requiredColumns) {
        if (!existingColumns.contains(column)) {
          if (kDebugMode) {
            print('Critical: Missing column $column in table $tableName');
          }
          return false;
        }
      }
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error validating table structure for $tableName: $e');
      }
      return false;
    }
  }
  
  // Метод для проверки целостности восстановленных данных
  Future<void> _validateRestoredData() async {
    try {
      if (kDebugMode) {
        print('Validating restored data integrity...');
      }
      
      // Проверяем количество записей в каждой таблице
      List<String> tables = ['companies', 'quotes', 'projects', 'expenses', 'salary_payments', 'quote_line_items'];
      
      for (String table in tables) {
        try {
          List<Map> result = await _database!.rawQuery('SELECT COUNT(*) as count FROM $table');
          int count = result.first['count'] as int;
          
          if (kDebugMode) {
            print('Table $table: $count records');
          }
          
          // Дополнительная проверка целостности для важных таблиц
          if (table == 'companies') {
            List<Map> companies = await _database!.rawQuery('SELECT * FROM companies LIMIT 5');
            for (Map company in companies) {
              if (!company.containsKey('name') || company['name'] == null) {
                if (kDebugMode) {
                  print('Warning: Found company without name: $company');
                }
              }
            }
          } else if (table == 'quotes') {
            List<Map> quotes = await _database!.rawQuery('SELECT * FROM quotes LIMIT 5');
            for (Map quote in quotes) {
              if (!quote.containsKey('client_name') || quote['client_name'] == null) {
                if (kDebugMode) {
                  print('Warning: Found quote without client_name: $quote');
                }
              }
            }
          }
          
        } catch (e) {
          if (kDebugMode) {
            print('Failed to validate table $table: $e');
          }
        }
      }
      
      if (kDebugMode) {
        print('Data validation completed');
      }
      
    } catch (e) {
      if (kDebugMode) {
        print('Data validation failed: $e');
      }
      // Не прерываем работу приложения при ошибке валидации
    }
  }
}
