import 'dart:async';
import '../models/story.dart';
import '../utils/ai_config.dart';
import 'api_service.dart';
import 'character_consistency_service.dart';

class StoryImageService {
  // Generate image prompts for story pages with character consistency
  static Future<List<String>> generateImagePrompts(Story story) async {
    try {
      print('🔍 Extracting character details for consistency...');
      
      // Extract character details from the story
      final characters = await CharacterConsistencyService.extractCharacterDetails(story);
      print('✅ Character details extracted: ${characters.keys.toList()}');
      
      final prompts = <String>[];
      
      for (int i = 0; i < story.pages.length; i++) {
        final page = story.pages[i];
        final imagePrompt = CharacterConsistencyService.buildConsistentImagePrompt(
          pageScript: page.script,
          theme: story.theme,
          characters: characters,
          pageNumber: page.pageNumber,
        );
        prompts.add(imagePrompt);
      }
      
      return prompts;
    } catch (e) {
      print('❌ Error generating consistent prompts: $e');
      // Fallback to old method
      return _generateFallbackPrompts(story);
    }
  }

  // Fallback method for generating prompts without character consistency
  static List<String> _generateFallbackPrompts(Story story) {
    final prompts = <String>[];
    
    for (final page in story.pages) {
      final imagePrompt = _buildImagePrompt(page.script, story.theme);
      prompts.add(imagePrompt);
    }
    
    return prompts;
  }
  
  // Build image prompt for a specific page
  static String _buildImagePrompt(String script, String theme) {
    final themeStyles = {
      'Adventure': 'adventure, action, exploration, exciting',
      'Fantasy': 'fantasy, magical, mystical, enchanted',
      'Space': 'sci-fi, futuristic, space, cosmic',
      'Nature': 'nature, peaceful, beautiful, natural',
      'Friendship': 'warm, friendly, heartwarming, caring',
      'Science': 'educational, scientific, colorful, learning',
    };
    
    final style = themeStyles[theme] ?? 'beautiful, colorful';
    
    return '''
Create a beautiful, detailed illustration for a children's story:
Scene: $script
Style: $style, child-friendly, vibrant colors, detailed but simple, storybook illustration
Format: High-quality digital art suitable for a children's book
''';
  }
  
  // Generate images for all story pages
  static Future<Story> generateImagesForStory(
    Story story, {
    bool parallel = true,
    Function(int, int)? onProgress,
  }) async {
    try {
      print('🎨 Starting image generation for ${story.pages.length} pages...');
      
      // Generate image prompts with character consistency
      final prompts = await generateImagePrompts(story);
      
      // Generate images
      final imageUrls = await ApiService.generateMultipleImages(
        prompts: prompts,
        parallel: parallel,
        modelName: AIConfig.modelName,
      );
      
      // Update story pages with generated images
      final updatedPages = <StoryPage>[];
      
      for (int i = 0; i < story.pages.length; i++) {
        final page = story.pages[i];
        final imageUrl = imageUrls[i];
        
        final updatedPage = StoryPage(
          pageNumber: page.pageNumber,
          script: page.script,
          imageUrl: imageUrl ?? _getFallbackImageUrl(page.pageNumber),
        );
        
        updatedPages.add(updatedPage);
        
        // Call progress callback if provided
        onProgress?.call(i + 1, story.pages.length);
      }
      
      // Return updated story with images
      return Story(
        id: story.id,
        title: story.title,
        pages: updatedPages,
        theme: story.theme,
        audioUrl: story.audioUrl,
        createdAt: story.createdAt,
      );
      
    } catch (e) {
      print('❌ Error generating images for story: $e');
      
      // Return story with fallback images
      final fallbackPages = story.pages.map((page) => StoryPage(
        pageNumber: page.pageNumber,
        script: page.script,
        imageUrl: _getFallbackImageUrl(page.pageNumber),
      )).toList();
      
      return Story(
        id: story.id,
        title: story.title,
        pages: fallbackPages,
        theme: story.theme,
        audioUrl: story.audioUrl,
        createdAt: story.createdAt,
      );
    }
  }
  
  // Generate single image for a story page
  static Future<String?> generateImageForPage(
    StoryPage page,
    String theme,
  ) async {
    try {
      final prompt = _buildImagePrompt(page.script, theme);
      final result = await ApiService.generateSingleImage(
        prompt: prompt,
        modelName: AIConfig.modelName,
      );
      
      if (result['success'] == true && result.containsKey('imageBase64')) {
        final base64 = result['imageBase64'] as String;
        return 'data:image/jpeg;base64,$base64';
      } else {
        print('❌ Failed to generate image for page ${page.pageNumber}: ${result['error']}');
        return null;
      }
    } catch (e) {
      print('❌ Error generating image for page ${page.pageNumber}: $e');
      return null;
    }
  }
  
  // Get fallback image URL
  static String _getFallbackImageUrl(int pageNumber) {
    return 'https://via.placeholder.com/400x300/4A90E2/FFFFFF?text=Page+$pageNumber';
  }
}

