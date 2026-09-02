import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/story_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/app_colors.dart';
import '../utils/ai_config.dart';
import '../models/story.dart';
import '../services/connectivity_service.dart';
import 'story_viewer_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _promptController = TextEditingController();
  final TextEditingController _contextController = TextEditingController();
  String _selectedTheme = 'Adventure';

  final List<Map<String, dynamic>> _themes = [
    {
      'name': 'Adventure',
      'icon': Icons.explore,
      'color': AppColors.adventure,
      'description': 'Exciting quests and discoveries',
    },
    {
      'name': 'Fantasy',
      'icon': Icons.auto_awesome,
      'color': AppColors.fantasy,
      'description': 'Magical worlds and creatures',
    },
    {
      'name': 'Space',
      'icon': Icons.rocket_launch,
      'color': AppColors.space,
      'description': 'Futuristic space adventures',
    },
    {
      'name': 'Nature',
      'icon': Icons.eco,
      'color': AppColors.nature,
      'description': 'Beautiful natural world',
    },
    {
      'name': 'Friendship',
      'icon': Icons.favorite,
      'color': AppColors.friendship,
      'description': 'Heartwarming friendship stories',
    },
    {
      'name': 'Science',
      'icon': Icons.science,
      'color': AppColors.science,
      'description': 'Educational scientific concepts',
    },
  ];

  @override
  void initState() {
    super.initState();
    // Set default theme to Adventure if not already set
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        _selectedTheme = context.read<ThemeProvider>().selectedTheme;
      } catch (e) {
        // If ThemeProvider not available, keep default
        _selectedTheme = 'Adventure';
      }
    });
    
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF667eea).withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.auto_stories,
                size: 28,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AI Storybook',
                    style: GoogleFonts.nunito(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2c3e50),
                    ),
                  ),
                  Text(
                    'Create magical stories with AI',
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      color: const Color(0xFF7f8c8d),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStoryForm() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFe0e6ed),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Story Prompt Section
          Text(
            'What story would you like to create?',
            style: GoogleFonts.nunito(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2c3e50),
            ),
          ),
          const SizedBox(height: 16),
          
          // Story Prompt Input
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFe0e6ed),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _promptController,
              maxLines: 4,
              style: GoogleFonts.nunito(
                color: const Color(0xFF2c3e50),
                fontSize: 14,
              ),
              decoration: InputDecoration(
                hintText: 'A brave knight rescues a dragon from a princess...',
                hintStyle: GoogleFonts.nunito(
                  color: const Color(0xFF95a5a6),
                  fontSize: 14,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(18),
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Generate Button
          _buildGenerateButton(),
        ],
      ),
    );
  }

  Widget _buildGenerateButton() {
    return Consumer<StoryProvider>(
      builder: (context, storyProvider, child) {
        return SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: storyProvider.isLoading || storyProvider.isLoadingImages
                ? null
                : () => _generateStory(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF667eea).withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: (storyProvider.isLoading || storyProvider.isLoadingImages)
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Generating Story...',
                          style: GoogleFonts.nunito(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.auto_stories, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Generate Story',
                          style: GoogleFonts.nunito(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildThemeInspirations() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.lightbulb_outline,
              color: Colors.amber,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Story Inspirations',
              style: GoogleFonts.nunito(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF2c3e50),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Choose a theme to spark your creativity',
          style: GoogleFonts.nunito(
            fontSize: 14,
            color: const Color(0xFF7f8c8d),
          ),
        ),
        const SizedBox(height: 16),
        
        // Theme Cards
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _themes.map((theme) {
            final isSelected = _selectedTheme == theme['name'];
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTheme = theme['name'] as String;
                });
                try {
                  context.read<ThemeProvider>().setTheme(_selectedTheme);
                } catch (e) {
                  // Provider not available, continue with local state
                }
              },
              child: Container(
                width: (MediaQuery.of(context).size.width - 64) / 2,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: isSelected 
                      ? LinearGradient(
                          colors: [
                            theme['color'] as Color,
                            (theme['color'] as Color).withOpacity(0.8),
                          ],
                        )
                      : LinearGradient(
                          colors: [
                            Colors.white,
                            const Color(0xFFf8f9ff),
                          ],
                        ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected 
                        ? theme['color'] as Color
                        : const Color(0xFFe0e6ed),
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: isSelected ? [
                    BoxShadow(
                      color: (theme['color'] as Color).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ] : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        theme['icon'] as IconData,
                        size: 16,
                        color: isSelected ? Colors.white : theme['color'] as Color,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        theme['name'] as String,
                        style: GoogleFonts.nunito(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : const Color(0xFF2c3e50),
                        ),
                      ),
                    ),
                    if (isSelected)
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.check,
                          size: 10,
                          color: Colors.black,
                        ),
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf8f9ff), // Fallback color
      body: Container(
        height: MediaQuery.of(context).size.height,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFf8f9ff),
              Color(0xFFe8f2ff),
              Color(0xFFf0f4ff),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section
                _buildHeader(),
                
                const SizedBox(height: 32),
                
                // Story Creation Form
                _buildStoryForm(),
                
                const SizedBox(height: 24),
                
                // Theme Inspirations Section
                _buildThemeInspirations(),
                
                const SizedBox(height: 16),
                
                // Error Display
                Consumer<StoryProvider>(
                  builder: (context, storyProvider, child) {
                    if (storyProvider.error != null) {
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.error),
                        ),
                        child: Text(
                          storyProvider.error!,
                          style: GoogleFonts.nunito(
                            color: AppColors.error,
                            fontSize: 14,
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _generateStory(BuildContext context) async {
    if (_promptController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please enter a story prompt',
            style: GoogleFonts.nunito(),
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Check internet connectivity before generating story
    final hasInternet = await ConnectivityService.hasInternetConnection();
    
    if (!hasInternet) {
      _showNoInternetDialog(context);
      return;
    }

    final request = StoryRequest(
      prompt: _promptController.text.trim(),
      theme: _selectedTheme,
      additionalContext: _contextController.text.trim().isNotEmpty
          ? _contextController.text.trim()
          : null,
      modelName: AIConfig.modelName,
    );

    // Listen to story provider changes to navigate when everything is complete
      final storyProvider = context.read<StoryProvider>();
    
    // Start the story generation process
    storyProvider.generateStory(request);
    
    // Listen for completion (both story text and images done)
    void checkCompletion() {
      if (!storyProvider.isLoading && !storyProvider.isLoadingImages && storyProvider.currentStory != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StoryViewerScreen(story: storyProvider.currentStory!),
          ),
        );
      }
    }
    
    // Check completion periodically
    Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      checkCompletion();
      
      // Cancel timer if we're done (either success or error)
      if (!storyProvider.isLoading && !storyProvider.isLoadingImages) {
        timer.cancel();
      }
    });
  }

  void _showNoInternetDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.wifi_off,
                color: AppColors.error,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                'No Internet Connection',
                style: GoogleFonts.nunito(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Please check your internet connection and try again.',
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Story generation requires an active internet connection to access AI services.',
                        style: GoogleFonts.nunito(
                          fontSize: 12,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                
                // Check connectivity again
                final hasInternet = await ConnectivityService.hasInternetConnection();
                if (hasInternet) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Internet connection restored! You can now generate stories.',
                        style: GoogleFonts.nunito(),
                      ),
                      backgroundColor: AppColors.success,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              },
              child: Text(
                'Check Again',
                style: GoogleFonts.nunito(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'OK',
                style: GoogleFonts.nunito(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _promptController.dispose();
    _contextController.dispose();
    super.dispose();
  }
}
