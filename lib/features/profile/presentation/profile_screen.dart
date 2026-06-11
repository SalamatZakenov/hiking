// lib/features/profile/presentation/profile_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/custom_header.dart';
import '../../../core/widgets/feed_post_card.dart';

import '../../tracking/providers/tracking_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../tracking/data/models/local_track.dart';
import '../../../core/theme/app_theme.dart';


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

  int _calculateWeeklyStreak(List<LocalTrack> tracks) {
    if (tracks.isEmpty) return 0;
    Set<int> activeWeeks = tracks.map((t) {
      return (t.date.millisecondsSinceEpoch ~/ 86400000 + 3) ~/ 7;
    }).toSet();

    int currentWeek = (DateTime.now().millisecondsSinceEpoch ~/ 86400000 + 3) ~/ 7;
    int streak = 0;

    if (activeWeeks.contains(currentWeek)) {
      int check = currentWeek;
      while (activeWeeks.contains(check)) {
        streak++;
        check--;
      }
    } else if (activeWeeks.contains(currentWeek - 1)) {
      int check = currentWeek - 1;
      while (activeWeeks.contains(check)) {
        streak++;
        check--;
      }
    }
    return streak;
  }

  @override
  Widget build(BuildContext context) {
    final tracker = Provider.of<TrackingProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final tracks = tracker.savedTracks;
    final int totalHikes = tracks.length;
    final double totalDistance = tracks.fold(0.0, (sum, track) => sum + track.distanceKm);
    final int weeklyStreak = _calculateWeeklyStreak(tracks);

    final String rawName = authProvider.user?.username ?? 'Salamat Zakenov';
    final String handle = '@${rawName.replaceAll(' ', '').toLowerCase()}';

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
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
              GlassButton(icon: Icons.settings_rounded, onTap: () => _showLogoutDialog(context, authProvider)),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: const Color(0xFF00E5FF).withOpacity(0.2), // Изменен цвет
                        child: Text(
                          rawName[0].toUpperCase(),
                          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF00E5FF)), // Изменен цвет
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              rawName,
                              style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              handle,
                              style: const TextStyle(color: Colors.white54, fontSize: 16, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  RichText(
                    text: const TextSpan(
                      style: TextStyle(fontSize: 16, color: Colors.white),
                      children: [
                        TextSpan(text: '0', style: TextStyle(fontWeight: FontWeight.bold)),
                        TextSpan(text: ' followers  ·  ', style: TextStyle(color: Colors.white70)),
                        TextSpan(text: '0', style: TextStyle(fontWeight: FontWeight.bold)),
                        TextSpan(text: ' following', style: TextStyle(color: Colors.white70)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
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
                        Container(width: 1, height: 40, color: Colors.white.withOpacity(0.1)),
                        _buildStatItem('$weeklyStreak wks', 'Streak'),
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
                physics: const NeverScrollableScrollPhysics(),
                itemCount: tracks.length,
                itemBuilder: (context, index) {
                  return FeedPostCard(track: tracks[index]);
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
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 13)),
      ],
    );
  }
}