import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/draft.dart';
import '../../providers/library_provider.dart';
import '../../providers/post_provider.dart';
import '../../providers/user_provider.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';
import '../../widgets/feed_post_card.dart';

// LibraryScreen has two tabs that are deliberately very different in how
// they get their data:
//  - Favorites holds only POST IDS (List<int>), so this screen looks
//    those ids up against PostProvider's already-fetched _posts list —
//    no new network call, since the Feed already paid that cost.
//  - Drafts holds full local Draft objects already (LibraryProvider has
//    everything it needs), so that tab needs no other provider at all.
class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Favorites needs PostProvider.posts to already be loaded to resolve
    // ids -> full Post objects. Normally Feed has already done this by
    // the time someone reaches Library, but this covers the edge case of
    // a deep link or hot-restart landing here first.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final postProvider = context.read<PostProvider>();
      if (postProvider.posts.isEmpty) postProvider.fetchPosts();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Library'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primary,
          unselectedLabelColor: Colors.black54,
          indicatorColor: AppTheme.primary,
          tabs: const [
            Tab(text: 'FAVORITES'),
            Tab(text: 'DRAFTS'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _FavoritesTab(),
          _DraftsTab(),
        ],
      ),
    );
  }
}

class _FavoritesTab extends StatelessWidget {
  const _FavoritesTab();

  @override
  Widget build(BuildContext context) {
    return Consumer3<LibraryProvider, PostProvider, UserProvider>(
      builder: (context, libraryProvider, postProvider, userProvider, _) {
        if (postProvider.isLoading && postProvider.posts.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        // Resolve favorite ids -> full Post objects from PostProvider's
        // list. where() instead of firstWhere() per id keeps this safe
        // even if a favorited post's id somehow isn't in _posts (e.g.
        // it was a locally-created post that hasn't loaded into _posts
        // yet after a hot restart) — it just gets skipped instead of
        // throwing.
        final favoritePosts = libraryProvider.favoriteIds
            .map((id) => postProvider.posts.where((p) => p.id == id))
            .where((matches) => matches.isNotEmpty)
            .map((matches) => matches.first)
            .toList();

        if (favoritePosts.isEmpty) {
          return const _EmptyState(
            icon: Icons.favorite_border,
            message: 'No favorites yet.\nTap the heart on any post to save it here.',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 12),
          itemCount: favoritePosts.length,
          itemBuilder: (context, index) {
            final post = favoritePosts[index];
            // Swipe-to-remove rather than a separate button — the heart
            // icon on Post Detail is the "add," this is the natural
            // mirror for "remove," without cluttering FeedPostCard with
            // an extra trailing icon it doesn't need anywhere else.
            return Dismissible(
              key: ValueKey('favorite-${post.id}'),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.red.shade300,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.delete_outline, color: Colors.white),
              ),
              onDismissed: (_) => libraryProvider.toggleFavorite(post.id),
              child: FeedPostCard(
                post: post,
                authorName: userProvider.authorName(post.userId),
                onTap: () => Navigator.pushNamed(
                  context,
                  AppRoutes.postDetail,
                  arguments: post.id,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _DraftsTab extends StatelessWidget {
  const _DraftsTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<LibraryProvider>(
      builder: (context, libraryProvider, _) {
        final drafts = libraryProvider.drafts;

        if (drafts.isEmpty) {
          return const _EmptyState(
            icon: Icons.drafts_outlined,
            message: 'No drafts yet.\nImages and attachments from Create Post show up here.',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: drafts.length,
          itemBuilder: (context, index) => _DraftCard(draft: drafts[index]),
        );
      },
    );
  }
}

class _DraftCard extends StatelessWidget {
  final Draft draft;
  const _DraftCard({required this.draft});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final hasImage = draft.imagePath != null && draft.imagePath!.isNotEmpty;
    final hasAttachment = draft.attachmentName != null && draft.attachmentName!.isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        // draft.id was set to match the SERVER post's id at creation time
        // (see CreatePostScreen._submit), so tapping a draft can jump
        // straight to that post's detail page — same number, two
        // different stores (Draft locally, Post on JSONPlaceholder)
        // describing the same thing.
        onTap: () {
          final postId = int.tryParse(draft.id);
          if (postId != null) {
            Navigator.pushNamed(context, AppRoutes.postDetail, arguments: postId);
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      draft.title,
                      style: textTheme.titleLarge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    onPressed: () => context.read<LibraryProvider>().deleteDraft(draft.id),
                  ),
                ],
              ),
              Text(
                draft.body,
                style: textTheme.bodyMedium?.copyWith(color: Colors.black54),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (hasImage) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 140,
                    width: double.infinity,
                    color: AppTheme.surface,
                    child: Image.network(
                      draft.imagePath!,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Center(
                        child: Icon(Icons.broken_image_outlined, color: Colors.black38),
                      ),
                    ),
                  ),
                ),
              ],
              if (hasAttachment) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.insert_drive_file_outlined, size: 18, color: AppTheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        draft.attachmentName!,
                        style: textTheme.bodyMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: Colors.black26),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black45),
            ),
          ],
        ),
      ),
    );
  }
}