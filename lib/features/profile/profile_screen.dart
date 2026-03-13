import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants.dart';
import '../../models/profile_model.dart';
import '../../services/auth_service.dart';
import '../../services/favorites_service.dart';
import '../../services/profile_service.dart';
import '../../services/watchlist_service.dart';
import '../auth/auth_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _profileService = ProfileService();
  final _imagePicker = ImagePicker();
  late Future<ProfileModel> _profileFuture;
  StreamSubscription<void>? _watchlistChangesSub;
  StreamSubscription<void>? _favoritesChangesSub;
  bool _notificationsEnabled = true;
  Uint8List? _localAvatarBytes;

  @override
  void initState() {
    super.initState();
    _profileFuture = _profileService.getCurrentProfile();
    _watchlistChangesSub = WatchlistService.changes.listen((_) {
      if (!mounted) return;
      _refreshProfile();
    });
    _favoritesChangesSub = FavoritesService.changes.listen((_) {
      if (!mounted) return;
      _refreshProfile();
    });
  }

  @override
  void dispose() {
    _watchlistChangesSub?.cancel();
    _favoritesChangesSub?.cancel();
    super.dispose();
  }

  void _refreshProfile() {
    setState(() {
      _profileFuture = _profileService.getCurrentProfile();
    });
  }

  Future<void> _editNameDialog(String currentName) async {
    final controller = TextEditingController(text: currentName);
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Profile'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: 'Display name'),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (saved != true) return;

    try {
      await _profileService.updateFullName(controller.text);
      if (!mounted) return;
      _refreshProfile();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile name updated')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _showTermsDialog() async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Terms & Conditions'),
          content: const SingleChildScrollView(
            child: Text(
              'By using CineVault, you agree to the following terms:\n\n'
              '1. Account use\n'
              '- Keep your login credentials secure.\n\n'
              '2. Personal data\n'
              '- Your profile and activity data are stored to provide app features.\n\n'
              '3. Content usage\n'
              '- Movie metadata is provided by third-party services and may change.\n\n'
              '4. Acceptable behavior\n'
              '- Do not misuse, exploit, or disrupt the service.\n\n'
              '5. Service updates\n'
              '- Features and policies may be updated over time.\n\n'
              '6. Contact\n'
              '- For support, please contact the CineVault team.',
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('I Understand'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showAvatarPicker(bool hasAvatar) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndUploadAvatar(ImageSource.gallery);
                },
              ),
              if (hasAvatar)
                ListTile(
                  leading: const Icon(Icons.delete_outline_rounded),
                  title: const Text('Remove Photo'),
                  onTap: () {
                    Navigator.pop(context);
                    _removeAvatar();
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickAndUploadAvatar(ImageSource source) async {
    try {
      final image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1200,
      );
      if (image == null) return;

      if (mounted) {
        setState(() {
          _localAvatarBytes = null;
        });
      }

      final bytes = await image.readAsBytes();
      if (mounted) {
        setState(() {
          _localAvatarBytes = bytes;
        });
      }
      await _profileService.updateAvatar(bytes);

      if (!mounted) return;
      _refreshProfile();
      setState(() {
        _localAvatarBytes = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile photo updated')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    }
  }

  Future<void> _removeAvatar() async {
    try {
      await _profileService.removeAvatar();
      if (!mounted) return;
      setState(() {
        _localAvatarBytes = null;
      });
      _refreshProfile();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile photo removed')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to remove profile photo')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Stack(
        children: [
          const _ProfileBackdrop(),
          SafeArea(
            child: FutureBuilder<ProfileModel>(
              future: _profileFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Failed to load profile\n${snapshot.error}',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                final profile = snapshot.data;
                if (profile == null) {
                  return const Center(child: Text('Profile not found'));
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _ProfileHeader(
                        displayName: profile.fullName,
                        email: profile.email,
                        localAvatarBytes: _localAvatarBytes,
                        avatarUrl: profile.avatarUrl,
                        onAvatarTap: () => _showAvatarPicker(
                          (profile.avatarUrl ?? '').isNotEmpty ||
                              _localAvatarBytes != null,
                        ),
                      ),
                      const SizedBox(height: 18),
                      _StatsRow(
                        watchlist: profile.watchlistCount,
                        favorites: profile.favoritesCount,
                        onWatchlistTap: () =>
                            context.pushNamed(RouteNames.watchlist),
                        onFavoritesTap: () =>
                            context.pushNamed(RouteNames.favorites),
                      ),
                      const SizedBox(height: 20),
                      const _SectionTitle(label: 'ACCOUNT'),
                      _GroupCard(
                        children: [
                          _MenuRow(
                            icon: Icons.person_outline_rounded,
                            label: 'Edit Profile',
                            onTap: () => _editNameDialog(profile.fullName),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const _SectionTitle(label: 'PREFERENCES'),
                      _GroupCard(
                        children: [
                          _SwitchRow(
                            icon: Icons.notifications_none_rounded,
                            label: 'Notifications',
                            value: _notificationsEnabled,
                            onChanged: (value) {
                              setState(() => _notificationsEnabled = value);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const _SectionTitle(label: 'SUPPORT'),
                      _GroupCard(
                        children: [
                          _MenuRow(
                            icon: Icons.gavel_rounded,
                            label: 'Terms & Conditions',
                            onTap: _showTermsDialog,
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFE64444),
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () async {
                          ref.read(authProvider.notifier).state = false;
                          await AuthService().logout();
                          if (!context.mounted) return;
                          context.goNamed(RouteNames.login);
                        },
                        icon: const Icon(Icons.logout_rounded),
                        label: const Text(
                          'Sign Out',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileBackdrop extends StatelessWidget {
  const _ProfileBackdrop();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0B0D15),
            Color(0xFF12172A),
            Color(0xFF090B13),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -50,
            right: -30,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFF6464).withAlpha(45),
              ),
            ),
          ),
          Positioned(
            bottom: 80,
            left: -70,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF4EA0FF).withAlpha(26),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final String displayName;
  final String email;
  final Uint8List? localAvatarBytes;
  final String? avatarUrl;
  final VoidCallback onAvatarTap;

  const _ProfileHeader({
    required this.displayName,
    required this.email,
    required this.localAvatarBytes,
    required this.avatarUrl,
    required this.onAvatarTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onAvatarTap,
          borderRadius: BorderRadius.circular(60),
          child: Container(
            width: 108,
            height: 108,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF6C4CFF), Color(0xFF3B2A8F)],
              ),
              border: Border.all(color: Colors.white24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6C4CFF).withAlpha(80),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: () {
              if (localAvatarBytes != null) {
                return ClipOval(
                  child: Image.memory(
                    localAvatarBytes!,
                    fit: BoxFit.cover,
                    width: 108,
                    height: 108,
                  ),
                );
              }

              if ((avatarUrl ?? '').isNotEmpty) {
                return ClipOval(
                  child: Image.network(
                    avatarUrl!,
                    fit: BoxFit.cover,
                    width: 108,
                    height: 108,
                    errorBuilder: (_, __, ___) {
                      return const Icon(
                        Icons.person,
                        size: 56,
                        color: Colors.white,
                      );
                    },
                  ),
                );
              }

              return const Icon(Icons.person, size: 56, color: Colors.white);
            }(),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          displayName,
          style: const TextStyle(
            fontSize: 27,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          email,
          style: TextStyle(
            color: Colors.white.withAlpha(190),
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

class _StatsRow extends StatelessWidget {
  final int watchlist;
  final int favorites;
  final VoidCallback onWatchlistTap;
  final VoidCallback onFavoritesTap;

  const _StatsRow({
    required this.watchlist,
    required this.favorites,
    required this.onWatchlistTap,
    required this.onFavoritesTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatTile(
            title: 'Watchlist',
            value: '$watchlist',
            icon: Icons.bookmark_rounded,
            onTap: onWatchlistTap,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatTile(
            title: 'Favorites',
            value: '$favorites',
            icon: Icons.favorite_rounded,
            onTap: onFavoritesTap,
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final VoidCallback? onTap;

  const _StatTile({
    required this.title,
    required this.value,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.light
                ? Colors.white.withAlpha(220)
                : Colors.white.withAlpha(14),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            children: [
              Icon(icon, size: 20, color: const Color(0xFFFF8A65)),
              const SizedBox(height: 8),
              Text(
                value,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.light
                      ? const Color(0xFF56627A)
                      : Colors.white.withAlpha(180),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String label;

  const _SectionTitle({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: Theme.of(context).brightness == Brightness.light
              ? const Color(0xFF8A96AB)
              : Colors.white70,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  final List<Widget> children;

  const _GroupCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Column(children: children),
    );
  }
}

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MenuRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final iconBg = Theme.of(context).brightness == Brightness.light
        ? const Color(0xFFE9EDF5)
        : const Color(0xFF1C2231);

    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: iconBg,
          border: Border.all(color: Colors.black12),
        ),
        child: Icon(icon),
      ),
      title: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final iconBg = Theme.of(context).brightness == Brightness.light
        ? const Color(0xFFE9EDF5)
        : const Color(0xFF1C2231);

    return ListTile(
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: iconBg,
          border: Border.all(color: Colors.black12),
        ),
        child: Icon(icon),
      ),
      title: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      trailing: Switch.adaptive(value: value, onChanged: onChanged),
      onTap: () => onChanged(!value),
    );
  }
}
