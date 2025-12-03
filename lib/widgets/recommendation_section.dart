import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/recommendation_provider.dart';
import '../providers/file_provider.dart';
import '../widgets/document_card.dart';

/// RecommendationSection - Displays recommended files
///
/// Shows horizontally scrollable list of recommended documents
class RecommendationSection extends StatelessWidget {
  const RecommendationSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<RecommendationProvider, FileProvider>(
      builder: (context, recommendationProvider, fileProvider, child) {
        if (recommendationProvider.isLoading) {
          return const SizedBox.shrink();
        }

        final recommendedDocs = fileProvider.documents
            .where((doc) =>
            recommendationProvider.recommendedFilePaths.contains(doc.path))
            .take(5)
            .toList();

        if (recommendedDocs.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.recommend, color: Colors.orange),
                  const SizedBox(width: 8),
                  Text(
                    'Recommended for you',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 180,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: recommendedDocs.length,
                itemBuilder: (context, index) {
                  return SizedBox(
                    width: 300,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: DocumentCard(document: recommendedDocs[index]),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
