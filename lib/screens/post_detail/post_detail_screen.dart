import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/draft.dart';
import '../../providers/post_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/library_provider.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';
import '../../utils/file_opener.dart';
import '../../widgets/post_detail_author_row.dart';

// PostDetailScreen receives a postId via Navigator arguments (see
// route_generator.dart) and shows the full post body plus its comments.
// It fetches fresh every time it opens, via PostProvider.fetchPostDetail
// — the feed only ever holds previews, so a real visit to a post's page
// needs its own network round trip, same as tapping into any article.
class PostDetailScreen extends StatefulWidget {
  final int postId;
  const PostDetailScreen({super.key, required this.postId});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    await context.read<PostProvider>().fetchPostDetail(widget.postId);
  }

  // attachmentPath now holds different things depending on platform:
  // - on web, it's a blob: URL (built in CreatePostScreen at pick-time),
  //   so we just open it directly the way a normal link would open.
  // - on mobile, it's a real filesystem path, so we hand it to
  //   url_launcher as a file:// URI and let the OS pick a viewer app —
  //   the same way tapping a downloaded PDF in any app would.
  // Either way, this method is the single place that knows the
  // difference; nothing else in the widget tree needs to care.
  Future<void> _openAttachment(String? attachmentPath, String? attachmentName) async {
    if (attachmentPath == null || attachmentPath.isEmpty) return;

    if (kIsWeb) {
      openWebUrl(attachmentPath, attachmentName);
      return;
    }

    final uri = Uri.file(attachmentPath);
    final opened = await canLaunchUrl(uri) && await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No app found to open this file.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Post'),
        actions: [
          Consumer<PostProvider>(
            builder: (context, postProvider, _) {
              final post = postProvider.selectedPost;
              if (post == null) return const SizedBox.shrink();
              // Reading isFavorite here via context.watch (not read) so
              // the icon flips instantly on tap — toggleFavorite() calls
              // notifyListeners() before it persists to disk, so the UI
              // never waits on SharedPreferences to feel responsive.
              final isFavorite = context.watch<LibraryProvider>().isFavorite(post.id);
              return IconButton(
                icon: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite ? AppTheme.primary : null,
                ),
                onPressed: () => context.read<LibraryProvider>().toggleFavorite(post.id),
              );
            },
          ),
        ],
      ),
      body: Consumer<PostProvider>(
        builder: (context, postProvider, _) {
          if (postProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (postProvider.errorMessage != null || postProvider.selectedPost == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(postProvider.errorMessage ?? 'Post not found.'),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: _load, child: const Text('RETRY')),
                ],
              ),
            );
          }

          final post = postProvider.selectedPost!;
          final comments = postProvider.comments;

          // The picked image and attachment (Create Post, Phase 9) were
          // never sent to JSONPlaceholder — it has no field for either —
          // so they were saved locally as a Draft keyed by this same
          // post's id. We look that draft up here purely to grab its
          // imagePath / attachmentPath / attachmentName; we don't care
          // about title/body on the draft itself, the Post already has
          // those as the source of truth.
          final matchingDraft = context.watch<LibraryProvider>().drafts.firstWhere(
                (d) => d.id == post.id.toString(),
                orElse: () => Draft(
                  id: '',
                  title: '',
                  body: '',
                  createdAt: DateTime.now(),
                ),
              );
          final imagePath = matchingDraft.imagePath;
          final attachmentPath = matchingDraft.attachmentPath;
          final attachmentName = matchingDraft.attachmentName;

          // userProvider.authorName() reads the same id -> name cache
          // FeedScreen filled on launch — no extra fetch needed here as
          // long as the cache has loaded at least once this session.
          final authorName = context.watch<UserProvider>().authorName(post.userId);

          return RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              children: [
                if (imagePath != null && imagePath.isNotEmpty) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      height: 220,
                      width: double.infinity,
                      color: AppTheme.surface,
                      child: Image.network(
                        imagePath,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => const Center(
                          child: Icon(Icons.broken_image_outlined, color: Colors.black38),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                if (attachmentName != null && attachmentName.isNotEmpty) ...[
                  Material(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => _openAttachment(attachmentPath, attachmentName),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        child: Row(
                          children: [
                            const Icon(Icons.insert_drive_file_outlined, color: AppTheme.primary, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                attachmentName,
                                overflow: TextOverflow.ellipsis,
                                style: textTheme.bodyMedium,
                              ),
                            ),
                            const Icon(Icons.open_in_new, color: Colors.black38, size: 18),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                PostDetailAuthorRow(
                  authorName: authorName,
                  onViewProfile: () => Navigator.pushNamed(
                    context,
                    AppRoutes.authorProfile,
                    arguments: post.userId,
                  ),
                ),
                const SizedBox(height: 16),
                Text(post.title, style: textTheme.headlineSmall),
                const SizedBox(height: 12),
                Text(post.body, style: textTheme.bodyLarge),
                const SizedBox(height: 28),
                Text('COMMENTS (${comments.length})', style: textTheme.bodyMedium),
                const SizedBox(height: 12),
                if (comments.isEmpty)
                  Text(
                    'No comments yet.',
                    style: textTheme.bodyMedium?.copyWith(color: Colors.black45),
                  )
                else
                  ...comments.map((c) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(c.name, style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Text(c.body, style: textTheme.bodyMedium),
                          ],
                        ),
                      )),
              ],
            ),
          );
        },
      ),
    );
  }
}