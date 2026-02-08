import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart'; // Ensure this is in pubspec.yaml
import '../models/document_model.dart';
import '../providers/file_provider.dart';
import '../providers/recommendation_provider.dart';
import '../providers/tag_provider.dart';
import '../services/ml_service.dart';
import '../services/native_file_service.dart';

class DocumentCard extends StatefulWidget {
  final DocumentModel document;

  const DocumentCard({
    super.key,
    required this.document,
  });

  @override
  State<DocumentCard> createState() => _DocumentCardState();
}

class _DocumentCardState extends State<DocumentCard> {
  bool _loadingSummary = false;
  final MLService _mlService = MLService();

  @override
  void initState() {
    super.initState();
    if (widget.document.summary == null) {
      _loadSummary();
    }
  }

  Future<void> _loadSummary() async {
    if (_loadingSummary) return;

    setState(() => _loadingSummary = true);

    try {
      final fileProvider = context.read<FileProvider>();
      final content = await fileProvider.getFileContent(widget.document);

      if (content != null && content.isNotEmpty && mounted) {
        final summary = await _mlService.getSummary(content);

        if (summary != null && mounted) {
          setState(() {
            widget.document.summary = summary;
            _loadingSummary = false;
          });
        }
      } else {
        if (mounted) setState(() => _loadingSummary = false);
      }
    } catch (e) {
      print('Error loading summary: $e');
      if (mounted) {
        setState(() => _loadingSummary = false);
      }
    }
  }

  IconData _getFileIcon(String type) {
    switch (type.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'txt':
      case 'md':
        return Icons.text_snippet;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'bmp':
        return Icons.image;
      default:
        return Icons.insert_drive_file;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () async {
          Provider.of<RecommendationProvider>(context, listen: false)
              .updateRecommendations(widget.document);
          await OpenFile.open(widget.document.path);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _getFileIcon(widget.document.type),
                    size: 32,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.document.name,
                          style: Theme.of(context).textTheme.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${widget.document.formattedSize} • ${widget.document.type.toUpperCase()}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  if (widget.document.topicName != null) ...[
                    const SizedBox(width: 8),
                    Chip(
                      label: Text(widget.document.topicName!),
                      labelStyle: const TextStyle(fontSize: 11),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ],
                  // Three-Dot Popup Menu Button
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 24),
                    onSelected: (value) {
                      switch (value) {
                        case 'share':
                          _handleShare();
                          break;
                        case 'delete':
                          _showDeleteConfirmation();
                          break;
                        case 'info':
                          _showFileInfo();
                          break;
                      }
                    },
                    itemBuilder: (BuildContext context) => [
                      const PopupMenuItem(
                        value: 'share',
                        child: Row(
                          children: [
                            Icon(Icons.share, size: 20),
                            SizedBox(width: 12),
                            Text('Share File'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'info',
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, size: 20),
                            SizedBox(width: 12),
                            Text('Details'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, color: Colors.red, size: 20),
                            SizedBox(width: 12),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (_loadingSummary || widget.document.summary != null) ...[
                const SizedBox(height: 12),
                if (_loadingSummary)
                  const LinearProgressIndicator()
                else
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.document.summary!,
                            style: Theme.of(context).textTheme.bodySmall,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _handleShare() {
    Share.shareXFiles([XFile(widget.document.path)], text: 'Sharing ${widget.document.name} from SmartFind');
  }

  void _showFileInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("File Details"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Name: ${widget.document.name}"),
            const SizedBox(height: 8),
            Text("Path: ${widget.document.path}"),
            const SizedBox(height: 8),
            Text("Size: ${widget.document.formattedSize}"),
            const SizedBox(height: 8),
            Text("Modified: ${widget.document.lastModified}"),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close")),
        ],
      ),
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete File?"),
        content: Text("Are you sure you want to delete ${widget.document.name}? This action cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _handleDelete();
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleDelete() async {
    final fileProvider = Provider.of<FileProvider>(context, listen: false);
    final tagProvider = Provider.of<TagProvider>(context, listen: false);
    final nativeFileService = NativeFileService();

    bool deleted = await nativeFileService.deleteFile(widget.document.path);

    if (deleted) {
      await _mlService.removeFromIndex(widget.document.path);
      tagProvider.removeFileFromTags(widget.document.path);
      fileProvider.removeFileFromList(widget.document.path);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("File deleted successfully"))
        );
      }
    }
  }
}