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
import 'cleanup_screen.dart';

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

  Future<void> _initializeApp() async {
    final fileProvider = context.read<FileProvider>();
    final tagProvider = context.read<TagProvider>();
    final recommendationProvider = context.read<RecommendationProvider>();

    await fileProvider.initialize();

    if (fileProvider.hasPermission) {
      await tagProvider.loadTopicNames();

      await Future.wait([
        fileProvider.loadDocuments(),
        tagProvider.loadTagMapping(),
        recommendationProvider.loadRecommendations(),
      ]);

      _classifyUntaggedFiles();
    }
  }

  Future<void> _classifyUntaggedFiles() async {
    final fileProvider = context.read<FileProvider>();
    final tagProvider = context.read<TagProvider>();

    for (final doc in fileProvider.documents) {
      if (doc.topicNumber == null) {
        await tagProvider.classifyAndTagFile(doc);
      }
    }
  }

  void _onSearchChanged(String query) {
    final searchProvider = context.read<SearchProvider>();
    final fileProvider = context.read<FileProvider>();

    searchProvider.updateQuery(query);

    if (query.isNotEmpty) {
      searchProvider.search(fileProvider.documents);
    } else {
      searchProvider.clearSearch();
    }
  }

  Future<void> _requestPermission() async {
    final fileProvider = context.read<FileProvider>();
    final granted = await fileProvider.requestPermission();

    if (!granted) {
      _showPermissionDialog();
    } else {
      _initializeApp();
    }
  }

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
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/logo-bgl-nn.png', width: 50),
            const Text(
              'SmartFind',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 26,
                  color: Color.fromRGBO(117, 70, 202, .8)),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _initializeApp(),
            tooltip: 'Refresh',
          ),
        ],
      ),
      drawer: Drawer(
        child: Column(
          children: [
            const SizedBox(height: 60),
            ListTile(
              leading: const Icon(Icons.cleaning_services_outlined,
                  color: Colors.blue),
              title: const Text('Storage Cleanup'),
              subtitle: const Text('Remove duplicate files'),
              onTap: () {
                Navigator.pop(context); // Close drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const CleanupScreen()),
                );
              },
            ),
            const Spacer(),
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Version 1.0.0',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
      body: Consumer<FileProvider>(
        builder: (context, fileProvider, child) {
          if (!fileProvider.hasPermission) {
            return _buildPermissionRequest();
          }

          if (fileProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (fileProvider.errorMessage != null) {
            return _buildError(fileProvider.errorMessage!);
          }

          return _buildMainContent();
        },
      ),
    );
  }

  Widget _buildPermissionRequest() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.folder_open, size: 80, color: Colors.grey),
          const SizedBox(height: 24),
          const Text('Permission Required',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ElevatedButton(
              onPressed: _requestPermission, child: const Text('Grant')),
        ],
      ),
    );
  }

  Widget _buildError(String message) {
    return Center(child: Text(message));
  }

  Widget _buildMainContent() {
    return Consumer<SearchProvider>(
      builder: (context, searchProvider, child) {
        if (searchProvider.query.isNotEmpty) {
          return Column(
            children: [
              _buildSearchBar(),
              Expanded(child: _buildSearchResults(searchProvider)),
            ],
          );
        }

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

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          hintText: 'Search documents...',
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
    );
  }

  Widget _buildCategoriesHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const Icon(Icons.folder, color: Colors.blue),
          const SizedBox(width: 8),
          Text('Categories',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSearchResults(SearchProvider searchProvider) {
    if (searchProvider.isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    final fileProvider = context.read<FileProvider>();
    final resultPaths =
        searchProvider.searchResultPaths.map((p) => p.trim()).toSet();

    final resultDocs = fileProvider.documents.where((doc) {
      return resultPaths.contains(doc.path.trim());
    }).toList();

    if (resultDocs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('No results found',
                style: Theme.of(context).textTheme.titleMedium),
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
