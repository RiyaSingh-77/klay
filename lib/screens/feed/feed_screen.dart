import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/post_provider.dart';
import '../../providers/user_provider.dart';
import '../../routes/app_routes.dart';
import '../../widgets/feed_post_card.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadFeed());
  }

  Future<void> _loadFeed() async {
    final postProvider = context.read<PostProvider>();
    final userProvider = context.read<UserProvider>();

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
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_border),
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.library),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () =>
            Navigator.pushNamed(context, AppRoutes.createPost),
        child: const Icon(Icons.add),
      ),
      body: Consumer2<PostProvider, UserProvider>(
        builder: (context, postProvider, userProvider, _) {
          if (postProvider.isLoading && postProvider.posts.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (postProvider.errorMessage != null &&
              postProvider.posts.isEmpty) {
            return _ErrorState(
              message: postProvider.errorMessage!,
              onRetry: _loadFeed,
            );
          }

          return RefreshIndicator(
            onRefresh: _loadFeed,
            child: LayoutBuilder(
              builder: (context, constraints) {
                double width;

                if (constraints.maxWidth > 1200) {
                  width = 450;
                } else if (constraints.maxWidth > 800) {
                  width = 500;
                } else {
                  width = constraints.maxWidth;
                }

                return Center(
                  child: SizedBox(
                    width: width,
                    child: ListView.builder(
                      physics:
                          const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                      ),
                      itemCount: postProvider.posts.length,
                      itemBuilder: (context, index) {
                        final post =
                            postProvider.posts[index];

                        return FeedPostCard(
                          post: post,
                          authorName: userProvider.authorName(
                            post.userId,
                          ),
                          onTap: () => Navigator.pushNamed(
                            context,
                            AppRoutes.postDetail,
                            arguments: post.id,
                          ),
                        );
                      },
                    ),
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

  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('RETRY'),
            ),
          ],
        ),
      ),
    );
  }
}