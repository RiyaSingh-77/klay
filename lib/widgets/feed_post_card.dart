import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/draft.dart';
import '../models/post.dart';
import '../providers/library_provider.dart';
import '../theme/app_theme.dart';

class FeedPostCard extends StatelessWidget {
  final Post post;
  final String authorName;
  final VoidCallback onTap;

  const FeedPostCard({
    super.key,
    required this.post,
    required this.authorName,
    required this.onTap,
  });

  static const List<List<Color>> _heroGradients = [
    [Color(0xFFC8553D), Color(0xFFE8845A)],
    [Color(0xFF5B7FA6), Color(0xFF8BAECF)],
    [Color(0xFF8B7355), Color(0xFFB8977A)],
    [Color(0xFF6B8F71), Color(0xFF9EC4A4)],
    [Color(0xFF8B6B8A), Color(0xFFB99AB8)],
    [Color(0xFF7A6545), Color(0xFFA89068)],
    [Color(0xFF4A7C8B), Color(0xFF7AACBB)],
    [Color(0xFF8B4A6B), Color(0xFFB87A9B)],
    [Color(0xFF5C7A5C), Color(0xFF8CAA8C)],
    [Color(0xFF7B5EA7), Color(0xFFA98EC9)],
  ];

  static const List<String> _categories = [
    'DESIGN',
    'PHOTO',
    'LIFESTYLE',
    'ART',
    'TECH',
    'CRAFT',
    'FOOD',
    'TRAVEL',
    'MUSIC',
    'WRITING',
  ];

  List<Color> get _gradient =>
      _heroGradients[post.userId % _heroGradients.length];

  String get _category =>
      _categories[post.id % _categories.length];

  String get _bodyPreview =>
      post.body.replaceAll('\n', ' ');

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final libraryProvider =
        context.watch<LibraryProvider>();

    final matchingDraft =
        libraryProvider.drafts.firstWhere(
      (d) => d.id == post.id.toString(),
      orElse: () => Draft(
        id: '',
        title: '',
        body: '',
        createdAt: DateTime.now(),
      ),
    );

    final imagePath = matchingDraft.imagePath;
    final isFavorite =
        libraryProvider.isFavorite(post.id);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(
        vertical: 12,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor:
                        AppTheme.primary,
                    child: Text(
                      authorName.isNotEmpty
                          ? authorName[0]
                                .toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      authorName,
                      style: textTheme.bodyLarge
                          ?.copyWith(
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context
                        .read<
                            LibraryProvider>()
                        .toggleFavorite(
                            post.id),
                    child: Icon(
                      isFavorite
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: isFavorite
                          ? AppTheme.primary
                          : AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),

            AspectRatio(
              aspectRatio: 1,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (imagePath != null &&
                      imagePath.isNotEmpty)
                    Image.network(
                      imagePath,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (_, __, ___) =>
                              _GradientHero(
                        colors: _gradient,
                      ),
                    )
                  else
                    _GradientHero(
                      colors: _gradient,
                    ),

                  Positioned(
                    top: 14,
                    right: 14,
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration:
                          BoxDecoration(
                        color: Colors.black54,
                        borderRadius:
                            BorderRadius.circular(
                                20),
                      ),
                      child: Text(
                        _category,
                        style:
                            const TextStyle(
                          color:
                              Colors.white,
                          fontSize: 10,
                          fontWeight:
                              FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding:
                  const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    post.title,
                    maxLines: 2,
                    overflow:
                        TextOverflow.ellipsis,
                    style: textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _bodyPreview,
                    maxLines: 3,
                    overflow:
                        TextOverflow.ellipsis,
                    style: textTheme.bodyMedium
                        ?.copyWith(
                      color:
                          AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GradientHero extends StatelessWidget {
  final List<Color> colors;

  const _GradientHero({
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }
}