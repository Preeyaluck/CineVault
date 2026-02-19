import 'package:flutter_riverpod/flutter_riverpod.dart';

// จัดการสถานะการล็อกอิน [cite: 219]
final authProvider = StateProvider<bool>((ref) => false);