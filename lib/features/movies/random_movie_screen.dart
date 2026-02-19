import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants.dart';

class RandomMovieScreen extends StatelessWidget {
  const RandomMovieScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Random Discovery')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.casino, size: 100, color: Colors.orange),
            const SizedBox(height: 20),
            const Text('Don\'t know what to watch?'),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(20)),
              onPressed: () => context.pushNamed(RouteNames.randomResult),
              child: const Text('Tap to Discover!'),
            ),
          ],
        ),
      ),
    );
  }
}