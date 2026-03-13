import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants.dart';
import '../../models/movie_model.dart';
import '../../services/favorites_service.dart';
import 'movie_provider.dart';

class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen> {
  final _favoritesService = FavoritesService();
  late Future<List<Movie>> _favoritesFuture;

  @override
  void initState() {
    super.initState();
    _favoritesFuture = _favoritesService.getFavoritesMovies();
  }

  void _refresh() {
    setState(() {
      _favoritesFuture = _favoritesService.getFavoritesMovies();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Favorites')),
      body: FutureBuilder<List<Movie>>(
        future: _favoritesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Failed to load favorites\n${snapshot.error}'),
            );
          }

          final movies = snapshot.data ?? [];
          if (movies.isEmpty) {
            return const Center(child: Text('No favorite movies yet'));
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
                      await _favoritesService.removeMovie(movie.id);
                      if (!mounted) return;
                      _refresh();
                    },
                    icon: const Icon(Icons.remove_circle_outline_rounded),
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
