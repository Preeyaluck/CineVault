import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../features/auth/login_screen.dart';
import '../features/movies/seasonal_home_screen.dart';
import '../features/movies/random_movie_screen.dart';
import '../features/movies/random_result_screen.dart';
import '../features/movies/movie_detail_screen.dart';
import '../features/movies/watchlist_screen.dart';
import '../features/movies/favorites_screen.dart';
import '../features/profile/profile_screen.dart';
import 'constants.dart';

bool _isLoggedIn() {
  try {
    return Supabase.instance.client.auth.currentSession != null;
  } catch (_) {
    return false;
  }
}

class _AuthRefreshNotifier extends ChangeNotifier {
  late final StreamSubscription<AuthState> _subscription;

  _AuthRefreshNotifier() {
    _subscription = Supabase.instance.client.auth.onAuthStateChange.listen((_) {
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

final _authRefreshNotifier = _AuthRefreshNotifier();

final appRouter = GoRouter(
  initialLocation: '/login',
  redirect: (context, state) {
    final loggedIn = _isLoggedIn();
    final goingToLogin = state.matchedLocation == '/login';

    if (!loggedIn && !goingToLogin) {
      return '/login';
    }
    if (loggedIn && goingToLogin) {
      return '/home';
    }
    return null;
  },
  refreshListenable: _authRefreshNotifier,
  routes: [
    GoRoute(
      path: '/login',
      name: RouteNames.login,
      builder: (context, state) => const LoginScreen(),
    ),
    ShellRoute(
      builder: (context, state, child) =>
          MainScaffold(currentLocation: state.uri.path, child: child),
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
        GoRoute(
          path: '/detail',
          name: RouteNames.detail,
          builder: (context, state) => const MovieDetailScreen(),
        ),
        GoRoute(
          path: '/watchlist',
          name: RouteNames.watchlist,
          builder: (context, state) => const WatchlistScreen(),
        ),
        GoRoute(
          path: '/favorites',
          name: RouteNames.favorites,
          builder: (context, state) => const FavoritesScreen(),
        ),
        GoRoute(
          path: '/profile',
          name: RouteNames.profile,
          builder: (context, state) => const ProfileScreen(),
        ),
      ],
    ),
  ],
);

class MainScaffold extends StatelessWidget {
  final String currentLocation;
  final Widget child;
  const MainScaffold({
    super.key,
    required this.currentLocation,
    required this.child,
  });
  int _calculateIndex() {
    if (currentLocation.startsWith('/random')) {
      return 1;
    }
    if (currentLocation.startsWith('/profile')) {
      return 2;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _calculateIndex(),
        backgroundColor: const Color(0xFF0E1220),
        selectedItemColor: const Color(0xFFFF6363),
        unselectedItemColor: Colors.white70,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          if (index == 0) context.goNamed(RouteNames.home);
          if (index == 1) context.goNamed(RouteNames.random);
          if (index == 2) context.goNamed(RouteNames.profile);
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
