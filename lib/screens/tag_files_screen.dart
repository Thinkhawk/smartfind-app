import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/tag_provider.dart';
import '../providers/file_provider.dart';
import '../widgets/document_list.dart';

/// TagFilesScreen - Shows all files in a specific category/topic
///
/// Displays files filtered by topic number
class TagFilesScreen extends StatelessWidget {
  final int topicNumber;
  final String topicName;

  const TagFilesScreen({
    super.key,
    required this.topicNumber,
    required this.topicName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(topicName),
        actions: [
          Consumer<TagProvider>(
            builder: (context, tagProvider, child) {
              final fileCount = tagProvider.getTopicFileCount(topicNumber);
              return Center(
                child: Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Chip(
                    label: Text('$fileCount files'),
                    backgroundColor: Colors.blue.withOpacity(0.1),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer2<TagProvider, FileProvider>(
        builder: (context, tagProvider, fileProvider, child) {
          // Get file paths for this topic
          final filePaths = tagProvider.getFilesForTopic(topicNumber);

          // Get document objects
          final documents = fileProvider.documents
              .where((doc) => filePaths.contains(doc.path))
              .toList();

          if (documents.isEmpty) {
            return _buildEmptyState(context);
          }

          return DocumentList(
            documents: documents,
            emptyMessage: 'No files in this category',
          );
        },
      ),
    );
  }

  /// Build empty state
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_open,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No files in this category',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Files will appear here once classified',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
