import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/album_provider.dart';
import '../../widgets/photo_grid_tile.dart';

// AlbumPhotosScreen receives an albumId via Navigator arguments and shows
// every photo in that album as a grid, using AlbumProvider's "Level 2"
// fetch (fetchPhotosByAlbum) — see album_provider.dart for why albums and
// photos share one provider instead of being split in two.
class AlbumPhotosScreen extends StatefulWidget {
  final int albumId;
  const AlbumPhotosScreen({super.key, required this.albumId});

  @override
  State<AlbumPhotosScreen> createState() => _AlbumPhotosScreenState();
}

class _AlbumPhotosScreenState extends State<AlbumPhotosScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    await context.read<AlbumProvider>().fetchPhotosByAlbum(widget.albumId);
  }

  void _openFullPhoto(BuildContext context, String url, String title) {
    // A lightweight in-place viewer rather than a named route — there's
    // no separate state to manage here (no provider, no arguments beyond
    // what's already on screen), so a plain MaterialPageRoute is enough.
    // If a "save photo" or "share" feature gets added later, this is the
    // natural point to promote it to a real named route.
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: Text(title)),
          backgroundColor: Colors.black,
          body: Center(
            child: InteractiveViewer(
              child: Image.network(url),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Album')),
      body: Consumer<AlbumProvider>(
        builder: (context, albumProvider, _) {
          if (albumProvider.isLoadingPhotos) {
            return const Center(child: CircularProgressIndicator());
          }

          if (albumProvider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(albumProvider.errorMessage!),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: _load, child: const Text('RETRY')),
                ],
              ),
            );
          }

          if (albumProvider.photos.isEmpty) {
            return Center(
              child: Text('No photos in this album.', style: textTheme.bodyMedium),
            );
          }

          return RefreshIndicator(
            onRefresh: _load,
            child: GridView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: albumProvider.photos.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemBuilder: (context, index) {
                final photo = albumProvider.photos[index];
                return PhotoGridTile(
                  photo: photo,
                  onTap: () => _openFullPhoto(context, photo.url, photo.title),
                );
              },
            ),
          );
        },
      ),
    );
  }
}