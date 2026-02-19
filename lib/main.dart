import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/app_router.dart';

void main() {
  // ลบ ออกเพื่อให้ Syntax ถูกต้อง
  runApp(const ProviderScope(child: CineVaultApp()));
}

class CineVaultApp extends StatelessWidget {
  const CineVaultApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: appRouter,
      theme: ThemeData.dark(), // ใช้ Theme มืดให้เข้ากับสไตล์ CineVault
      debugShowCheckedModeBanner: false,
    );
  }
}
