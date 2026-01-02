import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/project.dart';
import '../models/quote.dart';
import '../database/database_helper.dart';
import 'project_edit_screen.dart';

class ProjectListScreen extends StatefulWidget {
  const ProjectListScreen({super.key});

  @override
  State<ProjectListScreen> createState() => _ProjectListScreenState();
}

class _ProjectListScreenState extends State<ProjectListScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Project> _projects = [];
  List<Quote> _quotes = []; // Загружаем предложения для отображения
  List<Project> _filteredProjects = [];
  bool _isLoading = true;
  ProjectStatus? _selectedStatus;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadProjects();
    _loadQuotes();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProjects() async {
    setState(() => _isLoading = true);
    
    try {
      final data = await DatabaseHelper.instance.query(
        'projects',
        where: 'deleted_at IS NULL',
        orderBy: 'created_at DESC',
      );
      
      final projects = data.map((map) => Project.fromMap(map)).toList();
      
      setState(() {
        _projects = projects;
        _filteredProjects = projects;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки проектов: $e')),
        );
      }
    }
  }

  Future<void> _loadQuotes() async {
    try {
      final data = await DatabaseHelper.instance.query(
        'quotes',
        where: 'deleted_at IS NULL',
        orderBy: 'created_at DESC',
      );
      
      final quotes = data.map((map) => Quote.fromMap(map)).toList();
      
      setState(() {
        _quotes = quotes;
      });
    } catch (e) {
      // Ошибка загрузки предложений
    }
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
      _applyFilters();
    });
  }

  void _applyFilters() {
    setState(() {
      _filteredProjects = _projects.where((project) {
        final matchesSearch = project.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            (project.customerName?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
            (project.address?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
        
        final matchesStatus = _selectedStatus == null || project.status == _selectedStatus;
        
        return matchesSearch && matchesStatus;
      }).toList();
    });
  }

  Future<void> _deleteProject(Project project) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить проект?'),
        content: Text('Проект "${project.name}" будет удален.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await DatabaseHelper.instance.update(
          'projects',
          {'deleted_at': DateTime.now().toIso8601String()},
          where: 'project_id = ?',
          whereArgs: [project.id],
        );
        
        await _loadProjects();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Проект удален')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ошибка удаления: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Учет объектов'),
        backgroundColor: Colors.white,
        elevation: 0,
        titleTextStyle: const TextStyle(
          color: Color(0xFF1D1D1F),
          fontWeight: FontWeight.w600,
          fontSize: 18,
        ),
        iconTheme: const IconThemeData(color: Color(0xFF007AFF)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF86868B)),
            onPressed: _loadProjects,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchAndFilters(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredProjects.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredProjects.length,
                        itemBuilder: (context, index) {
                          final project = _filteredProjects[index];
                          return _buildProjectCard(project);
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (context) => const ProjectEditScreen()),
          );
          if (result == true) {
            _loadProjects();
          }
        },
        backgroundColor: const Color(0xFF007AFF),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Поиск проектов...',
              prefixIcon: const Icon(Icons.search, color: Color(0xFF86868B)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE5E5E7)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF007AFF)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildStatusChip(null, 'Все'),
                ...ProjectStatus.values.map((status) => _buildStatusChip(status, status.label)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(ProjectStatus? status, String label) {
    final isSelected = _selectedStatus == status;
    
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedStatus = selected ? status : null;
            _applyFilters();
          });
        },
        backgroundColor: Colors.white,
        selectedColor: status?.color.withOpacity(0.2) ?? Colors.grey.withOpacity(0.2),
        labelStyle: TextStyle(
          color: isSelected ? (status?.color ?? Colors.grey) : const Color(0xFF86868B),
        ),
        side: BorderSide(
          color: isSelected ? (status?.color ?? Colors.grey) : const Color(0xFFE5E5E7),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.business_outlined,
            size: 64,
            color: const Color(0xFF86868B),
          ),
          const SizedBox(height: 16),
          Text(
            'Нет проектов',
            style: TextStyle(
              fontSize: 18,
              color: const Color(0xFF86868B),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Создайте новый проект для начала учета',
            style: TextStyle(
              fontSize: 14,
              color: const Color(0xFF86868B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectCard(Project project) {
    final profitMargin = project.plannedBudget > 0 
        ? ((project.profit / project.plannedBudget) * 100).toStringAsFixed(1)
        : '0.0';
    
    final relatedQuote = project.quoteId != null 
        ? _quotes.firstWhere((q) => q.id == project.quoteId, orElse: () => Quote.fromMap({}))
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E5E7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    project.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1D1D1F),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: project.status.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    project.status.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: project.status.color,
                    ),
                  ),
                ),
              ],
            ),
            if (project.customerName != null) ...[
              const SizedBox(height: 8),
              Text(
                'Клиент: ${project.customerName}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF86868B),
                ),
              ),
              const SizedBox(height: 4),
            ],
            
            // Связанное предложение
            if (relatedQuote != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.description, color: Colors.blue[700], size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'Предложение: ${relatedQuote!.objectName ?? 'Без названия'}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Сумма: ${currencyFormat.format(relatedQuote!.totalAmount)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.blue[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (project.address != null) ...[
              Text(
                'Адрес: ${project.address}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF86868B),
                ),
              ),
              const SizedBox(height: 4),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildInfoColumn(
                    'Бюджет',
                    '${project.plannedBudget.toStringAsFixed(0)} ₽',
                    const Color(0xFF007AFF),
                  ),
                ),
                Expanded(
                  child: _buildInfoColumn(
                    'Расходы',
                    '${project.actualExpenses.toStringAsFixed(0)} ₽',
                    const Color(0xFFFF9500),
                  ),
                ),
                Expanded(
                  child: _buildInfoColumn(
                    'Зарплата',
                    '${project.totalSalary.toStringAsFixed(0)} ₽',
                    const Color(0xFF34C759),
                  ),
                ),
                Expanded(
                  child: _buildInfoColumn(
                    'Прибыль',
                    '${project.profit.toStringAsFixed(0)} ₽',
                    project.profit >= 0 ? const Color(0xFF34C759) : const Color(0xFFFF3B30),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  'Маржа: $profitMargin%',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: double.parse(profitMargin) >= 0 ? const Color(0xFF34C759) : const Color(0xFFFF3B30),
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () async {
                    final result = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProjectEditScreen(project: project),
                      ),
                    );
                    if (result == true) {
                      _loadProjects();
                    }
                  },
                  child: const Text('Подробнее'),
                ),
                TextButton(
                  onPressed: () => _deleteProject(project),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFFF3B30),
                  ),
                  child: const Text('Удалить'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF86868B),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}
