import 'package:flutter/material.dart';
import '../models/quote_attachment.dart';

class QuoteAttachmentsWidget extends StatefulWidget {
  final int quoteId;
  final List<QuoteAttachment> attachments;
  final Function(List<QuoteAttachment>) onChanged;

  const QuoteAttachmentsWidget({
    Key? key,
    required this.quoteId,
    required this.attachments,
    required this.onChanged,
  }) : super(key: key);

  @override
  State<QuoteAttachmentsWidget> createState() => _QuoteAttachmentsWidgetState();
}

class _QuoteAttachmentsWidgetState extends State<QuoteAttachmentsWidget> {
  bool _isAddingFile = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Вложения',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_isAddingFile)
                  const CircularProgressIndicator()
                else
                  ElevatedButton.icon(
                    onPressed: _showDisabledMessage,
                    icon: const Icon(Icons.attach_file),
                    label: const Text('Добавить файл'),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (widget.attachments.isEmpty)
              const Text('Нет вложений')
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: widget.attachments.length,
                itemBuilder: (context, index) {
                  final attachment = widget.attachments[index];
                  return ListTile(
                    leading: const Icon(Icons.insert_drive_file),
                    title: Text(attachment.fileName),
                    subtitle: Text('${attachment.fileSize} байт'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _removeAttachment(index),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showDisabledMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Функция добавления файлов временно отключена')),
    );
  }

  void _removeAttachment(int index) {
    setState(() {
      final updatedAttachments = List<QuoteAttachment>.from(widget.attachments);
      updatedAttachments.removeAt(index);
      widget.onChanged(updatedAttachments);
    });
  }
}
