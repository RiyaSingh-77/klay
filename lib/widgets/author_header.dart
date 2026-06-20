import 'package:flutter/material.dart';
import '../models/user.dart';
import '../theme/app_theme.dart';

// AuthorHeader is the top block of AuthorProfileScreen: a big avatar,
// name + @username, a "bio" line (JSONPlaceholder has no real bio field,
// so company.catchPhrase stands in for one — it reads like a tagline),
// and a short list of contact details. Pure display widget — handed a
// User and nothing else, no provider access here.
class AuthorHeader extends StatelessWidget {
  final User user;

  const AuthorHeader({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: AppTheme.primary,
              child: Text(
                user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 28,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.name, style: textTheme.headlineSmall),
                  const SizedBox(height: 2),
                  Text(
                    '@${user.username}',
                    style: textTheme.bodyMedium?.copyWith(color: AppTheme.primary),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // company.catchPhrase reads like a tagline ("Multi-layered client-
        // server neural-net" etc.) — it's the closest thing JSONPlaceholder
        // has to a user bio, so it's repurposed here rather than left unused.
        if (user.company.catchPhrase.isNotEmpty) ...[
          Text(
            user.company.catchPhrase,
            style: textTheme.bodyLarge?.copyWith(
              fontStyle: FontStyle.italic,
              color: AppTheme.textDark.withValues(alpha: 0.75),
            ),
          ),
          const SizedBox(height: 16),
        ],

        _ContactRow(icon: Icons.mail_outline, text: user.email),
        _ContactRow(icon: Icons.phone_outlined, text: user.phone),
        _ContactRow(icon: Icons.language, text: user.website),
        _ContactRow(icon: Icons.location_on_outlined, text: user.address.city),
      ],
    );
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _ContactRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox.shrink();
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: textTheme.bodyMedium, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}