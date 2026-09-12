import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/story.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../utils/app_colors.dart';
import 'login_screen.dart';
import 'settings_screen.dart';
import 'story_viewer_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

enum _ProfileTab { myStories, favorites }

class _ProfileScreenState extends State<ProfileScreen> {
  List<Story>? _stories;
  List<Story>? _favorites;
  String? _error;
  _ProfileTab _tab = _ProfileTab.myStories;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = context.watch<AuthProvider>();
    if (auth.isLoggedIn && _stories == null && _error == null) {
      _loadStories(auth.token!);
    }
  }

  Future<void> _loadStories(String token) async {
    try {
      final page = await ApiService.myStoriesPaged(token, limit: 50);
      if (!mounted) return;
      setState(() => _stories = page.stories);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Failed to load your stories: $e');
    }
  }

  Future<void> _loadFavorites(String token) async {
    try {
      final page = await ApiService.myFavoriteStories(token, limit: 50);
      if (!mounted) return;
      setState(() => _favorites = page.stories);
    } catch (e) {
      if (!mounted) return;
      setState(() => _favorites = []);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load favorites: $e', style: GoogleFonts.nunito())),
      );
    }
  }

  void _selectTab(_ProfileTab tab, String token) {
    setState(() => _tab = tab);
    if (tab == _ProfileTab.favorites && _favorites == null) {
      _loadFavorites(token);
    }
  }

  Future<void> _confirmLogout(BuildContext context, AuthProvider auth) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You can always log back in with your email or Google account.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Log out')),
        ],
      ),
    );
    if (confirmed == true) auth.logout();
  }

  Future<void> _editName(BuildContext context, AuthProvider auth) async {
    final controller = TextEditingController(text: auth.user?['name'] as String? ?? '');
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit name'),
        content: TextField(controller: controller, autofocus: true, decoration: const InputDecoration(hintText: 'Your name')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (newName == null || newName.isEmpty) return;
    final ok = await auth.updateName(newName);
    if (!context.mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update name.', style: GoogleFonts.nunito())),
      );
    }
  }

  Future<void> _deleteStory(BuildContext context, Story story, String token) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete story?'),
        content: Text('"${story.title}" will be permanently deleted.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ApiService.deleteStory(story.id, token);
      if (!mounted) return;
      setState(() => _stories = _stories!.where((s) => s.id != story.id).toList());
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete: $e', style: GoogleFonts.nunito())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (!auth.isLoggedIn) {
      return Scaffold(
        backgroundColor: const Color(0xFFf8f9ff),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.account_circle, size: 72, color: AppColors.primary.withOpacity(0.6)),
                  const SizedBox(height: 16),
                  Text('Log in to see your profile', style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  const SizedBox(height: 8),
                  Text('Your account, history, and saved stories live here.', textAlign: TextAlign.center, style: GoogleFonts.nunito(color: AppColors.textSecondary)),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14)),
                    child: Text('Log in', style: GoogleFonts.nunito(fontWeight: FontWeight.w600, color: Colors.white)),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final user = auth.user;
    final token = auth.token!;
    final activeList = _tab == _ProfileTab.myStories ? _stories : _favorites;

    return Scaffold(
      backgroundColor: const Color(0xFFf8f9ff),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _tab == _ProfileTab.myStories ? _loadStories(token) : _loadFavorites(token),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: AppColors.primary,
                        child: Text(
                          (user?['name'] as String? ?? '?').characters.first.toUpperCase(),
                          style: GoogleFonts.nunito(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    user?['name'] as String? ?? '',
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.nunito(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit, size: 16, color: AppColors.textLight),
                                  onPressed: () => _editName(context, auth),
                                  constraints: const BoxConstraints(),
                                  padding: const EdgeInsets.only(left: 8),
                                  visualDensity: VisualDensity.compact,
                                ),
                              ],
                            ),
                            Text(user?['email'] as String? ?? '', style: GoogleFonts.nunito(fontSize: 13, color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.settings_outlined, color: AppColors.textSecondary),
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
                        tooltip: 'Settings',
                      ),
                      IconButton(
                        icon: const Icon(Icons.logout, color: AppColors.textSecondary),
                        onPressed: () => _confirmLogout(context, auth),
                        tooltip: 'Log out',
                      ),
                    ],
                  ),
                ),
              ),
              if (_stories != null)
                SliverToBoxAdapter(child: _buildStats(_stories!)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Row(
                    children: [
                      _TabChip(label: 'My Stories', selected: _tab == _ProfileTab.myStories, onTap: () => _selectTab(_ProfileTab.myStories, token)),
                      const SizedBox(width: 8),
                      _TabChip(label: 'Favorites', selected: _tab == _ProfileTab.favorites, onTap: () => _selectTab(_ProfileTab.favorites, token)),
                    ],
                  ),
                ),
              ),
              if (_tab == _ProfileTab.myStories && _error != null)
                SliverToBoxAdapter(
                  child: Padding(padding: const EdgeInsets.all(20), child: Text(_error!, style: GoogleFonts.nunito(color: AppColors.error))),
                )
              else if (activeList == null)
                const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator())))
              else if (activeList.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      _tab == _ProfileTab.myStories ? "You haven't created any stories yet." : "No favorites yet — tap the heart on a story to save it here.",
                      style: GoogleFonts.nunito(color: AppColors.textSecondary),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  sliver: SliverList.separated(
                    itemCount: activeList.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final story = activeList[index];
                      final cover = story.pages.firstWhere((p) => p.imageUrl != null && p.imageUrl!.isNotEmpty, orElse: () => story.pages.first).imageUrl;
                      return Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => StoryViewerScreen(storyId: story.id))),
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: SizedBox(
                                    width: 56,
                                    height: 56,
                                    child: cover != null && cover.isNotEmpty
                                        ? CachedNetworkImage(imageUrl: cover, fit: BoxFit.cover)
                                        : Container(color: AppColors.primary.withOpacity(0.15), child: const Icon(Icons.menu_book, color: AppColors.primary)),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(story.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.nunito(fontWeight: FontWeight.w600)),
                                      Text(story.theme, style: GoogleFonts.nunito(fontSize: 12, color: AppColors.textSecondary)),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    auth.isFavorite(story.id) ? Icons.favorite : Icons.favorite_border,
                                    color: auth.isFavorite(story.id) ? AppColors.error : AppColors.textLight,
                                    size: 20,
                                  ),
                                  onPressed: () => auth.toggleFavorite(story.id),
                                ),
                                if (_tab == _ProfileTab.myStories)
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: AppColors.textLight, size: 20),
                                    onPressed: () => _deleteStory(context, story, token),
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
          ),
        ),
      ),
    );
  }

  Widget _buildStats(List<Story> stories) {
    final themeCounts = <String, int>{};
    for (final s in stories) {
      themeCounts[s.theme] = (themeCounts[s.theme] ?? 0) + 1;
    }
    final topTheme = themeCounts.entries.isEmpty
        ? null
        : (themeCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value))).first;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: [
          Expanded(child: _StatCard(label: 'Stories Created', value: '${stories.length}')),
          const SizedBox(width: 12),
          Expanded(child: _StatCard(label: 'Favorite Theme', value: topTheme?.key ?? '—')),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFe0e6ed)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          Text(label, style: GoogleFonts.nunito(fontSize: 11, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _TabChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label, style: GoogleFonts.nunito(fontWeight: FontWeight.w600, color: selected ? Colors.white : AppColors.primary)),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.primary.withOpacity(0.1),
      side: BorderSide(color: AppColors.primary.withOpacity(0.3)),
    );
  }
}
