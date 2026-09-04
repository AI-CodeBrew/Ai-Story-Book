import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/story.dart';
import '../services/api_service.dart';
import '../utils/app_colors.dart';
import '../utils/theme_options.dart';
import 'story_viewer_screen.dart';

/// Public, login-free browsing of admin-curated stories, filterable by type.
class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  String? _selectedTheme;
  List<Story> _stories = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final stories = await ApiService.listStories(isDefault: true, theme: _selectedTheme, limit: 48);
      if (!mounted) return;
      setState(() {
        _stories = stories;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load the library: $e';
        _loading = false;
      });
    }
  }

  void _selectTheme(String? theme) {
    setState(() => _selectedTheme = theme);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf8f9ff),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Library', style: GoogleFonts.nunito(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              ),
            ),
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _FilterChip(label: 'All', selected: _selectedTheme == null, color: AppColors.primary, onTap: () => _selectTheme(null)),
                  ...kThemeOptions.map((t) => _FilterChip(
                        label: t.name,
                        selected: _selectedTheme == t.name,
                        color: t.color,
                        onTap: () => _selectTheme(t.name),
                      )),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _load,
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                        ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!, style: GoogleFonts.nunito(color: AppColors.error))))
                        : _stories.isEmpty
                            ? ListView(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(40),
                                    child: Center(child: Text('No stories in this category yet.', style: GoogleFonts.nunito(color: AppColors.textSecondary))),
                                  ),
                                ],
                              )
                            : GridView.builder(
                                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  mainAxisSpacing: 16,
                                  crossAxisSpacing: 16,
                                  childAspectRatio: 0.72,
                                ),
                                itemCount: _stories.length,
                                itemBuilder: (context, index) {
                                  final story = _stories[index];
                                  final cover = story.pages.firstWhere((p) => p.imageUrl != null && p.imageUrl!.isNotEmpty, orElse: () => story.pages.first).imageUrl;
                                  final color = kThemeOptions.firstWhere((t) => t.name.toLowerCase() == story.theme.toLowerCase(), orElse: () => kThemeOptions.first).color;
                                  return GestureDetector(
                                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => StoryViewerScreen(storyId: story.id))),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(18),
                                      child: Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          if (cover != null && cover.isNotEmpty)
                                            CachedNetworkImage(imageUrl: cover, fit: BoxFit.cover)
                                          else
                                            Container(color: color.withOpacity(0.3), child: const Center(child: Icon(Icons.menu_book, size: 40, color: Colors.white))),
                                          Positioned(
                                            left: 0,
                                            right: 0,
                                            bottom: 0,
                                            child: Container(
                                              padding: const EdgeInsets.fromLTRB(12, 24, 12, 10),
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  begin: Alignment.topCenter,
                                                  end: Alignment.bottomCenter,
                                                  colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                                                ),
                                              ),
                                              child: Text(
                                                story.title,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.selected, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label, style: GoogleFonts.nunito(fontWeight: FontWeight.w600, color: selected ? Colors.white : color)),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: color,
        backgroundColor: color.withOpacity(0.12),
        side: BorderSide(color: color.withOpacity(0.3)),
      ),
    );
  }
}
