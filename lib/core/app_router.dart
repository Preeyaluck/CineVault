import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/login_screen.dart';
import '../features/movies/seasonal_home_screen.dart';
import '../features/movies/random_movie_screen.dart';
import '../features/movies/random_result_screen.dart';
import 'constants.dart';

final appRouter = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/login',
      name: RouteNames.login,
      builder: (context, state) => const LoginScreen(),
    ),
    ShellRoute(
      builder: (context, state, child) => MainScaffold(child: child),
      routes: [
        GoRoute(
          path: '/home',
          name: RouteNames.home,
          builder: (context, state) => const SeasonalHomeScreen(),
        ),
        GoRoute(
          path: '/random',
          name: RouteNames.random,
          builder: (context, state) => const RandomMovieScreen(),
        ),
        GoRoute(
          path: '/random-result',
          name: RouteNames
              .randomResult, // ต้องชื่อเดียวกับที่เรียกในหน้า RandomMovieScreen
          builder: (context, state) =>
              const RandomResultScreen(), // ใส่ชื่อ Class หน้าผลลัพธ์ของคุณ
        ),
      ],
    ),
  ],
);

class MainScaffold extends StatelessWidget {
  final Widget child;
  const MainScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        onTap: (index) {
          if (index == 0) context.goNamed(RouteNames.home);
          if (index == 1) context.goNamed(RouteNames.random);
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.shuffle), label: 'Random'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
