import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/movie_model.dart';

// จัดการข้อมูลหนังที่เลือกหรือสุ่มได้เพื่อแชร์ข้ามหน้า [cite: 220]
final selectedMovieProvider = StateProvider<Movie?>((ref) => null);