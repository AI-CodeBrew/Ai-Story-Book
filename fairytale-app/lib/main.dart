import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:api_key_pool/api_key_pool.dart';
import 'screens/main_shell.dart';
import 'providers/story_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/auth_provider.dart';
import 'services/crash_log_service.dart';
import 'utils/app_colors.dart';
import 'utils/app_sizes.dart';
import 'utils/app_strings.dart';

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    CrashLogService.init();

    AppStrings.gemini_model = 'gemini-2.0-flash';

    await ApiKeyPool.init('ai_storybook_frontend');

    final authProvider = AuthProvider();
    await authProvider.loadFromStorage();

    runApp(MyApp(authProvider: authProvider));
  }, (error, stack) {
    CrashLogService.recordError(error.toString(), stack);
    if (kDebugMode) debugPrint('Uncaught zone error: $error');
  });
}

class MyApp extends StatelessWidget {
  final AuthProvider authProvider;

  const MyApp({super.key, required this.authProvider});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => StoryProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'FairyTale AI',
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
            home: const MainShell(),
            routes: {
              '/home': (context) => const MainShell(),
            },
          );
        },
      ),
    );
  }
}
