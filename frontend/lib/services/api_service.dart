import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:api_key_pool/api_key_pool.dart';
import '../models/story.dart';

class ApiService {
  // For development - local Flask server
  // static const String baseUrl = 'http://127.0.0.1:8080/api';

  // For production - Vercel deployment
  static const String baseUrl = 'https://backend-gqxa3h948-uzairhassan375s-projects.vercel.app/api';
  
  // Helper method to convert relative image URLs to absolute URLs
  static String getImageUrl(String imageUrl) {
    // If it's already a data URL (base64), return as-is
    if (imageUrl.startsWith('data:')) {
      return imageUrl;
    }
    // If it's already a full URL, return as-is
    if (imageUrl.startsWith('http')) {
      return imageUrl;
    }
    // Otherwise, treat as relative URL
    return 'https://backend-gqxa3h948-uzairhassan375s-projects.vercel.app$imageUrl';
  }
  
  // Manual function to test ApiKeyPool
  static Future<void> testApiKeyPool() async {
    try {
      print('🧪 Testing ApiKeyPool...');
      
      // Test initialization
      await ApiKeyPool.init('ai_storybook_frontend');
      print('✅ ApiKeyPool.init() completed');
      
      await Future.delayed(const Duration(seconds: 2));
      
      // Try initialize method
      await ApiKeyPool.initialize();
      print('✅ ApiKeyPool.initialize() completed');
      
      // Check keys
      final keys = ApiKeyPool.allKeys;
      print('🔑 Keys found: ${keys.length}');
      print('🔑 Keys: $keys');
      
      // Test getKey method
      if (keys.isNotEmpty) {
        final testKey = ApiKeyPool.getKey();
        print('🔑 Test key: ${testKey.substring(0, 10)}...');
      }
      
    } catch (e) {
      print('❌ ApiKeyPool test error: $e');
    }
  }

  // Send all API keys to backend for rotation
  static Future<Map<String, dynamic>> sendApiKeysToBackend() async {
    try {
      print('🔑 Initializing ApiKeyPool and fetching keys...');
      
      // First, ensure ApiKeyPool is properly initialized
      await ApiKeyPool.init('ai_storybook_frontend');
      
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Try to initialize again if keys are still empty
      if (ApiKeyPool.allKeys.isEmpty) {
        print('🔄 Keys still empty, trying initialize() method...');
        await ApiKeyPool.initialize();
        await Future.delayed(const Duration(milliseconds: 1000));
      }
      
      // Get all keys from the API Key Pool
      final keys = ApiKeyPool.allKeys;
      print('🔑 Found ${keys.length} keys: $keys');
      
      if (keys.isEmpty) {
        print('⚠️ No API keys found in ApiKeyPool - will use backend fallback');
        // Don't throw error, let backend use its fallback key
        return {
          'success': false,
          'message': 'No keys found in ApiKeyPool, backend will use fallback'
        };
      }
      
      final response = await http.post(
        Uri.parse('$baseUrl/keys/update'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'api_keys': keys,
          'app_name': 'ai_storybook_frontend',
        }),
      );
      
      print('📡 Keys upload response: ${response.statusCode}');
      print('📄 Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          print('✅ API keys successfully sent to backend');
          return data;
        } else {
          throw Exception(data['error'] ?? 'Failed to update API keys');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ API Keys Upload Error: $e');
      // Don't throw error, let the app continue with backend fallback
      return {
        'success': false,
        'error': 'Failed to send API keys to backend: $e'
      };
    }
  }
  
  // Story generation
  static Future<Story> generateStory(StoryRequest request) async {
    try {
      print('🔗 Making API request to: $baseUrl/stories/generate');
      print('📝 Request data: ${jsonEncode(request.toJson())}');

      final response = await http.post(
        Uri.parse('$baseUrl/stories/generate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(request.toJson()),
      ).timeout(const Duration(seconds: 60)); // Add timeout

      print('📡 Response status: ${response.statusCode}');
      print('📄 Response body: ${response.body}');
      print('📄 Response headers: ${response.headers}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('📊 Parsed response data: $data');

        if (data['success'] == true && data['data'] != null) {
          print('✅ API call successful, parsing story...');
          final story = Story.fromJson(data['data']);
          print('✅ Story parsed successfully');
          return story;
        } else {
          print('❌ API returned error response');
          throw Exception(data['error'] ?? 'Failed to generate story');
        }
      } else {
        print('❌ HTTP error response');
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e, stackTrace) {
      print('❌ API Error in generateStory:');
      print('🔴 Error: $e');
      print('🔴 Stack trace: $stackTrace');
      print('🔴 Error type: ${e.runtimeType}');
      throw Exception('Network error: $e');
    }
  }

  // Submit feedback
  static Future<Map<String, dynamic>> submitFeedback({
    required String feedbackType,
    required String selectedFeedback,
    String? customFeedback,
    String? storyId,
    int rating = 5,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/feedback'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'feedbackType': feedbackType,
          'selectedFeedback': selectedFeedback,
          'customFeedback': customFeedback,
          'storyId': storyId,
          'rating': rating,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to submit feedback: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Get feedback options
  static Future<Map<String, dynamic>> getFeedbackOptions() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/feedback/options'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get feedback options: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Get feedback for a story
  static Future<List<Feedback>> getFeedbackForStory(String storyId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/feedback/$storyId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final List<dynamic> feedbackList = data['data'];
          return feedbackList.map((json) => Feedback.fromJson(json)).toList();
        } else {
          throw Exception(data['error'] ?? 'Failed to get feedback');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Get feedback stats for a story
  static Future<Map<String, dynamic>> getFeedbackStats(String storyId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/feedback/$storyId/stats'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return Map<String, dynamic>.from(data['data']);
        } else {
          throw Exception(data['error'] ?? 'Failed to get feedback stats');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Generate single image - optimized for Vercel
  static Future<Map<String, dynamic>> generateSingleImage({
    required String prompt,
    String? modelName,
  }) async {
    try {
      print('🖼️ Generating single image for prompt: ${prompt.substring(0, 50)}...');
      
      final response = await http.post(
        Uri.parse('$baseUrl/generate-image'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'prompt': prompt,
          'modelName': modelName,
        }),
      ).timeout(const Duration(seconds: 30)); // 30 second timeout

      print('📡 Single image response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Single image generated successfully');
        return data;
      } else {
        print('❌ Single image generation failed: ${response.statusCode}');
        throw Exception('Failed to generate image: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ Single image generation error: $e');
      throw Exception('Network error: $e');
    }
  }

  // Generate multiple images for story pages
  static Future<List<String?>> generateMultipleImages({
    required List<String> prompts,
    bool parallel = true,
    String? modelName,
  }) async {
    try {
      print('🎨 Generating ${prompts.length} images (parallel: $parallel)...');
      
      if (parallel) {
        // Generate all images in parallel using Future.wait
        print('🚀 Starting parallel image generation...');
        
        final futures = prompts.asMap().entries.map((entry) async {
          final index = entry.key;
          final prompt = entry.value;
          
          try {
            print('🖼️ Starting image $index...');
            final result = await generateSingleImage(prompt: prompt, modelName: modelName);
            
            if (result['success'] == true && result.containsKey('imageBase64')) {
              final base64 = result['imageBase64'] as String;
              print('✅ Image $index completed (${base64.length} chars)');
              return 'data:image/jpeg;base64,$base64';
            } else {
              print('❌ Image $index failed: ${result['error']}');
              return null;
            }
          } catch (e) {
            print('❌ Image $index error: $e');
            return null;
          }
        });
        
        final results = await Future.wait(futures);
        print('🏁 Parallel generation completed: ${results.where((r) => r != null).length}/${prompts.length} successful');
        return results;
        
      } else {
        // Generate images sequentially
        print('⏭️ Starting sequential image generation...');
        final results = <String?>[];
        
        for (int i = 0; i < prompts.length; i++) {
          try {
            print('🖼️ Generating image ${i + 1}/${prompts.length}...');
            final result = await generateSingleImage(prompt: prompts[i], modelName: modelName);
            
            if (result['success'] == true && result.containsKey('imageBase64')) {
              final base64 = result['imageBase64'] as String;
              results.add('data:image/jpeg;base64,$base64');
              print('✅ Image ${i + 1} completed');
            } else {
              results.add(null);
              print('❌ Image ${i + 1} failed: ${result['error']}');
            }
          } catch (e) {
            results.add(null);
            print('❌ Image ${i + 1} error: $e');
          }
        }
        
        print('🏁 Sequential generation completed: ${results.where((r) => r != null).length}/${prompts.length} successful');
        return results;
      }
      
    } catch (e) {
      print('❌ Multiple image generation error: $e');
      throw Exception('Multiple image generation failed: $e');
    }
  }

  // Legacy method for backward compatibility
  static Future<Map<String, dynamic>> generateImage({
    required String prompt,
    List<Uint8List>? images,
    String? modelName,
  }) async {
    return generateSingleImage(prompt: prompt, modelName: modelName);
  }

  // Generate text
  static Future<Map<String, dynamic>> generateText({
    required String prompt,
    String? systemInstruction,
    Map<String, dynamic>? generationConfig,
    List<Uint8List>? images,
    String? modelName,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/text/generate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'prompt': prompt,
          'systemInstruction': systemInstruction,
          'generationConfig': generationConfig,
          'images': images?.map((img) => base64Encode(img)).toList(),
          'modelName': modelName,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to generate text: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Health check
  static Future<bool> checkHealth() async {
    try {
      print('🏥 Health check to: $baseUrl/health');
      final response = await http.get(
        Uri.parse('$baseUrl/health'),
        headers: {'Content-Type': 'application/json'},
      );

      print('🏥 Health check response: ${response.statusCode}');
      if (response.statusCode == 200) {
        print('✅ Backend is healthy');
        return true;
      } else {
        print('❌ Backend health check failed: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ Health check error: $e');
      return false;
    }
  }

  // Test connection and debug
  static Future<void> testConnection() async {
    try {
      print('🧪 Testing API connection...');
      
      // Test different URLs
      final testUrls = [
        'http://127.0.0.1:8080/api/health',
        'http://localhost:8080/api/health',
        'http://192.168.17.89:8080/api/health', // From your backend logs
      ];
      
      for (String url in testUrls) {
        try {
          print('🔍 Testing: $url');
          final response = await http.get(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
          ).timeout(const Duration(seconds: 5));
          
          print('✅ $url responded with ${response.statusCode}');
          if (response.statusCode == 200) {
            print('📄 Response: ${response.body}');
          }
        } catch (e) {
          print('❌ $url failed: $e');
        }
      }
    } catch (e) {
      print('❌ Connection test failed: $e');
    }
  }
}
