import 'package:flutter_test/flutter_test.dart';
import 'package:smartfind_app/models/document_model.dart';
import 'package:smartfind_app/providers/tag_provider.dart';
import 'package:smartfind_app/providers/search_provider.dart';

void main() {
  group('SmartFind Unit Tests', () {

    // 1. Model Parsing Test
    test('DocumentModel correctly formats file size', () {
      final doc = DocumentModel(
        path: '/test.pdf',
        name: 'test.pdf',
        type: 'pdf',
        size: 2500000, // ~2.5 MB
        lastModified: DateTime.now(),
      );

      expect(doc.formattedSize, '2.4 MB');
      expect(doc.icon, '📄');
    });

    // 2. Search Provider Logic
    test('SearchProvider manages state correctly', () {
      final provider = SearchProvider();

      // Initial state
      expect(provider.isSearching, false);
      expect(provider.query, '');

      // Update query
      provider.updateQuery('finance');
      expect(provider.query, 'finance');

      // Clear
      provider.clearSearch();
      expect(provider.query, '');
      expect(provider.searchResultPaths, isEmpty);
    });

    // 3. Tag Logic Test
    // This mocks the scenario where we want to ensure topics don't overlap
    test('TagProvider handles visible topics', () {
      // In a real unit test we would mock the file loading,
      // but here we verify the initial empty state logic.
      final provider = TagProvider();
      expect(provider.visibleTopics, isEmpty);
      expect(provider.isLoading, false);
    });
  });
}