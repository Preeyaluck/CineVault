import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants.dart';
import '../../services/auth_service.dart';
import 'auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  // สร้าง Controller สำหรับดึงค่าจากช่องกรอก
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false; // สำหรับแสดงตัวหมุนโหลด

  void _handleLogin() async {
    setState(() => _isLoading = true);

    final authService = AuthService();
    final result = await authService.login(
      _emailController.text,
      _passwordController.text,
    );

    if (!mounted) return;

    if (result != null) {
      // ถ้าสำเร็จ: อัปเดตสถานะ Login และไปหน้า Home
      ref.read(authProvider.notifier).state = true;
      context.goNamed(RouteNames.home);
    } else {
      // ถ้าล้มเหลว: แจ้งเตือน
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('อีเมลหรือรหัสผ่านไม่ถูกต้อง (รหัสต้อง 6 ตัวขึ้นไป)')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.movie_filter, size: 80, color: Colors.blue),
                const Text('CineVault', 
                  style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                const SizedBox(height: 40),
                
                // ช่องกรอกอีเมล
                TextField(
                  controller: _emailController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                ),
                const SizedBox(height: 20),
                
                // ช่องกรอกรหัสผ่าน
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                ),
                const SizedBox(height: 30),
                
                // ปุ่ม Login พร้อมเช็คสถานะโหลด
                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                          backgroundColor: Colors.blue,
                        ),
                        onPressed: _handleLogin,
                        child: const Text('Login', style: TextStyle(color: Colors.white)),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}