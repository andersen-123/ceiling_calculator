import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
// import 'package:flutter/foundation.dart';
// import 'screens/main_screen.dart';

void main() async {
  print('=== SIMPLE APP STARTUP ===');
  
  try {
    WidgetsFlutterBinding.ensureInitialized();
    print('Flutter binding initialized');
    
    // Запускаем приложение без базы данных для теста
    print('Starting app without database...');
    runApp(const CeilingCalculatorApp());
    
  } catch (e, stackTrace) {
    print('=== SIMPLE APP ERROR ===');
    print('Error: $e');
    print('Stack trace: $stackTrace');
    print('========================');
  }
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
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            elevation: 2,
          ),
          cardTheme: const CardThemeData(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
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
        home: const SimpleMainScreen(),
      );
    } catch (e, stackTrace) {
      print('Error building MaterialApp: $e');
      print('Stack trace: $stackTrace');
      
      // Возвращаем максимально простой виджет в случае ошибки
      return MaterialApp(
        home: Scaffold(
          appBar: AppBar(title: const Text('Error')),
          body: Center(
            child: Text('Error: $e'),
          ),
        ),
      );
    }
  }
}

class SimpleMainScreen extends StatelessWidget {
  const SimpleMainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    print('Building SimpleMainScreen...');
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Калькулятор потолков'),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Приложение запустилось успешно!',
              style: TextStyle(fontSize: 20),
            ),
            SizedBox(height: 20),
            Text(
              'Это тестовая версия для проверки запуска',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
