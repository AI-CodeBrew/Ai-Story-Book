import 'package:ai_storybook_frontend/utils/app_strings.dart';

class AIConfig {
  static String get modelName {
    return AppStrings.gemini_model.isNotEmpty
        ? AppStrings.gemini_model
        : 'gemini-2.0-flash';
  }
  
  // Method to get current model name (useful for debugging)
  static String getCurrentModelName() {
    return modelName;
  }
  
  static const int requestTimeoutSeconds = 30;
  static const int connectionTestTimeoutSeconds = 10;
  
  // API endpoints for debugging
  static const String baseUrl = 'https://generativelanguage.googleapis.com';
  static const String apiVersion = 'v1beta';
  
  // Validation method
  static bool isValidApiKey(String key) {
    return key.isNotEmpty && key.startsWith('AIza') && key.length > 30;
  }
}


