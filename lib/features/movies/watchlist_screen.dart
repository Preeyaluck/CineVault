import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants.dart';
import '../../models/movie_model.dart';
import '../../services/watchlist_service.dart';
import 'movie_provider.dart';

class WatchlistScreen extends ConsumerStatefulWidget {
  const WatchlistScreen({super.key});

  @override
  ConsumerState<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends ConsumerState<WatchlistScreen> {
  final _watchlistService = WatchlistService();
  late Future<List<Movie>> _watchlistFuture;

  @override
  void initState() {
    super.initState();
    _watchlistFuture = _watchlistService.getWatchlistMovies();
  }

  void _refresh() {
    setState(() {
      _watchlistFuture = _watchlistService.getWatchlistMovies();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Watchlist')),
      body: FutureBuilder<List<Movie>>(
        future: _watchlistFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
                child: Text('Failed to load watchlist\n${snapshot.error}'));
          }

          final movies = snapshot.data ?? [];
          if (movies.isEmpty) {
            return const Center(child: Text('No movies in your watchlist yet'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: movies.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final movie = movies[index];

              return Card(
                child: ListTile(
                  onTap: () {
                    ref.read(selectedMovieProvider.notifier).state = movie;
                    context.pushNamed(RouteNames.detail);
                  },
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: movie.posterUrl.isEmpty
                        ? Container(
                            width: 48,
                            height: 72,
                            color: const Color(0xFF151925),
                            child: const Icon(Icons.movie_creation_outlined),
                          )
                        : Image.network(
                            movie.posterUrl,
                            width: 48,
                            height: 72,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 48,
                              height: 72,
                              color: const Color(0xFF151925),
                              child: const Icon(Icons.movie_creation_outlined),
                            ),
                          ),
                  ),
                  title: Text(
                    movie.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text('Rating ${movie.rating.toStringAsFixed(1)}'),
                  trailing: IconButton(
                    tooltip: 'Remove',
                    onPressed: () async {
                      await _watchlistService.removeMovie(movie.id);
                      if (!mounted) return;
                      _refresh();
                    },
                    icon: const Icon(Icons.bookmark_remove_rounded),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
