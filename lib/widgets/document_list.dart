import 'package:flutter/material.dart';
import '../models/document_model.dart';
import 'document_card.dart';

class DocumentList extends StatelessWidget {
  final List<DocumentModel> documents;
  final String emptyMessage;

  const DocumentList({
    super.key,
    required this.documents,
    this.emptyMessage = 'No documents found',
  });

  @override
  Widget build(BuildContext context) {
    if (documents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_open,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: documents.length,
      itemBuilder: (context, index) {
        return DocumentCard(document: documents[index]);
      },
    );
  }
}
