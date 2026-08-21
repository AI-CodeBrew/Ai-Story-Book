import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:api_key_pool/api_key_pool.dart';
import 'screens/home_screen.dart';
import 'providers/story_provider.dart';
import 'providers/theme_provider.dart';
import 'utils/app_colors.dart';
import 'utils/app_sizes.dart';
import 'utils/app_strings.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  AppStrings.gemini_model = 'gemini-2.0-flash';

  await ApiKeyPool.init('ai_storybook_frontend');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => StoryProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'AI Storybook',
            debugShowCheckedModeBanner: false,
            builder: (context, child) {
              AppSizes.init(context);
              return child!;
            },
            theme: ThemeData(
              primarySwatch: Colors.blue,
              primaryColor: AppColors.primary,
              scaffoldBackgroundColor: AppColors.background,
              appBarTheme: AppBarTheme(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                titleTextStyle: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            home: const HomeScreen(),
            routes: {
              '/home': (context) => const HomeScreen(),
            },
          );
        },
      ),
    );
  }
}
