import 'package:flutter/foundation.dart';
import '../services/ml_service.dart';
import '../models/document_model.dart'; // Import DocumentModel

class SearchProvider with ChangeNotifier {
  final MLService _mlService = MLService();

  String _query = '';
  List<String> _searchResultPaths = [];
  bool _isSearching = false;

  String get query => _query;
  List<String> get searchResultPaths => _searchResultPaths;
  bool get isSearching => _isSearching;

  void updateQuery(String query) {
    _query = query;
    notifyListeners();
  }

  // UPDATED: Now accepts the list of documents to perform Hybrid Search
  Future<void> search(List<DocumentModel> allDocuments) async {
    if (_query.isEmpty) {
      _searchResultPaths = [];
      notifyListeners();
      return;
    }

    _isSearching = true;
    notifyListeners();

    try {
      // 1. EXACT MATCH (Keyword Search) - The "Smart" part
      // Finds "png" or "invoice" in the filename directly
      final queryLower = _query.toLowerCase();
      final exactMatches = allDocuments.where((doc) {
        return doc.name.toLowerCase().contains(queryLower) ||
            doc.type.toLowerCase() == queryLower;
      }).map((doc) => doc.path).toList();

      // 2. SEMANTIC MATCH (AI Search) - The "Deep" part
      // Finds files related to the concept (e.g., "money" -> finds invoice.pdf)
      final semanticMatches = await _mlService.semanticSearch(_query);

      // 3. COMBINE (Exact matches first!)
      // We use a Set to remove duplicates
      _searchResultPaths = <String>{
        ...exactMatches,
        ...semanticMatches
      }.toList();

    } catch (e) {
      print('Search error: $e');
      _searchResultPaths = [];
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  void clearSearch() {
    _query = '';
    _searchResultPaths = [];
    notifyListeners();
  }
}