import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/story.dart';
import '../providers/auth_provider.dart';
import '../providers/story_provider.dart';
import '../providers/theme_provider.dart';
import '../services/api_service.dart';
import '../services/connectivity_service.dart';
import '../utils/ai_config.dart';
import '../utils/app_colors.dart';
import '../utils/theme_options.dart';
import 'library_screen.dart';
import 'login_screen.dart';
import 'story_viewer_screen.dart';

/// Small local record of the last story the user finished generating, so
/// Home can offer a one-tap "Continue reading" shortcut back to it.
class _LastStory {
  final String id;
  final String title;
  final String? cover;
  const _LastStory({required this.id, required this.title, this.cover});

  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'cover': cover};
  factory _LastStory.fromJson(Map<String, dynamic> json) =>
      _LastStory(id: json['id'] as String, title: json['title'] as String, cover: json['cover'] as String?);
}

/// The app's home tab: the story-creation form up front, with the same
/// admin-curated public stories shown on the website landing page (readable
/// without logging in) as an auto-scrolling strip below it.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _promptController = TextEditingController();
  String _selectedTheme = 'Adventure';
  bool _isSaving = false;

  List<Story> _stories = [];
  bool _loadingStories = true;
  String? _error;

  final TextEditingController _searchController = TextEditingController();
  _LastStory? _lastStory;

  // Auto-scrolling stories row
  static const double _marqueeCardWidth = 132;
  final ScrollController _marqueeController = ScrollController();
  Timer? _marqueeTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        _selectedTheme = context.read<ThemeProvider>().selectedTheme;
      } catch (e) {
        _selectedTheme = 'Adventure';
      }
    });
    _loadStories();
    _loadLastStory();
  }

  @override
  void dispose() {
    _promptController.dispose();
    _searchController.dispose();
    _marqueeTimer?.cancel();
    _marqueeController.dispose();
    super.dispose();
  }

  Future<void> _loadLastStory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('last_story');
      if (raw == null) return;
      if (!mounted) return;
      setState(() => _lastStory = _LastStory.fromJson(jsonDecode(raw) as Map<String, dynamic>));
    } catch (e) {
      // Corrupt/old cache entry — ignore, just skip the continue card.
    }
  }

  Future<void> _saveLastStory(Story story) async {
    final cover = story.pages
        .firstWhere((p) => p.imageUrl != null && p.imageUrl!.isNotEmpty, orElse: () => story.pages.first)
        .imageUrl;
    final entry = _LastStory(id: story.id, title: story.title, cover: cover);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_story', jsonEncode(entry.toJson()));
    } catch (e) {
      // Non-critical convenience cache — safe to skip on failure.
    }
    if (!mounted) return;
    setState(() => _lastStory = entry);
  }

  void _openLibrarySearch() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => LibraryScreen(initialSearch: _searchController.text.trim())),
    );
  }

  Future<void> _loadStories() async {
    setState(() {
      _loadingStories = true;
      _error = null;
    });
    try {
      var stories = await ApiService.listStories(isDefault: true, limit: 8);
      if (stories.isEmpty) {
        stories = await ApiService.listStories(limit: 12);
      }
      if (!mounted) return;
      setState(() {
        _stories = stories;
        _loadingStories = false;
      });
      _startMarquee();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load stories: $e';
        _loadingStories = false;
      });
    }
  }

  // Two back-to-back copies of the list let the marquee wrap seamlessly:
  // jumping backward by exactly one set width lands on an identical frame.
  void _startMarquee() {
    if (_stories.isEmpty) return;
    final setWidth = _marqueeCardWidth * _stories.length;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_marqueeController.hasClients) {
        _marqueeController.jumpTo(setWidth);
      }
    });
    _marqueeTimer?.cancel();
    _marqueeTimer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (!mounted || !_marqueeController.hasClients) return;
      double next = _marqueeController.offset - 0.6;
      if (next <= 0) next += setWidth;
      _marqueeController.jumpTo(next);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf8f9ff),
      body: Container(
        height: MediaQuery.of(context).size.height,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFf8f9ff), Color(0xFFe8f2ff), Color(0xFFf0f4ff)],
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _loadStories,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 20),
                  _buildSearchBar(),
                  if (_lastStory != null) ...[
                    const SizedBox(height: 16),
                    _buildContinueCard(),
                  ],
                  const SizedBox(height: 24),
                  _buildStoryForm(),
                  const SizedBox(height: 24),
                  _buildThemeInspirations(),
                  const SizedBox(height: 24),
                  _buildStoriesMarquee(),
                  const SizedBox(height: 16),
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
                            style: GoogleFonts.nunito(color: AppColors.error, fontSize: 14),
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
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF667eea), Color(0xFF764ba2)]),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF667eea).withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(Icons.auto_stories, size: 28, color: Colors.white),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'FairyTale AI',
                style: GoogleFonts.nunito(fontSize: 26, fontWeight: FontWeight.bold, color: const Color(0xFF2c3e50)),
              ),
              Text(
                'Create magical stories with AI',
                style: GoogleFonts.nunito(fontSize: 14, color: const Color(0xFF7f8c8d)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      onSubmitted: (_) => _openLibrarySearch(),
      style: GoogleFonts.nunito(fontSize: 14),
      decoration: InputDecoration(
        hintText: 'Search the Library...',
        hintStyle: GoogleFonts.nunito(color: const Color(0xFF95a5a6), fontSize: 14),
        prefixIcon: const Icon(Icons.search, size: 20),
        suffixIcon: IconButton(icon: const Icon(Icons.arrow_forward, size: 18), onPressed: _openLibrarySearch),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFe0e6ed))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFe0e6ed))),
      ),
    );
  }

  Widget _buildContinueCard() {
    final story = _lastStory!;
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => StoryViewerScreen(storyId: story.id))),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFe0e6ed)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 48,
                height: 48,
                child: story.cover != null && story.cover!.isNotEmpty
                    ? CachedNetworkImage(imageUrl: story.cover!, fit: BoxFit.cover)
                    : Container(color: const Color(0xFF667eea).withOpacity(0.15), child: const Icon(Icons.menu_book, color: Color(0xFF667eea))),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Continue Reading', style: GoogleFonts.nunito(fontSize: 11, color: const Color(0xFF7f8c8d))),
                  Text(story.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.nunito(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF95a5a6)),
          ],
        ),
      ),
    );
  }

  Widget _buildStoryForm() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFe0e6ed), width: 1),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What story would you like to create?',
            style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.w600, color: const Color(0xFF2c3e50)),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFe0e6ed), width: 1),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2)),
              ],
            ),
            child: TextField(
              controller: _promptController,
              maxLines: 4,
              style: GoogleFonts.nunito(color: const Color(0xFF2c3e50), fontSize: 14),
              decoration: InputDecoration(
                hintText: 'A brave knight rescues a dragon from a princess...',
                hintStyle: GoogleFonts.nunito(color: const Color(0xFF95a5a6), fontSize: 14),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(18),
              ),
            ),
          ),
          const SizedBox(height: 24),
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
            onPressed: storyProvider.isLoading || storyProvider.isLoadingImages || _isSaving
                ? null
                : () => _generateStory(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF667eea), Color(0xFF764ba2)]),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: const Color(0xFF667eea).withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4)),
                ],
              ),
              child: (storyProvider.isLoading || storyProvider.isLoadingImages || _isSaving)
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _isSaving ? 'Saving your storybook...' : 'Generating Story...',
                          style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
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
                          style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
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
            Icon(Icons.lightbulb_outline, color: Colors.amber, size: 20),
            const SizedBox(width: 8),
            Text(
              'Story Inspirations',
              style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.w600, color: const Color(0xFF2c3e50)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Choose a theme to spark your creativity',
          style: GoogleFonts.nunito(fontSize: 14, color: const Color(0xFF7f8c8d)),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: kThemeOptions.map((theme) {
            final isSelected = _selectedTheme == theme.name;
            return GestureDetector(
              onTap: () {
                setState(() => _selectedTheme = theme.name);
                try {
                  context.read<ThemeProvider>().setTheme(_selectedTheme);
                } catch (e) {
                  // Provider not available, continue with local state
                }
              },
              child: Container(
                width: ((MediaQuery.of(context).size.width - 64) / 2).clamp(80.0, double.infinity),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(colors: [theme.color, theme.color.withOpacity(0.8)])
                      : const LinearGradient(colors: [Colors.white, Color(0xFFf8f9ff)]),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? theme.color : const Color(0xFFe0e6ed),
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: isSelected
                      ? [BoxShadow(color: theme.color.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))]
                      : [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4, offset: const Offset(0, 1))],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(theme.icon, size: 16, color: isSelected ? Colors.white : theme.color),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        theme.name,
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
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: const Icon(Icons.check, size: 10, color: Colors.black),
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

  Widget _buildStoriesMarquee() {
    if (_loadingStories) {
      return const SizedBox(height: 150, child: Center(child: CircularProgressIndicator()));
    }
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(_error!, style: GoogleFonts.nunito(color: AppColors.error)),
      );
    }
    if (_stories.isEmpty) {
      return const SizedBox.shrink();
    }

    final displayList = [..._stories, ..._stories];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Explore Stories',
          style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.w600, color: const Color(0xFF2c3e50)),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 150,
          child: ListView.builder(
            controller: _marqueeController,
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: displayList.length,
            itemBuilder: (context, index) {
              final story = displayList[index];
              final cover = story.pages
                  .firstWhere((p) => p.imageUrl != null && p.imageUrl!.isNotEmpty, orElse: () => story.pages.first)
                  .imageUrl;
              final color = kThemeOptions
                  .firstWhere((t) => t.name.toLowerCase() == story.theme.toLowerCase(), orElse: () => kThemeOptions.first)
                  .color;
              return GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => StoryViewerScreen(storyId: story.id)),
                ),
                child: Container(
                  width: _marqueeCardWidth - 12,
                  margin: const EdgeInsets.only(right: 12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (cover != null && cover.isNotEmpty)
                          CachedNetworkImage(imageUrl: cover, fit: BoxFit.cover)
                        else
                          Container(
                            color: color.withOpacity(0.3),
                            child: const Center(child: Icon(Icons.menu_book, color: Colors.white)),
                          ),
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Colors.transparent, Colors.black.withOpacity(0.75)],
                              ),
                            ),
                            child: Text(
                              story.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _generateStory(BuildContext context) async {
    if (_promptController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a story prompt', style: GoogleFonts.nunito()), backgroundColor: AppColors.error),
      );
      return;
    }

    // The form is visible even to logged-out users now (it's the Home tab),
    // so prompt for login here instead of gating the whole screen behind it.
    final auth = context.read<AuthProvider>();
    String? authToken = auth.token;
    if (!auth.isLoggedIn) {
      final loggedIn = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      if (loggedIn != true || !context.mounted) return;
      authToken = context.read<AuthProvider>().token;
    }
    if (authToken == null) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please log in again.', style: GoogleFonts.nunito())),
      );
      return;
    }

    final hasInternet = await ConnectivityService.hasInternetConnection();
    if (!hasInternet) {
      if (!context.mounted) return;
      _showNoInternetDialog(context);
      return;
    }

    final request = StoryRequest(
      prompt: _promptController.text.trim(),
      theme: _selectedTheme,
      modelName: AIConfig.modelName,
    );

    final storyProvider = context.read<StoryProvider>();
    bool navigated = false;

    storyProvider.generateStory(request, authToken);

    Future<void> checkCompletion() async {
      if (navigated || storyProvider.isLoading || storyProvider.isLoadingImages || storyProvider.currentStory == null) {
        return;
      }
      navigated = true;

      Story storyToShow = storyProvider.currentStory!;
      setState(() => _isSaving = true);
      try {
        storyToShow = await ApiService.saveStory(storyToShow, authToken!);
      } catch (e) {
        print('❌ Failed to save story: $e');
      }
      await _saveLastStory(storyToShow);
      if (!mounted) return;
      setState(() => _isSaving = false);

      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => StoryViewerScreen(story: storyToShow)),
      );
    }

    Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      checkCompletion();
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.wifi_off, color: AppColors.error, size: 28),
              const SizedBox(width: 12),
              Text(
                'No Internet Connection',
                style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Please check your internet connection and try again.',
                style: GoogleFonts.nunito(fontSize: 14, color: AppColors.textSecondary),
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
                    Icon(Icons.info_outline, color: AppColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Story generation requires an active internet connection to access AI services.',
                        style: GoogleFonts.nunito(fontSize: 12, color: AppColors.primary),
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
                final hasInternet = await ConnectivityService.hasInternetConnection();
                if (hasInternet && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Internet connection restored! You can now generate stories.', style: GoogleFonts.nunito()),
                      backgroundColor: AppColors.success,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              },
              child: Text('Check Again', style: GoogleFonts.nunito(color: AppColors.primary, fontWeight: FontWeight.w600)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text('OK', style: GoogleFonts.nunito(color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ],
        );
      },
    );
  }
}
