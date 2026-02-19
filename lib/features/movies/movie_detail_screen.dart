import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'movie_provider.dart';

class MovieDetailScreen extends ConsumerWidget {
  const MovieDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final movie = ref.watch(selectedMovieProvider);

    if (movie == null)
      return const Scaffold(body: Center(child: Text('No Movie Selected')));

    return Scaffold(
      appBar: AppBar(title: Text(movie.title)),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Image.network(movie.posterUrl,
                width: double.infinity, fit: BoxFit.cover),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(movie.summary, style: const TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
