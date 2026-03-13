import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'movie_provider.dart';

class MovieDetailScreen extends ConsumerWidget {
  const MovieDetailScreen({super.key});

  String _formatDate(String rawDate) {
    if (rawDate.isEmpty) return 'N/A';
    final parts = rawDate.split('-');
    if (parts.length != 3) return rawDate;
    return '${parts[2]}/${parts[1]}/${parts[0]}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final movie = ref.watch(selectedMovieProvider);

    if (movie == null) {
      return const Scaffold(body: Center(child: Text('No Movie Selected')));
    }

    final screenWidth = MediaQuery.sizeOf(context).width;
    final maxContentWidth = screenWidth > 900 ? 900.0 : screenWidth;
    final posterHeight = screenWidth > 900 ? 520.0 : screenWidth * 1.2;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: posterHeight,
            pinned: true,
            stretch: true,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsetsDirectional.only(
                start: 16,
                bottom: 14,
                end: 16,
              ),
              title: Text(
                movie.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  movie.posterUrl.isEmpty
                      ? const ColoredBox(
                          color: Color(0xFF161A24),
                          child: Center(
                            child:
                                Icon(Icons.movie_creation_outlined, size: 40),
                          ),
                        )
                      : Image.network(
                          movie.posterUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const ColoredBox(
                            color: Color(0xFF161A24),
                            child: Center(
                              child: Icon(Icons.broken_image, size: 40),
                            ),
                          ),
                        ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0x10000000),
                          Color(0x88000000),
                          Color(0xDD000000),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxContentWidth),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _InfoChip(
                            icon: Icons.star_rounded,
                            label: 'Rating ${movie.rating.toStringAsFixed(1)}',
                          ),
                          _InfoChip(
                            icon: Icons.calendar_month_rounded,
                            label: _formatDate(movie.releaseDate),
                          ),
                          _InfoChip(
                            icon: Icons.language_rounded,
                            label: movie.language.toUpperCase(),
                          ),
                          _InfoChip(
                            icon: Icons.how_to_vote_rounded,
                            label: '${movie.voteCount} votes',
                          ),
                          _InfoChip(
                            icon: Icons.trending_up_rounded,
                            label: 'Pop ${movie.popularity.toStringAsFixed(1)}',
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      Text(
                        'Overview',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        movie.summary.isEmpty
                            ? 'No overview available for this movie.'
                            : movie.summary,
                        style: const TextStyle(height: 1.55, fontSize: 16),
                      ),
                      const SizedBox(height: 28),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: Colors.white.withAlpha(10),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline_rounded, size: 18),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Tip: Tap back to discover more movies from Seasonal Favorites.',
                                style: TextStyle(fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: Colors.amber[300]),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
