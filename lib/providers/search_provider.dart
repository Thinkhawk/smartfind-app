import 'package:flutter/foundation.dart';
import '../services/ml_service.dart';

/// SearchProvider - Manages semantic document search
///
/// Provides real-time semantic search across indexed documents
class SearchProvider with ChangeNotifier {
  final MLService _mlService = MLService();

  String _query = '';
  List<String> _searchResultPaths = [];
  bool _isSearching = false;
  bool _isSemanticSearch = true; // Toggle state

  String get query => _query;
  List<String> get searchResultPaths => _searchResultPaths;
  bool get isSearching => _isSearching;
  bool get isSemanticSearch => _isSemanticSearch;

  void updateQuery(String query) {
    _query = query;
    notifyListeners();
  }

  void toggleSearchMode(bool isSemantic) {
    _isSemanticSearch = isSemantic;
    if (_query.isNotEmpty) search();
    notifyListeners();
  }

  Future<void> search() async {
    if (_query.isEmpty) {
      _searchResultPaths = [];
      notifyListeners();
      return;
    }

    _isSearching = true;
    notifyListeners();

    try {
      if (_isSemanticSearch) {
        print("DEBUG: Running Semantic Search");
        _searchResultPaths = await _mlService.semanticSearch(_query);
      } else {
        print("DEBUG: Running Keyword Search");
        _searchResultPaths = await _mlService.keywordSearch(_query);
      }
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
