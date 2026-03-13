import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  void _handleRegister() async {
    setState(() => _isLoading = true);

    final result = await AuthService().register(
      _nameController.text,
      _emailController.text,
      _passwordController.text,
    );

    // เช็กว่า Widget ยังอยู่บนหน้าจอไหม ก่อนจะใช้ context ต่อ
    if (!mounted) return;

    setState(() => _isLoading = false);

    if (result != null) {
      context.go('/home'); // สมัครสำเร็จไปหน้า Home
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registration Failed!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          // เพิ่มเพื่อให้หน้าจอไม่ล้นเวลาคีย์บอร์ดเด้ง
          child: Column(
            children: [
              TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Full Name')),
              TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email')),
              TextField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true),
              const SizedBox(height: 20),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _handleRegister,
                      child: const Text('Sign Up'),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    // ล้าง Controller เมื่อปิดหน้าจอเพื่อประหยัดหน่วยความจำ
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
