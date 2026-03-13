import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants.dart';
import '../../services/auth_service.dart';
import '../../services/profile_service.dart';
import 'auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  final _profileService = ProfileService();
  bool _isLoading = false;
  bool _isLoginMode = true;
  bool _obscurePassword = true;
  int _signupCooldownSeconds = 0;
  Timer? _cooldownTimer;

  String _normalizeEmail(String input) {
    return input
        .trim()
        .replaceAll('"', '')
        .replaceAll("'", '')
        .replaceAll(' ', '')
        .toLowerCase();
  }

  InputDecoration _fieldDecoration({
    required String label,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFFFF8A7A)),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xFF121829),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF2A3550)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF2A3550)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFFF7B6B), width: 1.5),
      ),
      labelStyle: const TextStyle(color: Color(0xFFC6CDDE)),
    );
  }

  String _cleanErrorMessage(Object error) {
    return error.toString().replaceFirst('Exception: ', '').trim();
  }

  bool _isRateLimitError(String message) {
    final text = message.toLowerCase();
    return text.contains('rate limit') || text.contains('too many requests');
  }

  bool get _isSignupBlocked => !_isLoginMode && _signupCooldownSeconds > 0;

  void _startSignupCooldown([int seconds = 60]) {
    _cooldownTimer?.cancel();
    setState(() => _signupCooldownSeconds = seconds);

    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_signupCooldownSeconds <= 1) {
        timer.cancel();
        setState(() => _signupCooldownSeconds = 0);
        return;
      }
      setState(() => _signupCooldownSeconds -= 1);
    });
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _normalizeEmail(_emailController.text);
    final password = _passwordController.text;
    final name = _nameController.text.trim();

    if (email.isEmpty || password.isEmpty || (!_isLoginMode && name.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields.')),
      );
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Password must be at least 6 characters.')),
      );
      return;
    }

    if (_isSignupBlocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'กรุณารอ $_signupCooldownSeconds วินาทีก่อนสมัครใหม่',
          ),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = _isLoginMode
          ? await _authService.login(email, password)
          : await _authService.register(name, email, password);

      if (!mounted) return;

      if (result != null && result['token'] != null) {
        await _profileService.ensureCurrentProfile(fallbackName: name);
        if (!mounted) return;
        ref.read(authProvider.notifier).state = true;
        context.goNamed(RouteNames.home);
        return;
      }

      if (!_isLoginMode) {
        // If sign-up succeeds but no token is returned, try immediate sign-in.
        final loginResult = await _authService.login(email, password);
        if (!mounted) return;

        if (loginResult != null && loginResult['token'] != null) {
          await _profileService.ensureCurrentProfile(fallbackName: name);
          if (!mounted) return;
          ref.read(authProvider.notifier).state = true;
          context.goNamed(RouteNames.home);
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'สมัครสำเร็จแล้ว แต่ยังเข้าใช้งานไม่ได้ กรุณาตรวจสอบการตั้งค่า Email Confirm ใน Supabase',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      final errorMessage = _cleanErrorMessage(e);

      // กรณีสมัครซ้ำจนโดนจำกัดอีเมล ลองล็อกอินด้วยบัญชีเดิมให้อัตโนมัติ
      if (!_isLoginMode && _isRateLimitError(errorMessage)) {
        _startSignupCooldown(60);
        try {
          final loginResult = await _authService.login(email, password);
          if (!mounted) return;

          if (loginResult != null && loginResult['token'] != null) {
            await _profileService.ensureCurrentProfile(fallbackName: name);
            if (!mounted) return;
            ref.read(authProvider.notifier).state = true;
            context.goNamed(RouteNames.home);
            return;
          }
        } catch (_) {
          // หาก fallback login ไม่สำเร็จ จะแสดงข้อความด้านล่างแทน
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'ระบบส่งอีเมลถึงขีดจำกัดชั่วคราว กรุณารอสักครู่แล้วลองใหม่ หรือสลับไปแท็บ Login',
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0D15),
      body: Stack(
        children: [
          Positioned(
            top: -120,
            right: -80,
            child: Container(
              width: 280,
              height: 280,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Color(0x55FF6D5A), Color(0x00FF6D5A)],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -140,
            left: -100,
            child: Container(
              width: 320,
              height: 320,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Color(0x334EA0FF), Color(0x004EA0FF)],
                ),
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
                  decoration: BoxDecoration(
                    color: const Color(0xCC111729),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFF26314A)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(120),
                        blurRadius: 30,
                        offset: const Offset(0, 16),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 66,
                        height: 66,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFFFF7B6B), Color(0xFFE64545)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x66FF6F61),
                              blurRadius: 18,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.local_movies_rounded,
                          color: Colors.white,
                          size: 34,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'CineVault',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isLoginMode
                            ? 'Welcome back. Your next movie awaits.'
                            : 'Create your vault and start discovering.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFFB8C0D4),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 18),
                      SegmentedButton<bool>(
                        style: SegmentedButton.styleFrom(
                          selectedForegroundColor: Colors.white,
                          selectedBackgroundColor: const Color(0xFFE14E42),
                          foregroundColor: const Color(0xFFC9D0E0),
                        ),
                        segments: const [
                          ButtonSegment<bool>(
                              value: true, label: Text('Login')),
                          ButtonSegment<bool>(
                              value: false, label: Text('Sign Up')),
                        ],
                        selected: {_isLoginMode},
                        onSelectionChanged: (selection) {
                          setState(() => _isLoginMode = selection.first);
                        },
                      ),
                      const SizedBox(height: 12),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 320),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        transitionBuilder: (child, animation) {
                          final slide = Tween<Offset>(
                            begin: const Offset(0.08, 0),
                            end: Offset.zero,
                          ).animate(animation);
                          return FadeTransition(
                            opacity: animation,
                            child:
                                SlideTransition(position: slide, child: child),
                          );
                        },
                        child: Column(
                          key: ValueKey<bool>(_isLoginMode),
                          children: [
                            if (_isSignupBlocked) ...[
                              const SizedBox(height: 10),
                              Text(
                                'Signup cooldown: $_signupCooldownSeconds s',
                                style: const TextStyle(
                                    color: Colors.amber, fontSize: 12),
                              ),
                            ],
                            const SizedBox(height: 20),
                            if (!_isLoginMode) ...[
                              TextField(
                                controller: _nameController,
                                style: const TextStyle(color: Colors.white),
                                decoration: _fieldDecoration(
                                  label: 'Full name',
                                  icon: Icons.person_outline_rounded,
                                ),
                              ),
                              const SizedBox(height: 14),
                            ],
                            TextField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              autocorrect: false,
                              enableSuggestions: false,
                              style: const TextStyle(color: Colors.white),
                              decoration: _fieldDecoration(
                                label: 'Email',
                                icon: Icons.email_outlined,
                              ),
                            ),
                            const SizedBox(height: 14),
                            TextField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              style: const TextStyle(color: Colors.white),
                              decoration: _fieldDecoration(
                                label: 'Password',
                                icon: Icons.lock_outline_rounded,
                                suffixIcon: IconButton(
                                  onPressed: () {
                                    setState(() =>
                                        _obscurePassword = !_obscurePassword);
                                  },
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: const Color(0xFFB9C0D2),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 22),
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: _isLoading
                                  ? const Center(
                                      child: CircularProgressIndicator())
                                  : FilledButton(
                                      style: FilledButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFFE65346),
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(14),
                                        ),
                                      ),
                                      onPressed:
                                          _isSignupBlocked ? null : _submit,
                                      child: Text(
                                        _isLoginMode
                                            ? 'Login'
                                            : _isSignupBlocked
                                                ? 'Wait $_signupCooldownSeconds s'
                                                : 'Create Account',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                            ),
                            const SizedBox(height: 12),
                            TextButton(
                              onPressed: _isLoading
                                  ? null
                                  : () => setState(
                                      () => _isLoginMode = !_isLoginMode),
                              child: Text(
                                _isLoginMode
                                    ? 'No account? Sign up here'
                                    : 'Already have an account? Login',
                                style:
                                    const TextStyle(color: Color(0xFFB8C0D4)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
