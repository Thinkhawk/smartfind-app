import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/document_model.dart';
import '../providers/file_provider.dart';
import '../providers/recommendation_provider.dart'; // <--- NEW IMPORT ADDED HERE
import '../services/ml_service.dart';

/// DocumentCard - Displays document information with summary
///
/// Shows:
/// - File name and type
/// - File size
/// - Topic tag (if classified)
/// - Summary (loaded on demand)
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
    // Load summary if not already loaded
    if (widget.document.summary == null) {
      _loadSummary();
    }
  }

  /// Load document summary
  Future<void> _loadSummary() async {
    if (_loadingSummary) return;

    setState(() => _loadingSummary = true);

    try {
      // Use FileProvider to read content (Handles OCR for images!)
      final fileProvider = context.read<FileProvider>();
      final content = await fileProvider.getFileContent(widget.document);

      if (content != null && content.isNotEmpty && mounted) {
        // Generate summary using Python
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

  /// Get icon for file type
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
        // --- UPDATED ONTAP HANDLER START ---
        onTap: () {
          // 1. Open File
          context.read<FileProvider>().openDocument(widget.document);

          // 2. Update Recommendation Context
          // This tells the app: "The user is interested in THIS file right now"
          // so it can find similar files immediately.
          context.read<RecommendationProvider>().setLastOpened(widget.document.path);
        },
        // --- UPDATED ONTAP HANDLER END ---

        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
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
                  // Topic tag
                  if (widget.document.topicName != null)
                    Chip(
                      label: Text(widget.document.topicName!),
                      labelStyle: const TextStyle(fontSize: 11),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                ],
              ),

              // Summary section
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
}