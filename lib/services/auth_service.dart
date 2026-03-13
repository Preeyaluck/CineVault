import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _client = Supabase.instance.client;

  // ฟังก์ชัน Login ที่คืนค่าเป็นข้อมูลผู้ใช้และ Token
  Future<Map<String, dynamic>?> login(String email, String password) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      final session = response.session;
      final user = response.user;
      if (session != null && user != null) {
        return {
          'token': session.accessToken,
          'user': {
            'id': user.id,
            'email': user.email,
            'name': user.userMetadata?['name']?.toString() ?? '',
          },
        };
      }
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Login failed: $e');
    }

    return null; // Login ไม่สำเร็จ
  }

  // ฟังก์ชัน Register สมัครสมาชิกกับ Supabase
  Future<Map<String, dynamic>?> register(
    String name,
    String email,
    String password,
  ) async {
    try {
      final response = await _client.auth.signUp(
        email: email.trim(),
        password: password,
        data: {'name': name.trim()},
      );

      final session = response.session;
      final user = response.user;

      if (user != null) {
        // ถ้าเปิดยืนยันอีเมลใน Supabase session อาจเป็น null ได้
        return {
          'token': session?.accessToken,
          'user': {
            'id': user.id,
            'email': user.email,
            'name': user.userMetadata?['name']?.toString() ?? name.trim(),
          },
        };
      }
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Register failed: $e');
    }

    return null; // Register ไม่สำเร็จ
  }

  bool hasActiveSession() {
    return _client.auth.currentSession != null;
  }

  // ฟังก์ชัน Logout
  Future<void> logout() async {
    try {
      await _client.auth.signOut();
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Logout failed: $e');
    }
  }
}
