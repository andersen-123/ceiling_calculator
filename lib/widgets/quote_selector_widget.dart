import 'package:flutter/material.dart';
import '../models/quote.dart';
import '../database/database_helper.dart';

class QuoteSelectorWidget extends StatefulWidget {
  final int? selectedQuoteId;
  final Function(int? quoteId) onChanged;

  const QuoteSelectorWidget({
    super.key,
    this.selectedQuoteId,
    required this.onChanged,
  });

  @override
  State<QuoteSelectorWidget> createState() => _QuoteSelectorWidgetState();
}

class _QuoteSelectorWidgetState extends State<QuoteSelectorWidget> {
  List<Quote> _quotes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadQuotes();
  }

  Future<void> _loadQuotes() async {
    try {
      final data = await DatabaseHelper.instance.query(
        'quotes',
        where: 'deleted_at IS NULL',
        orderBy: 'created_at DESC',
      );
      
      setState(() {
        _quotes = data.map((map) => Quote.fromMap(map)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Связанное предложение',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1D1D1F),
          ),
        ),
        const SizedBox(height: 8),
        
        _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE5E5E7)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int?>(
                    value: widget.selectedQuoteId,
                    isExpanded: true,
                    hint: const Text('Выберите предложение'),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('Без предложения'),
                      ),
                      ..._quotes.map((quote) {
                        return DropdownMenuItem<int>(
                          value: quote.id,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                quote.objectName ?? 'Без названия',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                '${quote.customerName} • ${quote.totalAmount.toStringAsFixed(0)} ₽',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                    onChanged: (value) {
                      widget.onChanged(value);
                    },
                  ),
                ),
              ),
        
        if (widget.selectedQuoteId != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.green[700], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Данные из предложения будут автоматически добавлены в проект',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green[700],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
