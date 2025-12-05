import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/file_provider.dart';
import '../providers/tag_provider.dart';
import '../providers/search_provider.dart';
import '../providers/recommendation_provider.dart';
import '../services/platform_service.dart';
import '../widgets/recommendation_section.dart';
import '../widgets/tag_gallery.dart';
import '../widgets/document_card.dart';

/// HomeScreen - Main application screen
///
/// Displays:
/// - Permission request (if needed)
/// - Search bar
/// - Recommended files
/// - Category gallery
/// - Search results (when searching)
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final PlatformService _platformService = PlatformService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeApp();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Initialize app - check permissions and load data
  Future<void> _initializeApp() async {
    final fileProvider = context.read<FileProvider>();
    final tagProvider = context.read<TagProvider>();
    final recommendationProvider = context.read<RecommendationProvider>();

    // Initialize file provider
    await fileProvider.initialize();

    if (fileProvider.hasPermission) {
      // Load topic names
      await tagProvider.loadTopicNames();

      // Load data in parallel
      await Future.wait([
        fileProvider.loadDocuments(),
        tagProvider.loadTagMapping(),
        recommendationProvider.loadRecommendations(),
      ]);

      // Classify untagged files in background
      _classifyUntaggedFiles();
    }
  }

  /// Classify files that don't have topics yet
  Future<void> _classifyUntaggedFiles() async {
    final fileProvider = context.read<FileProvider>();
    final tagProvider = context.read<TagProvider>();

    for (final doc in fileProvider.documents) {
      if (doc.topicNumber == null) {
        await tagProvider.classifyAndTagFile(doc);
      }
    }
  }

  /// Handle search input
  void _onSearchChanged(String query) {
    final searchProvider = context.read<SearchProvider>();
    searchProvider.updateQuery(query);

    if (query.isNotEmpty) {
      searchProvider.search();
    } else {
      searchProvider.clearSearch();
    }
  }

  /// Request storage permission
  Future<void> _requestPermission() async {
    final fileProvider = context.read<FileProvider>();
    final granted = await fileProvider.requestPermission();

    if (!granted) {
      // Show dialog to open settings
      _showPermissionDialog();
    } else {
      _initializeApp();
    }
  }

  /// Show permission dialog
  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Storage Permission Required'),
        content: const Text(
          'SmartFind needs "All files access" permission to scan and organize your documents.\n\n'
              'Please enable it in Settings > Special app access > All files access.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _platformService.openAllFilesAccessSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SmartFind'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _initializeApp(),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Consumer<FileProvider>(
        builder: (context, fileProvider, child) {
          // Show permission request if not granted
          if (!fileProvider.hasPermission) {
            return _buildPermissionRequest();
          }

          // Show loading indicator
          if (fileProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          // Show error message if any
          if (fileProvider.errorMessage != null) {
            return _buildError(fileProvider.errorMessage!);
          }

          // Show main content
          return _buildMainContent();
        },
      ),
    );
  }

  /// Build permission request UI
  Widget _buildPermissionRequest() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.folder_open, size: 80, color: Colors.grey),
          const SizedBox(height: 24),
          const Text('Permission Required', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ElevatedButton(onPressed: _requestPermission, child: const Text('Grant')),
        ],
      ),
    );
  }

  /// Build error UI
  Widget _buildError(String message) {
    return Center(child: Text(message));
  }

  /// Build main content
  Widget _buildMainContent() {
    return Consumer<SearchProvider>(
      builder: (context, searchProvider, child) {
        // Show search results if searching
        if (searchProvider.query.isNotEmpty) {
          return Column(
            children: [
              _buildSearchBar(),
              Expanded(child: _buildSearchResults(searchProvider)),
            ],
          );
        }

        // Show home content
        return RefreshIndicator(
          onRefresh: _initializeApp,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSearchBar(),
                const SizedBox(height: 16),
                const RecommendationSection(),
                const SizedBox(height: 24),
                _buildCategoriesHeader(),
                const SizedBox(height: 12),
                const TagGallery(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Build search bar
  Widget _buildSearchBar() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: context.watch<SearchProvider>().isSemanticSearch
                  ? 'Smart Search (Concepts)...'
                  : 'Keyword Search (Exact)...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  _onSearchChanged('');
                },
              )
                  : null,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
            ),
          ),
        ),
        // Toggle Switch
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Consumer<SearchProvider>(
            builder: (context, provider, _) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    provider.isSemanticSearch ? "Smart Mode (AI)" : "Exact Match",
                    style: TextStyle(
                      color: provider.isSemanticSearch ? Colors.teal : Colors.orange,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  Transform.scale(
                    scale: 0.8,
                    child: Switch(
                      value: provider.isSemanticSearch,
                      activeColor: Colors.teal,
                      inactiveThumbColor: Colors.orange,
                      onChanged: (value) => provider.toggleSearchMode(value),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  /// Build categories header
  Widget _buildCategoriesHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const Icon(Icons.folder, color: Colors.blue),
          const SizedBox(width: 8),
          Text('Categories', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  /// Build search results
  Widget _buildSearchResults(SearchProvider searchProvider) {
    if (searchProvider.isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    final fileProvider = context.read<FileProvider>();

    // --- DEBUGGING LOGIC ---
    // Normalize paths by trimming to ensure matches
    final resultPaths = searchProvider.searchResultPaths.map((p) => p.trim()).toSet();

    if (resultPaths.isNotEmpty) {
      print("DEBUG: UI received ${resultPaths.length} matches from Python.");
      // Print first match for verification
      print("DEBUG: Sample match: ${resultPaths.first}");
    }

    final resultDocs = fileProvider.documents.where((doc) {
      final normalizedPath = doc.path.trim();
      final isMatch = resultPaths.contains(normalizedPath);
      return isMatch;
    }).toList();
    // -----------------------

    if (resultDocs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('No results found', style: Theme.of(context).textTheme.titleMedium),
            if (searchProvider.searchResultPaths.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  "Debug: Python found ${searchProvider.searchResultPaths.length} files, but UI failed to match paths.\nTry restarting the app.",
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: resultDocs.length,
      itemBuilder: (context, index) {
        return DocumentCard(document: resultDocs[index]);
      },
    );
  }
}