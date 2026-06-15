import 'package:ara_dict/play_rate.dart';
import 'package:flutter/material.dart';

class NoResults extends StatelessWidget {
  static const playlistEmpty = Icons.playlist_remove_outlined;
  static const searchEmpty = Icons.search_off;

  const NoResults({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.titleDir,
    this.subtitleDir,
    this.titleFont,
    this.subtitleFont,
  });

  final IconData icon;
  final String title;
  final String? subtitle;

  final TextDirection? titleDir;
  final TextDirection? subtitleDir;
  final String? titleFont;
  final String? subtitleFont;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final th = theme.textTheme;
    final cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          elevatedIcon(cs, icon),

          const SizedBox(height: 12),
          Text(
            title,
            style: th.titleMedium?.copyWith(
              color: cs.primary,
              fontFamily: titleFont,
            ),
            textDirection: titleDir,
            textAlign: TextAlign.center,
            softWrap: true,
          ),

          const SizedBox(height: 2),

          if (subtitle != null)
            Text(
              subtitle!,
              style: th.titleMedium?.copyWith(
                color: cs.secondary,
                fontFamily: subtitleFont,
              ),
              textDirection: subtitleDir,
              textAlign: TextAlign.center,
              softWrap: true,
            ),
        ],
      ),
    );
  }
}
