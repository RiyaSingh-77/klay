import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/draft.dart';
import '../../providers/post_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/library_provider.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';
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

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Post')),
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
          // imagePath / attachmentName; we don't care about title/body
          // on the draft itself, the Post already has those as the
          // source of truth.
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
                      // Image.network works here even though imagePath is
                      // a blob: URL (Flutter Web's object URL for a
                      // locally-picked file), not a real http(s) address —
                      // the browser resolves blob: URLs the same way it
                      // resolves any other image src, as long as we're
                      // still in the same tab/session that created it.
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
                // Attachment chip — same visual pattern CreatePostScreen
                // uses for _pickedAttachment. We only ever have the name
                // to show: on web, CreatePostScreen deliberately never
                // saves attachmentPath (PlatformFile.path throws on web,
                // see the comment there), so there's no file to open or
                // preview here, just the filename as a record that
                // something was attached.
                if (attachmentName != null && attachmentName.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(14),
                    ),
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
                      ],
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