import 'package:flutter/foundation.dart';
import '../services/ml_service.dart';
import '../models/document_model.dart';

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

  Future<void> search(List<DocumentModel> allDocuments) async {
    if (_query.isEmpty) {
      _searchResultPaths = [];
      notifyListeners();
      return;
    }

    _isSearching = true;
    notifyListeners();

    try {
      final queryLower = _query.toLowerCase();
      final exactMatches = allDocuments
          .where((doc) {
            return doc.name.toLowerCase().contains(queryLower) ||
                doc.type.toLowerCase() == queryLower;
          })
          .map((doc) => doc.path)
          .toList();

      final semanticMatches = await _mlService.semanticSearch(_query);

      _searchResultPaths =
          <String>{...exactMatches, ...semanticMatches}.toList();
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
