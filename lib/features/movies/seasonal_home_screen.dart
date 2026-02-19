import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/movie_model.dart';
import '../../core/constants.dart';

class SeasonalHomeScreen extends StatelessWidget {
  const SeasonalHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Seasonal Favorites')),
      body: FutureBuilder<List<Movie>>(
        future: ApiService().fetchMovies(AppConstants.popularMovies),
        builder: (context, snapshot) {
          // 1. เช็กสถานะการโหลด
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 2. เช็กว่ามี Error หรือไม่มีข้อมูลไหม (ป้องกันแอพเด้ง)
          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(child: Text('Something went wrong!'));
          }

          final movies = snapshot.data!;

          // 3. แก้ไข GridView.builder ลบ ออก
          return GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.7, // ปรับให้รูปเป็นทรงสูงสวยขึ้น
            ),
            itemCount: movies.length,
            itemBuilder: (context, index) => Card(
              clipBehavior: Clip.antiAlias, // ตัดขอบรูปให้โค้งตาม Card
              child: Image.network(
                movies[index].posterUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.broken_image), // กรณีรูปโหลดไม่ได้
              ),
            ),
          );
        },
      ),
    );
  }
}
