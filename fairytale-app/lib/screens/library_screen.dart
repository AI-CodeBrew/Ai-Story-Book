import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/story.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../utils/app_colors.dart';
import '../utils/theme_options.dart';
import 'story_viewer_screen.dart';

/// Public, login-free browsing of admin-curated stories, filterable by type,
/// searchable, sortable, and paginated (infinite scroll).
class LibraryScreen extends StatefulWidget {
  final String? initialSearch;
  const LibraryScreen({super.key, this.initialSearch});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  static const _pageSize = 20;

  String? _selectedTheme;
  String _sort = 'newest';
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  final List<Story> _stories = [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  String? _error;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    if (widget.initialSearch != null && widget.initialSearch!.isNotEmpty) {
      _searchController.text = widget.initialSearch!;
    }
    _scrollController.addListener(_onScroll);
    _load();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_hasMore || _loadingMore || _loading) return;
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 300) {
      _loadMore();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _stories.clear();
      _hasMore = true;
    });
    try {
      final page = await ApiService.listStoriesPaged(
        isDefault: true,
        theme: _selectedTheme,
        search: _searchController.text,
        sort: _sort,
        limit: _pageSize,
        skip: 0,
      );
      if (!mounted) return;
      setState(() {
        _stories.addAll(page.stories);
        _hasMore = page.hasMore;
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

  Future<void> _loadMore() async {
    setState(() => _loadingMore = true);
    try {
      final page = await ApiService.listStoriesPaged(
        isDefault: true,
        theme: _selectedTheme,
        search: _searchController.text,
        sort: _sort,
        limit: _pageSize,
        skip: _stories.length,
      );
      if (!mounted) return;
      setState(() {
        _stories.addAll(page.stories);
        _hasMore = page.hasMore;
        _loadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingMore = false);
    }
  }

  void _selectTheme(String? theme) {
    setState(() => _selectedTheme = theme);
    _load();
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), _load);
  }

  void _toggleSort() {
    setState(() => _sort = _sort == 'newest' ? 'oldest' : 'newest');
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      backgroundColor: const Color(0xFFf8f9ff),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text('Library', style: GoogleFonts.nunito(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  ),
                  IconButton(
                    icon: Icon(_sort == 'newest' ? Icons.arrow_downward : Icons.arrow_upward, color: AppColors.primary),
                    tooltip: _sort == 'newest' ? 'Newest first' : 'Oldest first',
                    onPressed: _toggleSort,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                style: GoogleFonts.nunito(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search stories...',
                  hintStyle: GoogleFonts.nunito(color: AppColors.textLight, fontSize: 14),
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            _load();
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFe0e6ed))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFe0e6ed))),
                ),
              ),
            ),
            const SizedBox(height: 12),
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
                                    child: Center(child: Text('No stories found.', style: GoogleFonts.nunito(color: AppColors.textSecondary))),
                                  ),
                                ],
                              )
                            : GridView.builder(
                                controller: _scrollController,
                                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  mainAxisSpacing: 16,
                                  crossAxisSpacing: 16,
                                  childAspectRatio: 0.72,
                                ),
                                itemCount: _stories.length + (_hasMore ? 1 : 0),
                                itemBuilder: (context, index) {
                                  if (index >= _stories.length) {
                                    return const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator()));
                                  }
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
                                          if (auth.isLoggedIn)
                                            Positioned(
                                              top: 6,
                                              right: 6,
                                              child: GestureDetector(
                                                onTap: () => auth.toggleFavorite(story.id),
                                                child: Container(
                                                  padding: const EdgeInsets.all(6),
                                                  decoration: BoxDecoration(color: Colors.black.withOpacity(0.35), shape: BoxShape.circle),
                                                  child: Icon(
                                                    auth.isFavorite(story.id) ? Icons.favorite : Icons.favorite_border,
                                                    size: 16,
                                                    color: auth.isFavorite(story.id) ? Colors.redAccent : Colors.white,
                                                  ),
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
