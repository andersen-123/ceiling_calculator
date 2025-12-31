import 'package:flutter/material.dart';
import '../models/quote.dart';
import '../database/database_helper.dart';
import '../widgets/quote_card.dart';
import 'quote_edit_screen.dart';
import 'import_screen.dart';
import 'project_list_screen.dart';

class QuoteListScreen extends StatefulWidget {
  const QuoteListScreen({super.key});

  @override
  State<QuoteListScreen> createState() => _QuoteListScreenState();
}

class _QuoteListScreenState extends State<QuoteListScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Quote> _quotes = [];
  List<Quote> _filteredQuotes = [];
  bool _isLoading = true;
  QuoteStatus? _selectedStatus;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadQuotes();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadQuotes() async {
    setState(() => _isLoading = true);
    
    try {
      final data = await DatabaseHelper.instance.query(
        'quotes',
        where: 'deleted_at IS NULL',
        orderBy: 'created_at DESC',
      );
      
      final quotes = data.map((map) => Quote.fromMap(map)).toList();
      
      setState(() {
        _quotes = quotes;
        _filteredQuotes = quotes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки: $e')),
        );
      }
    }
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      _applyFilters();
    });
  }

  void _applyFilters() {
    setState(() {
      _filteredQuotes = _quotes.where((quote) {
        final matchesSearch = _searchQuery.isEmpty ||
            quote.customerName.toLowerCase().contains(_searchQuery) ||
            (quote.objectName?.toLowerCase().contains(_searchQuery) ?? false) ||
            (quote.address?.toLowerCase().contains(_searchQuery) ?? false);
        
        final matchesStatus = _selectedStatus == null || quote.status == _selectedStatus;
        
        return matchesSearch && matchesStatus;
      }).toList();
    });
  }

  Future<void> _navigateToImport() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const ImportScreen()),
    );
    
    if (result == true) {
      _loadQuotes(); // Обновляем список после импорта
    }
  }

  Future<void> _deleteQuote(Quote quote) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить предложение?'),
        content: Text('Предложение для "${quote.customerName}" будет удалено.'),
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
          'quotes',
          {'deleted_at': DateTime.now().toIso8601String()},
          where: 'quote_id = ?',
          whereArgs: [quote.id],
        );
        
        await _loadQuotes();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Предложение удалено')),
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
      appBar: AppBar(
        title: const Text('Коммерческие предложения'),
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
            icon: const Icon(Icons.business_outlined, color: Color(0xFF007AFF)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProjectListScreen()),
              );
            },
            tooltip: 'Учет объектов',
          ),
          IconButton(
            icon: const Icon(Icons.cloud_upload_outlined, color: Color(0xFF007AFF)),
            onPressed: _navigateToImport,
            tooltip: 'Импорт из XLSX',
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF86868B)),
            onPressed: _loadQuotes,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchAndFilters(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredQuotes.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredQuotes.length,
                        itemBuilder: (context, index) {
                          final quote = _filteredQuotes[index];
                          return QuoteCard(
                            quote: quote,
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => QuoteEditScreen(quote: quote),
                                ),
                              );
                              _loadQuotes();
                            },
                            onEdit: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => QuoteEditScreen(quote: quote),
                                ),
                              );
                              _loadQuotes();
                            },
                            onDelete: () => _deleteQuote(quote),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              hintText: 'Поиск по клиенту, объекту, адресу...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('Статус: ', style: TextStyle(fontWeight: FontWeight.bold)),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        label: const Text('Все'),
                        selected: _selectedStatus == null,
                        onSelected: (selected) {
                          setState(() {
                            _selectedStatus = selected ? null : _selectedStatus;
                            _applyFilters();
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      ...QuoteStatus.values.map((status) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(status.displayName),
                            selected: _selectedStatus == status,
                            onSelected: (selected) {
                              setState(() {
                                _selectedStatus = selected ? status : null;
                                _applyFilters();
                              });
                            },
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.description_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty || _selectedStatus != null
                ? 'Ничего не найдено'
                : 'Нет коммерческих предложений',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          if (_searchQuery.isEmpty && _selectedStatus == null) ...[
            const SizedBox(height: 8),
            Text(
              'Нажмите "Создать" для добавления первого предложения',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
