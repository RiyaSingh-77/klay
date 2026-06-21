import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/post_provider.dart';
import '../../providers/user_provider.dart';
import '../../routes/app_routes.dart';
import '../../widgets/feed_post_card.dart';

// FeedScreen is the app's home screen — a scrollable list of every post
// from JSONPlaceholder. It owns no fetching logic itself; it just tells
// PostProvider and UserProvider WHEN to fetch (on first frame, and again
// on pull-to-refresh) and renders whatever state they're currently in.
class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  @override
  void initState() {
    super.initState();
    // addPostFrameCallback, same pattern as SplashScreen — calling
    // context.read() inside initState() directly is fine too, but doing
    // it post-frame keeps the first build pass free of side effects.
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadFeed());
  }

  Future<void> _loadFeed() async {
    final postProvider = context.read<PostProvider>();
    final userProvider = context.read<UserProvider>();
    // Run both requests concurrently — there's no dependency between
    // "fetch all posts" and "fetch all users," so awaiting them one at a
    // time would only make the user wait longer for no reason.
    await Future.wait([
      postProvider.fetchPosts(),
      userProvider.fetchAllUsers(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Klay'),
        centerTitle: false,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, AppRoutes.createPost),
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Consumer2<PostProvider, UserProvider>(
        builder: (context, postProvider, userProvider, _) {
          if (postProvider.isLoading && postProvider.posts.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (postProvider.errorMessage != null && postProvider.posts.isEmpty) {
            return _ErrorState(
              message: postProvider.errorMessage!,
              onRetry: _loadFeed,
            );
          }

          return RefreshIndicator(
            onRefresh: _loadFeed,
            child: ListView.builder(
              // Even when the list is short, physics stays scrollable so
              // pull-to-refresh always works — AlwaysScrollableScrollPhysics
              // is the standard fix for "RefreshIndicator doesn't trigger
              // on a list that fits on one screen."
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemCount: postProvider.posts.length,
              itemBuilder: (context, index) {
                final post = postProvider.posts[index];
                return FeedPostCard(
                  post: post,
                  authorName: userProvider.authorName(post.userId),
                  onTap: () => Navigator.pushNamed(
                    context,
                    AppRoutes.postDetail,
                    arguments: post.id,
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: const Text('RETRY')),
          ],
        ),
      ),
    );
  }
}