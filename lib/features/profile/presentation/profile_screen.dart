// lib/features/profile/presentation/profile_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/custom_header.dart';
import '../../../core/widgets/feed_post_card.dart'; // <--- ИМПОРТ НАШЕГО НОВОГО ВИДЖЕТА

import '../../tracking/providers/tracking_provider.dart';
import '../../auth/providers/auth_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _showLogoutDialog(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Log Out', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to log out?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () async {
              await authProvider.logout();
              if (context.mounted) {
                context.go('/login');
              }
            },
            child: const Text('Log Out', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tracker = Provider.of<TrackingProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final tracks = tracker.savedTracks;
    final int totalHikes = tracks.length;
    final double totalDistance = tracks.fold(0.0, (sum, track) => sum + track.distanceKm);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        toolbarHeight: 80,
        titleSpacing: 0,
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: CustomHeader(
            title: 'PROFILE',
            actions: [
              GlassButton(icon: Icons.notifications_none_rounded, onTap: () {}),
              GlassButton(icon: Icons.settings_rounded, onTap: () => _showLogoutDialog(context, authProvider)),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Container(
              width: 100, height: 100, alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white24, width: 2),
                color: const Color(0xFF32D74B).withOpacity(0.2),
              ),
              child: Text(
                (authProvider.user?.username ?? 'S').substring(0, 1).toUpperCase(),
                style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Color(0xFF32D74B)),
              ),
            ),
            const SizedBox(height: 16),
            Text(authProvider.user?.username ?? 'Salamat Zakenov', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            Text(authProvider.user?.email ?? 'salamat@zakenov.com', style: const TextStyle(color: Colors.white54, fontSize: 16)),
            const SizedBox(height: 32),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white.withOpacity(0.1))),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatItem(totalHikes.toString(), 'Activities'),
                        Container(width: 1, height: 40, color: Colors.white.withOpacity(0.1)),
                        _buildStatItem('${totalDistance.toStringAsFixed(1)} km', 'Distance'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),

            if (tracks.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32.0),
                child: Text("You haven't recorded any activities yet.", style: TextStyle(color: Colors.white54), textAlign: TextAlign.center),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(), // Чтобы не ломать скролл родительского SingleChildScrollView
                itemCount: tracks.length,
                itemBuilder: (context, index) {
                  return FeedPostCard(track: tracks[index]); // <--- ИСПОЛЬЗУЕМ ОДИНАКОВУЮ КАРТОЧКУ
                },
              ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 14)),
      ],
    );
  }
}