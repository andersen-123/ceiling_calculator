import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/foundation.dart';
import 'screens/main_screen.dart';
import 'database/database_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Добавляем детальное логирование для отладки крашей
  print('=== APP STARTUP DEBUG ===');
  print('Flutter binding initialized');
  
  try {
    if (kDebugMode) {
      print('Starting app with simplified database...');
    }
    
    print('Attempting database initialization...');
    // Упрощенная инициализация базы данных
    await DatabaseHelper.instance.database;
    print('Database initialized successfully');
    
    if (kDebugMode) {
      print('App started successfully');
    }
  } catch (e, stackTrace) {
    print('=== APP STARTUP ERROR ===');
    print('App startup failed: $e');
    print('Stack trace: $stackTrace');
    print('========================');
    
    // Запускаем приложение даже если база данных не работает
    print('Starting app without database...');
    runApp(const CeilingCalculatorApp());
    return;
  }
  
  print('Starting app with database...');
  runApp(const CeilingCalculatorApp());
}

class CeilingCalculatorApp extends StatelessWidget {
  const CeilingCalculatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    print('Building MaterialApp...');
    try {
      return MaterialApp(
        title: 'Калькулятор потолков',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF007AFF),
            foregroundColor: Colors.white,
            elevation: 2,
          ),
          cardTheme: CardTheme(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('ru', 'RU'),
        ],
        locale: const Locale('ru', 'RU'),
        home: const MainScreen(),
      );
    } catch (e, stackTrace) {
      print('Error building MaterialApp: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }
}
