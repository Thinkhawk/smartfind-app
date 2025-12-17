import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartfind_app/services/ml_service.dart';
import 'screens/home_screen.dart';
import 'providers/file_provider.dart';
import 'providers/tag_provider.dart';
import 'providers/search_provider.dart';
import 'providers/recommendation_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize ML Assets (Copy models to storage)
  final mlService = MLService();
  await mlService.initialize();

  runApp(const SmartFindApp());
}

/// SmartFindApp - Root application widget
///
/// Sets up:
/// - Multi-provider state management
/// - Material theme
/// - Navigation
class SmartFindApp extends StatelessWidget {
  const SmartFindApp({super.key});

  // TODO: Replace this with the dominant color from your new logo
  // Example: If your logo is Blue, use Color(0xFF2196F3)
  static const Color _brandColor = Color.fromRGBO(117, 70, 202, 1);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => FileProvider()),
        ChangeNotifierProvider(create: (_) => TagProvider()),
        ChangeNotifierProvider(create: (_) => SearchProvider()),
        ChangeNotifierProvider(create: (_) => RecommendationProvider()),
      ],
      child: MaterialApp(
        title: 'SmartFind',
        debugShowCheckedModeBanner: false,

        // LIGHT THEME (Auto-generated from your brand color)
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: _brandColor,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          fontFamily: 'Inter',
          appBarTheme: const AppBarTheme(
            elevation: 0,
            scrolledUnderElevation: 0, // Keeps flat look when scrolling
            backgroundColor: Colors.white, // Clean white header
          ),
          cardTheme: CardThemeData(
            elevation: 0, // Modern flat look
            color: Colors.grey.shade50,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16), // Softer corners
              side: BorderSide(color: Colors.grey.shade200), // Subtle border
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            prefixIconColor: _brandColor,
          ),
        ),

        // DARK THEME
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: _brandColor,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
          fontFamily: 'Inter',
          cardTheme: CardThemeData(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        themeMode: ThemeMode.system,
        home: const HomeScreen(),
      ),
    );
  }
}
