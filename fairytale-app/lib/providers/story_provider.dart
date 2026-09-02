import 'package:flutter/foundation.dart';
import '../models/story.dart';
import '../services/api_service.dart';
import '../services/story_image_service.dart';

class StoryProvider extends ChangeNotifier {
  Story? _currentStory;
  bool _isLoading = false;
  bool _isLoadingImages = false;
  String? _error;
  int _imageProgress = 0;
  int _totalImages = 0;

  Story? get currentStory => _currentStory;
  bool get isLoading => _isLoading;
  bool get isLoadingImages => _isLoadingImages;
  String? get error => _error;
  int get imageProgress => _imageProgress;
  int get totalImages => _totalImages;
  
  double get imageProgressPercentage => 
      _totalImages > 0 ? _imageProgress / _totalImages : 0.0;

  Future<void> generateStory(StoryRequest request) async {
    _setLoading(true);
    _error = null;

    try {
      print('🔄 Starting story generation...');
      print('📝 Request: ${request.toJson()}');

      // Step 1: Generate story text only (fast)
      final story = await ApiService.generateStory(request);
      print('✅ Story text generated successfully');
      print('📖 Story title: ${story.title}');
      print('📄 Pages count: ${story.pages.length}');

      _currentStory = story;
      _setLoading(false);
      notifyListeners();

      // Step 2: Generate images separately (may take time)
      await generateImagesForCurrentStory();
    } catch (e, stackTrace) {
      print('❌ STORY GENERATION ERROR:');
      print('🔴 Error: $e');
      print('🔴 Stack Trace: $stackTrace');
      print('🔴 Error type: ${e.runtimeType}');
      print('🔴 Error toString: ${e.toString()}');

      _error = e.toString();
      notifyListeners();
    } finally {
      _setLoading(false);
      print('🏁 Story generation process finished');
    }
  }

  void clearStory() {
    _currentStory = null;
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setImageLoading(bool loading) {
    _isLoadingImages = loading;
    notifyListeners();
  }

  Future<void> generateImagesForCurrentStory({bool parallel = true}) async {
    if (_currentStory == null) return;

    _setImageLoading(true);
    _imageProgress = 0;
    _totalImages = _currentStory!.pages.length;
    notifyListeners();

    try {
      print('🎨 Starting image generation for ${_totalImages} pages...');

      final storyWithImages = await StoryImageService.generateImagesForStory(
        _currentStory!,
        parallel: parallel,
        onProgress: (completed, total) {
          _imageProgress = completed;
          notifyListeners();
          print('🖼️ Image progress: $completed/$total');
        },
      );

      _currentStory = storyWithImages;
      print('✅ All images generated successfully');
      notifyListeners();

    } catch (e) {
      print('❌ Error generating images: $e');
      // Keep the story with placeholder images
    } finally {
      _setImageLoading(false);
    }
  }

  Future<void> regenerateImageForPage(int pageNumber) async {
    if (_currentStory == null) return;

    try {
      final pageIndex = pageNumber - 1;
      if (pageIndex < 0 || pageIndex >= _currentStory!.pages.length) return;

      final page = _currentStory!.pages[pageIndex];
      print('🔄 Regenerating image for page $pageNumber...');

      final newImageUrl = await StoryImageService.generateImageForPage(
        page, 
        _currentStory!.theme,
      );

      if (newImageUrl != null) {
        final updatedPages = List<StoryPage>.from(_currentStory!.pages);
        updatedPages[pageIndex] = StoryPage(
          pageNumber: page.pageNumber,
          script: page.script,
          imageUrl: newImageUrl,
        );

        _currentStory = Story(
          id: _currentStory!.id,
          title: _currentStory!.title,
          pages: updatedPages,
          theme: _currentStory!.theme,
          audioUrl: _currentStory!.audioUrl,
          createdAt: _currentStory!.createdAt,
        );

        print('✅ Image regenerated for page $pageNumber');
        notifyListeners();
      }
    } catch (e) {
      print('❌ Error regenerating image for page $pageNumber: $e');
    }
  }
}
