import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/album_provider.dart';
import '../../providers/user_provider.dart';
import '../../routes/app_routes.dart';
import '../../widgets/album_grid_title.dart';
import '../../widgets/author_header.dart';


// AuthorProfileScreen receives a userId via Navigator arguments (see
// route_generator.dart). It fetches two independent things on open: the
// user's profile details (UserProvider) and their list of albums
// (AlbumProvider) — same "run concurrently, no dependency between them"
// pattern as FeedScreen's Future.wait in Phase 7.
class AuthorProfileScreen extends StatefulWidget {
  final int userId;
  const AuthorProfileScreen({super.key, required this.userId});

  @override
  State<AuthorProfileScreen> createState() => _AuthorProfileScreenState();
}

class _AuthorProfileScreenState extends State<AuthorProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final userProvider = context.read<UserProvider>();
    final albumProvider = context.read<AlbumProvider>();
    await Future.wait([
      userProvider.fetchUser(widget.userId),
      albumProvider.fetchAlbumsByUser(widget.userId),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Consumer2<UserProvider, AlbumProvider>(
        builder: (context, userProvider, albumProvider, _) {
          // selectedUser carries this screen's own fetch — separate from
          // UserProvider's authorName() cache from Phase 7, which only
          // ever holds names, not full profiles.
          final user = userProvider.selectedUser;

          if (userProvider.isLoading && user == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (userProvider.errorMessage != null && user == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(userProvider.errorMessage!),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: _load, child: const Text('RETRY')),
                ],
              ),
            );
          }

          if (user == null) {
            return const Center(child: Text('Author not found.'));
          }

          return RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              children: [
                AuthorHeader(user: user),
                const SizedBox(height: 28),
                Text('ALBUMS', style: textTheme.bodyMedium),
                const SizedBox(height: 12),

                if (albumProvider.isLoadingAlbums)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (albumProvider.errorMessage != null)
                  Text(
                    albumProvider.errorMessage!,
                    style: textTheme.bodyMedium?.copyWith(color: Colors.black45),
                  )
                else if (albumProvider.albums.isEmpty)
                  Text(
                    'No albums yet.',
                    style: textTheme.bodyMedium?.copyWith(color: Colors.black45),
                  )
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: albumProvider.albums.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      // A fixed height (mainAxisExtent) instead of
                      // childAspectRatio — aspect ratio is computed from
                      // the cell's WIDTH, which varies a lot between a
                      // phone, a resized browser window, and a desktop
                      // build. A fixed 140px tile stays predictable
                      // everywhere, so the title never gets pushed out
                      // of view the way it was with ratio-based sizing.
                      mainAxisExtent: 140,
                    ),
                    itemBuilder: (context, index) {
                      final album = albumProvider.albums[index];
                      return AlbumGridTitle(
                        album: album,
                        onTap: () => Navigator.pushNamed(
                          context,
                          AppRoutes.albumPhotos,
                          arguments: album.id,
                        ),
                      );
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}