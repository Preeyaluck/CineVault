import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/constants.dart';
import '../models/profile_model.dart';

class ProfileService {
  final SupabaseClient _client = Supabase.instance.client;
  static const String _avatarBucket = 'profile-images';

  Exception _mapStorageException(StorageException e) {
    final message = e.message.toLowerCase();
    final isRlsViolation =
        message.contains('row-level security') ||
        message.contains('violates row-level security policy');
    final isUnauthorized = e.statusCode == '401' || e.statusCode == '403';

    if (isRlsViolation || isUnauthorized) {
      return Exception(
        'Avatar upload is blocked by Supabase Storage RLS policy '
        '(bucket: $_avatarBucket). Please allow authenticated users to '
        'insert/update/delete their own files under <uid>/*',
      );
    }

    return Exception(e.message);
  }

  String _resolveName(User user, {String? fallbackName}) {
    final metaName = user.userMetadata?['name']?.toString().trim() ?? '';
    if (metaName.isNotEmpty) return metaName;

    final candidate = fallbackName?.trim() ?? '';
    if (candidate.isNotEmpty) return candidate;

    final email = user.email ?? '';
    if (email.contains('@')) return email.split('@').first;

    return 'CineVault User';
  }

  Future<void> ensureCurrentProfile({String? fallbackName}) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    final existing = await _client
        .from('profiles')
        .select('id')
        .eq('id', user.id)
        .maybeSingle();

    if (existing != null) {
      return;
    }

    await _client.from('profiles').insert({
      'id': user.id,
      'full_name': _resolveName(user, fallbackName: fallbackName),
      'email': user.email ?? '',
      'membership': 'Free',
      'language': AppConstants.defaultLanguage,
      'watchlist_count': 0,
      'watched_count': 0,
      'favorites_count': 0,
    });
  }

  Future<ProfileModel> getCurrentProfile({String? fallbackName}) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('No authenticated user');
    }

    await ensureCurrentProfile(fallbackName: fallbackName);

    final row =
        await _client.from('profiles').select().eq('id', user.id).single();

    var watchlistCount = ((row['watchlist_count'] ?? 0) as num).toInt();
    var favoritesCount = ((row['favorites_count'] ?? 0) as num).toInt();
    try {
      final watchlistRows = await _client
          .from('watchlist_items')
          .select('movie_id')
          .eq('user_id', user.id);
      watchlistCount = (watchlistRows as List).length;

      final favoriteRows = await _client
          .from('favorites_items')
          .select('movie_id')
          .eq('user_id', user.id);
      favoritesCount = (favoriteRows as List).length;

      final updates = <String, dynamic>{};
      if (watchlistCount != ((row['watchlist_count'] ?? 0) as num).toInt()) {
        updates['watchlist_count'] = watchlistCount;
      }
      if (favoritesCount != ((row['favorites_count'] ?? 0) as num).toInt()) {
        updates['favorites_count'] = favoritesCount;
      }
      if (updates.isNotEmpty) {
        await _client.from('profiles').update(updates).eq('id', user.id);
      }
    } catch (_) {
      // Keep existing value if watchlist table is not ready yet.
    }

    return ProfileModel.fromJson({
      ...row,
      'watchlist_count': watchlistCount,
      'favorites_count': favoritesCount,
    });
  }

  Stream<ProfileModel> watchCurrentProfile() {
    final user = _client.auth.currentUser;
    if (user == null) {
      return Stream<ProfileModel>.error(Exception('No authenticated user'));
    }

    return _client
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('id', user.id)
        .map((rows) {
          if (rows.isEmpty) {
            throw Exception('Profile not found');
          }
          return ProfileModel.fromJson(rows.first);
        });
  }

  Future<void> updateFullName(String fullName) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('No authenticated user');
    }

    final trimmed = fullName.trim();
    if (trimmed.isEmpty) {
      throw Exception('Name cannot be empty');
    }

    await _client
        .from('profiles')
        .update({'full_name': trimmed}).eq('id', user.id);

    await _client.auth.updateUser(
      UserAttributes(data: {'name': trimmed}),
    );
  }

  Future<void> updateAvatar(Uint8List bytes) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('No authenticated user');
    }

    final filePath =
        '${user.id}/avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';

    String? oldAvatarUrl;
    try {
      final existing = await _client
          .from('profiles')
          .select('avatar_url')
          .eq('id', user.id)
          .maybeSingle();
      oldAvatarUrl = (existing?['avatar_url'] as String?)?.trim();
    } catch (_) {
      // Best effort: continue even when old avatar is unavailable.
    }

    try {
      await _client.storage.from(_avatarBucket).uploadBinary(
            filePath,
            bytes,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: true,
            ),
          );
    } on StorageException catch (e) {
      throw _mapStorageException(e);
    }

    final avatarUrl =
        _client.storage.from(_avatarBucket).getPublicUrl(filePath);

    try {
      await _client
          .from('profiles')
          .update({'avatar_url': avatarUrl}).eq('id', user.id);
    } on PostgrestException catch (e) {
      if (e.message.toLowerCase().contains('avatar_url')) {
        throw Exception('Missing `avatar_url` column in `profiles` table');
      }
      rethrow;
    }

    await _deleteAvatarFromUrl(oldAvatarUrl);
  }

  Future<void> removeAvatar() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('No authenticated user');
    }

    String? oldAvatarUrl;
    try {
      final existing = await _client
          .from('profiles')
          .select('avatar_url')
          .eq('id', user.id)
          .maybeSingle();
      oldAvatarUrl = (existing?['avatar_url'] as String?)?.trim();
    } catch (_) {
      // Continue with profile update even if read fails.
    }

    try {
      await _client
          .from('profiles')
          .update({'avatar_url': null}).eq('id', user.id);
    } on PostgrestException catch (e) {
      if (e.message.toLowerCase().contains('avatar_url')) {
        throw Exception('Missing `avatar_url` column in `profiles` table');
      }
      rethrow;
    }

    await _deleteAvatarFromUrl(oldAvatarUrl);
  }

  Future<void> _deleteAvatarFromUrl(String? avatarUrl) async {
    if (avatarUrl == null || avatarUrl.isEmpty) return;

    const marker = '/storage/v1/object/public/$_avatarBucket/';
    final markerIndex = avatarUrl.indexOf(marker);
    if (markerIndex == -1) return;

    final objectPath = avatarUrl.substring(markerIndex + marker.length);
    if (objectPath.isEmpty) return;

    try {
      await _client.storage.from(_avatarBucket).remove([objectPath]);
    } on StorageException catch (_) {
      // Ignore cleanup failures caused by missing delete permission.
    } catch (_) {
      // Ignore cleanup failures.
    }
  }
}
