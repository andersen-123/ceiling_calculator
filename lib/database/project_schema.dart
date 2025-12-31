import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';

class ProjectSchema {
  static Future<void> createTables(DatabaseHelper dbHelper) async {
    final db = await dbHelper.database;
    
    await db.execute('''
      CREATE TABLE IF NOT EXISTS projects (
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
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        deleted_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS expenses (
        expense_id INTEGER PRIMARY KEY AUTOINCREMENT,
        project_id INTEGER NOT NULL,
        type TEXT NOT NULL,
        description TEXT NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        notes TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (project_id) REFERENCES projects (project_id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS salary_payments (
        salary_id INTEGER PRIMARY KEY AUTOINCREMENT,
        project_id INTEGER NOT NULL,
        employee_name TEXT NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        work_description TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (project_id) REFERENCES projects (project_id) ON DELETE CASCADE
      )
    ''');

    // Создание индексов для быстрого поиска
    await db.execute('CREATE INDEX IF NOT EXISTS idx_projects_status ON projects(status)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_projects_created_at ON projects(created_at)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_expenses_project_id ON expenses(project_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_expenses_date ON expenses(date)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_salary_project_id ON salary_payments(project_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_salary_date ON salary_payments(date)');
  }
}
