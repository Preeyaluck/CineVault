import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/movie_model.dart';

class WatchlistService {
  final SupabaseClient _client = Supabase.instance.client;
  static final StreamController<void> _changesController =
      StreamController<void>.broadcast();

  static Stream<void> get changes => _changesController.stream;

  Future<void> addMovie(Movie movie) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('Please login first');
    }

    await _client.from('watchlist_items').upsert(
      {
        'user_id': user.id,
        'movie_id': movie.id,
        'title': movie.title,
        'summary': movie.summary,
        'poster_url': movie.posterUrl,
        'rating': movie.rating,
        'release_date': movie.releaseDate,
        'language': movie.language,
        'vote_count': movie.voteCount,
        'popularity': movie.popularity,
      },
      onConflict: 'user_id,movie_id',
    );

    await _syncWatchlistCount(user.id);
    _changesController.add(null);
  }

  Future<void> removeMovie(int movieId) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('Please login first');
    }

    await _client
        .from('watchlist_items')
        .delete()
        .eq('user_id', user.id)
        .eq('movie_id', movieId);

    await _syncWatchlistCount(user.id);
    _changesController.add(null);
  }

  Future<Set<int>> getWatchlistMovieIds() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('Please login first');
    }

    final rows = await _client
        .from('watchlist_items')
        .select('movie_id')
        .eq('user_id', user.id);

    return (rows as List)
        .map((row) => ((row['movie_id'] ?? 0) as num).toInt())
        .toSet();
  }

  Future<List<Movie>> getWatchlistMovies() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('Please login first');
    }

    final rows = await _client
        .from('watchlist_items')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    return (rows as List)
        .map(
          (row) => Movie(
            id: (row['movie_id'] ?? 0) as int,
            title: (row['title'] ?? 'No Title').toString(),
            summary: (row['summary'] ?? '').toString(),
            posterUrl: (row['poster_url'] ?? '').toString(),
            rating: ((row['rating'] ?? 0.0) as num).toDouble(),
            releaseDate: (row['release_date'] ?? '').toString(),
            language: (row['language'] ?? 'en-US').toString(),
            voteCount: ((row['vote_count'] ?? 0) as num).toInt(),
            popularity: ((row['popularity'] ?? 0.0) as num).toDouble(),
          ),
        )
        .toList();
  }

  Future<void> _syncWatchlistCount(String userId) async {
    try {
      final rows = await _client
          .from('watchlist_items')
          .select('movie_id')
          .eq('user_id', userId);

      await _client.from('profiles').update({
        'watchlist_count': (rows as List).length,
      }).eq('id', userId);
    } catch (_) {
      // Do not block user flow if profile sync fails.
    }
  }
}
