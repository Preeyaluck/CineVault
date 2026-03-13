import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants.dart';
import '../../services/api_service.dart';
import '../../models/movie_model.dart';
import 'movie_provider.dart';

class RandomResultScreen extends ConsumerStatefulWidget {
  const RandomResultScreen({super.key});

  @override
  ConsumerState<RandomResultScreen> createState() => _RandomResultScreenState();
}

class _RandomResultScreenState extends ConsumerState<RandomResultScreen> {
  late final Future<List<Movie>> _moviesFuture;
  List<Movie> _movies = const [];
  Movie? _currentMovie;

  @override
  void initState() {
    super.initState();
    _moviesFuture = ApiService().fetchMovies(AppConstants.popularMovies);
  }

  Movie _pickRandomMovie(List<Movie> movies, {int? avoidId}) {
    if (movies.length <= 1) return movies.first;

    Movie candidate = movies[Random().nextInt(movies.length)];
    while (candidate.id == avoidId) {
      candidate = movies[Random().nextInt(movies.length)];
    }
    return candidate;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your Lucky Movie')),
      body: FutureBuilder<List<Movie>>(
        // ดึงหนังยอดนิยมมาเพื่อสุ่ม 1 เรื่องจากในนั้น
        future: _moviesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError ||
              !snapshot.hasData ||
              snapshot.data!.isEmpty) {
            return const Center(child: Text('Error finding a movie'));
          }

          if (_movies.isEmpty) {
            _movies = snapshot.data!;
            _currentMovie = _pickRandomMovie(_movies);
          }

          final randomMovie = _currentMovie!;

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () {
                    ref.read(selectedMovieProvider.notifier).state =
                        randomMovie;
                    context.pushNamed(RouteNames.detail);
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: randomMovie.posterUrl.isEmpty
                        ? Container(
                            height: 400,
                            width: 270,
                            color: const Color(0xFF151925),
                            child: const Icon(
                              Icons.movie_creation_outlined,
                              size: 48,
                            ),
                          )
                        : Image.network(
                            randomMovie.posterUrl,
                            height: 400,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                              height: 400,
                              width: 270,
                              color: const Color(0xFF151925),
                              child: const Icon(
                                Icons.movie_creation_outlined,
                                size: 48,
                              ),
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Tap poster to view details',
                  style: TextStyle(fontSize: 12, color: Colors.white70),
                ),
                const SizedBox(height: 20),
                Text(
                  randomMovie.title,
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    randomMovie.summary,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 30),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _currentMovie = _pickRandomMovie(
                        _movies,
                        avoidId: _currentMovie?.id,
                      );
                    });
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try Again'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
