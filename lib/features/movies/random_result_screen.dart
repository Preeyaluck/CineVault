import 'dart:math';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/movie_model.dart';
import '../../core/constants.dart';

class RandomResultScreen extends StatelessWidget {
  const RandomResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your Lucky Movie')),
      body: FutureBuilder<List<Movie>>(
        // ดึงหนังยอดนิยมมาเพื่อสุ่ม 1 เรื่องจากในนั้น
        future: ApiService().fetchMovies(AppConstants.popularMovies),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError ||
              !snapshot.hasData ||
              snapshot.data!.isEmpty) {
            return const Center(child: Text('Error finding a movie'));
          }

          // อัลกอริทึมสุ่ม: เลือก Index แบบสุ่มจาก List ที่ได้มา
          final movies = snapshot.data!;
          final randomMovie = movies[Random().nextInt(movies.length)];

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.network(
                    randomMovie.posterUrl,
                    height: 400,
                    fit: BoxFit.cover,
                  ),
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
                  onPressed: () =>
                      Navigator.pop(context), // กดย้อนกลับไปสุ่มใหม่
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
