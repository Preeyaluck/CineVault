import 'dart:async';

class AuthService {
  // ฟังก์ชัน Login ที่คืนค่าเป็นข้อมูลผู้ใช้และ Token
  Future<Map<String, dynamic>?> login(String email, String password) async {
    // จำลองความหน่วงเวลาติดต่อ Server
    await Future.delayed(const Duration(seconds: 2));

    // Validation เบื้องต้นตามที่คุณออกแบบไว้
    if (email.contains('@') && password.length >= 6) {
      return {
        'token': 'fake-jwt-token-for-cinevault', // ในอนาคตใช้ Token จริงจาก API
        'user': {
          'name': 'Preeyaluk',
          'email': email,
        }
      };
    }
    return null; // Login ไม่สำเร็จ
  }

  // ฟังก์ชัน Logout
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 500));
    // ในอนาคตจะมีการล้าง Secure Storage ที่นี่
  }
}