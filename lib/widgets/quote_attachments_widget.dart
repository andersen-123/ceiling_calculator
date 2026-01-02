import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import '../models/quote_attachment.dart';

class QuoteAttachmentsWidget extends StatefulWidget {
  final int quoteId;
  final List<QuoteAttachment> attachments;
  final Function(List<QuoteAttachment>) onChanged;

  const QuoteAttachmentsWidget({
    super.key,
    required this.quoteId,
    required this.attachments,
    required this.onChanged,
  });

  @override
  State<QuoteAttachmentsWidget> createState() => _QuoteAttachmentsWidgetState();
}

class _QuoteAttachmentsWidgetState extends State<QuoteAttachmentsWidget> {
  bool _isAddingFile = false;

  Future<void> _requestPermissions() async {
    await Permission.storage.request();
    await Permission.photos.request();
  }

  Future<void> _addAttachment() async {
    setState(() => _isAddingFile = true);

    try {
      await _requestPermissions();

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final fileName = result.files.single.name;
        final fileSize = await file.length();
        
        // Создаем директорию для файлов приложения
        final appDir = await getApplicationDocumentsDirectory();
        final attachmentsDir = Directory('${appDir.path}/attachments');
        if (!await attachmentsDir.exists()) {
          await attachmentsDir.create(recursive: true);
        }

        // Создаем уникальное имя файла
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final uniqueFileName = '${timestamp}_$fileName';
        final savedFile = File('${attachmentsDir.path}/$uniqueFileName');
        
        print('Копируем файл из: ${file.path}');
        print('Копируем файл в: ${savedFile.path}');
        
        // Копируем файл в директорию приложения
        await file.copy(savedFile.path);
        
        print('Файл скопирован, существует: ${await savedFile.exists()}');

        final attachment = QuoteAttachment(
          quoteId: widget.quoteId,
          fileName: fileName,
          filePath: savedFile.path,
          mimeType: result.files.single.extension,
          fileSize: fileSize,
          createdAt: DateTime.now(),
        );

        setState(() {
          widget.attachments.add(attachment);
        });
        widget.onChanged(widget.attachments);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Файл добавлен: $fileName'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      print('Ошибка добавления файла: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка добавления файла: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isAddingFile = false);
    }
  }

  Future<void> _openAttachment(QuoteAttachment attachment) async {
    try {
      final file = File(attachment.filePath);
      print('Проверка файла: ${attachment.filePath}');
      print('Файл существует: ${await file.exists()}');
      
      if (await file.exists()) {
        // Используем OpenFile для прямого открытия в приложении
        final result = await OpenFile.open(attachment.filePath);
        print('Результат открытия: ${result.type}');
        print('Сообщение: ${result.message}');
        
        if (result.type == ResultType.error) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Не удалось открыть файл: ${result.message}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Файл не найден на устройстве'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Ошибка открытия файла: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка открытия файла: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _removeAttachment(QuoteAttachment attachment) {
    setState(() {
      widget.attachments.remove(attachment);
    });
    widget.onChanged(widget.attachments);

    // Удаляем файл с диска
    try {
      File(attachment.filePath).deleteSync();
    } catch (e) {
      print('Ошибка удаления файла: $e');
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Файл удален: ${attachment.fileName}'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
              children: [
                Expanded(
                  child: Text(
                    'Прикрепленные файлы',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1D1D1F),
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _isAddingFile ? null : _addAttachment,
                  icon: _isAddingFile
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.attach_file, size: 14),
                  label: Text(_isAddingFile ? 'Загрузка...' : 'Добавить'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    minimumSize: Size(0, 32),
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (widget.attachments.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.attach_file_outlined,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Нет прикрепленных файлов',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Нажмите "Добавить файл" чтобы прикрепить документы, фото или другие файлы',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              ...widget.attachments.map((attachment) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  onTap: () => _openAttachment(attachment),
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getFileIcon(attachment.fileName),
                      color: Colors.blue[700],
                      size: 20,
                    ),
                  ),
                  title: Text(
                    attachment.fileName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    _formatFileSize(attachment.fileSize),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  trailing: IconButton(
                    onPressed: () => _removeAttachment(attachment),
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    tooltip: 'Удалить файл',
                  ),
                ),
              )),
          ],
        ),
      ),
    );
  }

  IconData _getFileIcon(String fileName) {
    final extension = fileName.toLowerCase().split('.').last;
    
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Icons.image;
      case 'mp4':
      case 'avi':
      case 'mov':
        return Icons.videocam;
      case 'mp3':
      case 'wav':
        return Icons.audiotrack;
      default:
        return Icons.insert_drive_file;
    }
  }
}
