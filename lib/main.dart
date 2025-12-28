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

  final mlService = MLService();
  await mlService.initialize();

  runApp(const SmartFindApp());
}

class SmartFindApp extends StatelessWidget {
  const SmartFindApp({super.key});

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

        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: _brandColor,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          fontFamily: 'Inter',
          appBarTheme: const AppBarTheme(
            elevation: 0,
            scrolledUnderElevation: 0,
            backgroundColor: Colors.white,
          ),
          cardTheme: CardThemeData(
            elevation: 0,
            color: Colors.grey.shade50,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.shade200),
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
