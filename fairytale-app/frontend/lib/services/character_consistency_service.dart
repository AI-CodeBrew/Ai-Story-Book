import 'dart:convert';
import '../models/story.dart';
import '../utils/ai_config.dart';
import 'api_service.dart';

class CharacterConsistencyService {
  // Extract character details from story using AI
  static Future<Map<String, String>> extractCharacterDetails(Story story) async {
    try {
      print('🔍 Extracting character details from story...');
      
      // Combine all story content for character analysis
      final fullStory = story.pages.map((page) => page.script).join(' ');
      
      final characterPrompt = '''
Analyze this children's story and extract consistent character descriptions for illustration:

Story: $fullStory

Please identify the main characters and provide detailed, consistent descriptions for each character that should remain the same throughout all illustrations. Include:

1. Physical appearance (age, hair color, eye color, height, build)
2. Clothing style and colors
3. Distinctive features
4. Any pets or companions

Format your response as JSON:
{
  "characters": {
    "character1_name": "Detailed description including age, appearance, clothing, etc.",
    "character2_name": "Detailed description including age, appearance, clothing, etc."
  },
  "setting": "Brief description of the main setting/location",
  "style_notes": "Any specific artistic style preferences for consistency"
}

Example:
{
  "characters": {
    "Lily": "15-year-old girl with long brown hair, bright green eyes, wearing a yellow flowery dress with white sneakers, friendly smile",
    "Tom": "14-year-old boy with short black hair, blue eyes, wearing blue jeans and a red t-shirt, adventurous look",
    "Buddy": "Small white puppy with floppy ears, brown eyes, wearing a blue collar"
  },
  "setting": "Magical forest with tall trees, sunlight filtering through leaves",
  "style_notes": "Child-friendly illustration style, vibrant colors, detailed but simple"
}
''';

      final result = await ApiService.generateText(
        prompt: characterPrompt,
        systemInstruction: 'You are an expert at analyzing children\'s stories and extracting consistent character descriptions for illustration. Always respond with valid JSON format.',
        modelName: AIConfig.modelName,
      );

      if (result['success'] == true && result['text'] != null) {
        final characterText = result['text'] as String;
        print('✅ Character analysis completed');
        
        // Parse the JSON response
        try {
          final characterData = jsonDecode(characterText);
          print('📋 Extracted characters: ${characterData['characters']?.keys?.toList()}');
          return Map<String, String>.from(characterData['characters'] ?? {});
        } catch (e) {
          print('❌ Error parsing character JSON: $e');
          return _extractCharactersFromText(characterText);
        }
      }
      
      print('❌ Character extraction failed, using fallback');
      return _getFallbackCharacters(story);
      
    } catch (e) {
      print('❌ Error extracting character details: $e');
      return _getFallbackCharacters(story);
    }
  }

  // Fallback method to extract characters from text if JSON parsing fails
  static Map<String, String> _extractCharactersFromText(String text) {
    final characters = <String, String>{};
    
    // Simple text parsing to find character descriptions
    final lines = text.split('\n');
    for (final line in lines) {
      if (line.contains(':')) {
        final parts = line.split(':');
        if (parts.length >= 2) {
          final name = parts[0].trim().replaceAll('"', '').replaceAll('{', '').replaceAll('}', '');
          final description = parts[1].trim().replaceAll('"', '').replaceAll(',', '');
          if (name.isNotEmpty && description.isNotEmpty) {
            characters[name] = description;
          }
        }
      }
    }
    
    return characters;
  }

  // Fallback characters if extraction fails
  static Map<String, String> _getFallbackCharacters(Story story) {
    // Generate generic character descriptions based on theme
    final theme = story.theme.toLowerCase();
    
    switch (theme) {
      case 'adventure':
        return {
          'Hero': 'Brave young adventurer with determined eyes, wearing practical adventure clothes',
          'Companion': 'Loyal friend with a warm smile, dressed in comfortable exploration gear'
        };
      case 'fantasy':
        return {
          'Princess': 'Beautiful young girl with flowing hair, wearing a magical dress with sparkles',
          'Wizard': 'Wise young person with a pointed hat and robes, carrying a magical staff'
        };
      case 'space':
        return {
          'Astronaut': 'Young space explorer in a futuristic suit with a helmet',
          'Alien': 'Friendly alien creature with big eyes and a welcoming smile'
        };
      case 'nature':
        return {
          'Explorer': 'Curious child with a nature guide outfit and a backpack',
          'Animal': 'Cute forest animal companion with bright, friendly eyes'
        };
      case 'friendship':
        return {
          'Friend1': 'Happy child with a warm smile, wearing colorful casual clothes',
          'Friend2': 'Cheerful child with bright eyes, dressed in comfortable play clothes'
        };
      case 'science':
        return {
          'Scientist': 'Young scientist with safety goggles and a lab coat',
          'Assistant': 'Curious helper with a magnifying glass and explorer outfit'
        };
      default:
        return {
          'Main Character': 'Friendly child with a bright smile, wearing comfortable clothes',
          'Sidekick': 'Loyal companion with a happy expression and casual outfit'
        };
    }
  }

  // Generate enhanced image prompt with character consistency
  static String buildConsistentImagePrompt({
    required String pageScript,
    required String theme,
    required Map<String, String> characters,
    required int pageNumber,
  }) {
    // Build character descriptions string
    final characterDescriptions = characters.entries
        .map((entry) => '${entry.key}: ${entry.value}')
        .join(', ');

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
Create a beautiful, detailed illustration for a children's story (Page $pageNumber):

STORY SCENE: $pageScript

CHARACTER CONSISTENCY - Use these exact character descriptions:
$characterDescriptions

IMPORTANT: The characters must look EXACTLY the same as described above. Maintain consistent:
- Physical appearance (age, hair, eyes, build)
- Clothing and colors
- Distinctive features
- Any pets or companions

STYLE: $style, child-friendly, vibrant colors, detailed but simple, storybook illustration
FORMAT: High-quality digital art suitable for a children's book
CONSISTENCY: Ensure characters maintain their appearance throughout the story
''';
  }
}
