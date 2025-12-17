import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/file_provider.dart';
import '../models/document_model.dart';

class CleanupScreen extends StatefulWidget {
  const CleanupScreen({super.key});

  @override
  State<CleanupScreen> createState() => _CleanupScreenState();
}

class _CleanupScreenState extends State<CleanupScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
        Provider.of<FileProvider>(context, listen: false).scanForDuplicates());
  }

  void _confirmDeletion(BuildContext context, DocumentModel doc) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirm Deletion"),
        content: Text("Are you sure you want to delete '${doc.name}'? This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("CANCEL"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await Provider.of<FileProvider>(context, listen: false).deleteDocument(doc);
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("File deleted successfully")),
                );
              }
            },
            child: const Text("DELETE", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Storage Cleanup"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<FileProvider>().scanForDuplicates(),
          )
        ],
      ),
      body: Consumer<FileProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.duplicateClusters.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.auto_awesome, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text("No duplicate files found!", style: TextStyle(color: Colors.grey)),
                  Text("Your storage is clean.", style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.duplicateClusters.length,
            itemBuilder: (context, index) {
              final cluster = provider.duplicateClusters[index];
              return _DuplicateClusterCard(
                cluster: cluster,
                onDelete: (doc) => _confirmDeletion(context, doc),
              );
            },
          );
        },
      ),
    );
  }
}

class _DuplicateClusterCard extends StatelessWidget {
  final List<DocumentModel> cluster;
  final Function(DocumentModel) onDelete;

  const _DuplicateClusterCard({required this.cluster, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(Icons.copy_all, size: 20, color: Colors.blue),
                SizedBox(width: 8),
                Text("Similar Content Detected", style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const Divider(height: 1),
          ...cluster.map((doc) => ListTile(
            leading: Icon(_getIcon(doc.type), color: Colors.grey),
            title: Text(doc.name, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text("${doc.size} • ${doc.path}", style: const TextStyle(fontSize: 11)),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => onDelete(doc),
            ),
          )),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            color: Colors.grey.shade50,
            child: Text(
              "Keep one version and delete the others to save space.",
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
              textAlign: TextAlign.center,
            ),
          )
        ],
      ),
    );
  }

  IconData _getIcon(String type) {
    if (type == 'pdf') return Icons.picture_as_pdf;
    if (['jpg', 'png', 'jpeg'].contains(type)) return Icons.image;
    return Icons.insert_drive_file;
  }
}