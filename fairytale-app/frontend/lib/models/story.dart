import '../services/api_service.dart';

class StoryPage {
  final int pageNumber;
  final String script;
  final String? imageUrl;

  StoryPage({
    required this.pageNumber,
    required this.script,
    this.imageUrl,
  });

  factory StoryPage.fromJson(Map<String, dynamic> json) {
    return StoryPage(
      pageNumber: json['pageNumber'] as int,
      script: json['script'] as String,
      imageUrl: json['imageUrl'] != null ? ApiService.getImageUrl(json['imageUrl'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pageNumber': pageNumber,
      'script': script,
      'imageUrl': imageUrl,
    };
  }
}

class Story {
  final String id;
  final String title;
  final List<StoryPage> pages;
  final String theme;
  final String audioUrl;
  final DateTime createdAt;

  Story({
    required this.id,
    required this.title,
    required this.pages,
    required this.theme,
    required this.audioUrl,
    required this.createdAt,
  });

  // Backward compatibility - get content from all pages
  String get content => pages.map((page) => page.script).join('\n\n');
  
  // Backward compatibility - get image URLs from all pages
  List<String> get imageUrls => pages.map((page) => page.imageUrl ?? '').where((url) => url.isNotEmpty).toList();

  factory Story.fromJson(Map<String, dynamic> json) {
    // Handle both old format (content + imageUrls) and new format (pages)
    List<StoryPage> storyPages;
    
    if (json['pages'] != null) {
      // New 10-page format
      storyPages = (json['pages'] as List)
          .map((pageJson) => StoryPage.fromJson(pageJson))
          .toList();
    } else {
      // Backward compatibility with old format
      final content = json['content'] as String? ?? '';
      final imageUrls = json['imageUrls'] as List<dynamic>? ?? [];
      
      // Split content into sentences and create pages
      final sentences = content.split('. ').where((s) => s.trim().isNotEmpty).toList();
      storyPages = [];
      
      for (int i = 0; i < 10; i++) {
        final pageContent = i < sentences.length ? sentences[i] + '.' : 'The story continues...';
        final imageUrl = i < imageUrls.length ? imageUrls[i] as String? : null;
        
        storyPages.add(StoryPage(
          pageNumber: i + 1,
          script: pageContent,
          imageUrl: imageUrl,
        ));
      }
    }

    return Story(
      id: json['id'] as String,
      title: json['title'] as String,
      pages: storyPages,
      theme: json['theme'] as String,
      audioUrl: json['audioUrl'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'pages': pages.map((page) => page.toJson()).toList(),
      'theme': theme,
      'audioUrl': audioUrl,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class StoryRequest {
  final String prompt;
  final String theme;
  final String? additionalContext;
  final String? modelName;

  StoryRequest({
    required this.prompt,
    required this.theme,
    this.additionalContext,
    this.modelName,
  });

  Map<String, dynamic> toJson() {
    return {
      'prompt': prompt,
      'theme': theme,
      'additionalContext': additionalContext,
      'modelName': modelName,
    };
  }
}

class Feedback {
  final String id;
  final String storyId;
  final String feedbackType;
  final String feedbackText;
  final int rating;
  final DateTime timestamp;

  Feedback({
    required this.id,
    required this.storyId,
    required this.feedbackType,
    required this.feedbackText,
    required this.rating,
    required this.timestamp,
  });

  factory Feedback.fromJson(Map<String, dynamic> json) {
    return Feedback(
      id: json['id'] as String,
      storyId: json['storyId'] as String,
      feedbackType: json['feedbackType'] as String,
      feedbackText: json['feedbackText'] as String,
      rating: json['rating'] as int,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'storyId': storyId,
      'feedbackType': feedbackType,
      'feedbackText': feedbackText,
      'rating': rating,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

class ThemeOption {
  final String name;
  final String description;
  final String icon;
  final String color;

  const ThemeOption({
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
  });
}
