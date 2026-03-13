import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../services/api_service.dart';
import '../../services/favorites_service.dart';
import '../../services/watchlist_service.dart';
import '../../models/movie_model.dart';
import '../../core/constants.dart';
import 'movie_provider.dart';

class SeasonalHomeScreen extends ConsumerStatefulWidget {
  const SeasonalHomeScreen({super.key});

  @override
  ConsumerState<SeasonalHomeScreen> createState() => _SeasonalHomeScreenState();
}

class _SeasonalHomeScreenState extends ConsumerState<SeasonalHomeScreen> {
  final _searchController = TextEditingController();
  final _api = ApiService();
  final _favoritesService = FavoritesService();
  final _watchlistService = WatchlistService();
  final Set<int> _heartBurstMovieIds = <int>{};
  final Set<int> _watchlistMovieIds = <int>{};
  Timer? _debounce;
  late Future<List<Movie>> _moviesFuture;

  void _triggerHeartBurst(int movieId) {
    setState(() => _heartBurstMovieIds.add(movieId));
    Future<void>.delayed(const Duration(milliseconds: 650), () {
      if (!mounted) return;
      setState(() => _heartBurstMovieIds.remove(movieId));
    });
  }

  Future<void> _addToFavorites(Movie movie) async {
    try {
      _triggerHeartBurst(movie.id);
      await _favoritesService.addMovie(movie);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Added "${movie.title}" to favorites')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add favorite: $e')),
      );
    }
  }

  Future<void> _toggleWatchlist(Movie movie) async {
    final isSaved = _watchlistMovieIds.contains(movie.id);
    try {
      if (isSaved) {
        await _watchlistService.removeMovie(movie.id);
        if (!mounted) return;
        setState(() => _watchlistMovieIds.remove(movie.id));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Removed "${movie.title}" from watchlist')),
        );
        return;
      }

      await _watchlistService.addMovie(movie);
      if (!mounted) return;
      setState(() => _watchlistMovieIds.add(movie.id));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Added "${movie.title}" to watchlist')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add: $e')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _moviesFuture = _api.fetchMovies(AppConstants.popularMovies);
    _loadWatchlistIds();
  }

  Future<void> _loadWatchlistIds() async {
    try {
      final ids = await _watchlistService.getWatchlistMovieIds();
      if (!mounted) return;
      setState(() {
        _watchlistMovieIds
          ..clear()
          ..addAll(ids);
      });
    } catch (_) {
      // Keep default empty state if watchlist cannot be loaded.
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;

      setState(() {
        if (value.trim().isEmpty) {
          _moviesFuture = _api.fetchMovies(AppConstants.popularMovies);
        } else {
          _moviesFuture = _api.searchMovies(value);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CineVault'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(70),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search movies from TMDB...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                          setState(() {});
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
                filled: true,
                fillColor: Colors.white.withAlpha(12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
      body: FutureBuilder<List<Movie>>(
        future: _moviesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Search failed. Please check internet and try again.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final movies = snapshot.data ?? [];
          if (movies.isEmpty) {
            return const Center(child: Text('No movies found'));
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final crossAxisCount = width >= 1200
                  ? 6
                  : width >= 900
                      ? 5
                      : width >= 700
                          ? 4
                          : width >= 520
                              ? 3
                              : 2;

              return GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.68,
                ),
                itemCount: movies.length,
                itemBuilder: (context, index) {
                  final movie = movies[index];
                  final isSaved = _watchlistMovieIds.contains(movie.id);

                  return InkWell(
                    onTap: () {
                      ref.read(selectedMovieProvider.notifier).state = movie;
                      context.pushNamed(RouteNames.detail);
                    },
                    onDoubleTap: () => _addToFavorites(movie),
                    borderRadius: BorderRadius.circular(14),
                    child: Card(
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          movie.posterUrl.isEmpty
                              ? const ColoredBox(
                                  color: Color(0xFF151925),
                                  child: Icon(Icons.movie_creation_outlined),
                                )
                              : Image.network(
                                  movie.posterUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const ColoredBox(
                                    color: Color(0xFF151925),
                                    child: Icon(
                                      Icons.movie_creation_outlined,
                                    ),
                                  ),
                                ),
                          const DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Color(0x55000000),
                                  Color(0xB0000000),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withAlpha(130),
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                visualDensity: VisualDensity.compact,
                                iconSize: 18,
                                tooltip: isSaved
                                    ? 'Remove from watchlist'
                                    : 'Add to watchlist',
                                onPressed: () => _toggleWatchlist(movie),
                                icon: Icon(
                                  isSaved
                                      ? Icons.check_circle_rounded
                                      : Icons.bookmark_add_rounded,
                                  color: isSaved
                                      ? const Color(0xFF43D17A)
                                      : Colors.white,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            left: 10,
                            right: 10,
                            bottom: 10,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  movie.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.star_rounded,
                                      size: 14,
                                      color: Colors.amber,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      movie.rating.toStringAsFixed(1),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          IgnorePointer(
                            child: Center(
                              child: AnimatedScale(
                                scale: _heartBurstMovieIds.contains(movie.id)
                                    ? 1.0
                                    : 0.2,
                                duration: const Duration(milliseconds: 180),
                                curve: Curves.easeOutBack,
                                child: AnimatedOpacity(
                                  opacity:
                                      _heartBurstMovieIds.contains(movie.id)
                                          ? 1
                                          : 0,
                                  duration: const Duration(milliseconds: 220),
                                  child: const Icon(
                                    Icons.favorite_rounded,
                                    size: 74,
                                    color: Color(0xFFFF4D6D),
                                    shadows: [
                                      Shadow(
                                        color: Color(0xAAFF4D6D),
                                        blurRadius: 16,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
