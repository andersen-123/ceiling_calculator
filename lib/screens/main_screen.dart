import 'package:flutter/material.dart';
import 'quote_list_screen.dart';
import 'project_list_screen.dart';
import 'quote_edit_screen.dart';
import 'project_edit_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Калькулятор потолков'),
        backgroundColor: const Color(0xFF007AFF),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600),
          tabs: const [
            Tab(
              icon: Icon(Icons.list_alt),
              text: 'Предложения',
            ),
            Tab(
              icon: Icon(Icons.business),
              text: 'Проекты',
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () {
              if (_tabController.index == 0) {
                // Добавляем предложение
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const QuoteEditScreen(),
                  ),
                );
              } else {
                // Добавляем проект
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProjectEditScreen(),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          QuoteListScreen(),
          ProjectListScreen(),
        ],
      ),
    );
  }
}
