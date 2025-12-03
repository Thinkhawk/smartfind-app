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

  String get query => _query;
  List<String> get searchResultPaths => _searchResultPaths;
  bool get isSearching => _isSearching;

  /// Update search query
  void updateQuery(String query) {
    _query = query;
    notifyListeners();
  }

  /// Perform semantic search
  Future<void> search() async {
    if (_query.isEmpty) {
      _searchResultPaths = [];
      notifyListeners();
      return;
    }

    _isSearching = true;
    notifyListeners();

    try {
      _searchResultPaths = await _mlService.semanticSearch(_query);
    } catch (e) {
      print('Search error: $e');
      _searchResultPaths = [];
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  /// Clear search
  void clearSearch() {
    _query = '';
    _searchResultPaths = [];
    notifyListeners();
  }
}
