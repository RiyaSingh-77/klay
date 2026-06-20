import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/post_provider.dart';
import '../../providers/user_provider.dart';
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
                PostDetailAuthorRow(authorName: authorName),
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