import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'track_detail_screen.dart';

import '../../tracking/providers/tracking_provider.dart';
import '../../auth/providers/auth_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  // --- МЕТОД ДЛЯ ВЫБОРА ИКОНКИ ---
  IconData getIconForType(String type) {
    switch(type) {
      case 'Walking': return Icons.directions_walk_rounded;
      case 'Running': return Icons.directions_run_rounded;
      case 'Hiking': default: return Icons.terrain_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tracker = Provider.of<TrackingProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final tracks = tracker.savedTracks;

    final int totalHikes = tracks.length;
    final double totalDistance = tracks.fold(0.0, (sum, track) => sum + track.distanceKm);
    final int totalElevation = 0;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text('Profile', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white),
            onPressed: () {},
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- ШАПКА ---
            Center(
              child: Column(
                children: [
                  // НОВЫЙ КОД: Заглавная буква имени
                  Container(
                    width: 100, height: 100,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white24, width: 2),
                      color: const Color(0xFF32D74B).withOpacity(0.2), // Полупрозрачный зеленый фон
                    ),
                    child: Text(
                      (authProvider.user?.username ?? 'S').substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF32D74B) // Зеленый текст
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                      authProvider.user?.username ?? 'Salamat Zakenov',
                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)
                  ),
                  const SizedBox(height: 4),
                  Text(
                      authProvider.user?.email ?? 'salamat@zakenov.com',
                      style: const TextStyle(color: Colors.white54, fontSize: 16)
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // --- СТАТИСТИКА ---
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatItem(totalHikes.toString(), 'Activities'),
                      _buildDivider(),
                      _buildStatItem('${totalDistance.toStringAsFixed(1)} km', 'Distance'),
                      _buildDivider(),
                      _buildStatItem('$totalElevation m', 'Elevation'),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // --- СПИСОК ТРЕНИРОВОК ---
            const Text('My Routes', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            if (tracks.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    children: [
                      Icon(Icons.directions_walk_rounded, color: Colors.white.withOpacity(0.2), size: 64),
                      const SizedBox(height: 16),
                      const Text("You haven't recorded any activities yet.", style: TextStyle(color: Colors.white54), textAlign: TextAlign.center),
                    ],
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: tracks.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final track = tracks[index];
                  final dateStr = "${track.date.day.toString().padLeft(2, '0')}.${track.date.month.toString().padLeft(2, '0')}.${track.date.year}";
                  final durationMin = track.durationSeconds ~/ 60;

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TrackDetailScreen(track: track),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.05)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: const Color(0xFF32D74B).withOpacity(0.2), shape: BoxShape.circle),
                            child: Icon(getIconForType(track.type), color: const Color(0xFF32D74B)),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(track.name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 4),
                                Text(dateStr, style: const TextStyle(color: Colors.white54, fontSize: 14)),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('${track.distanceKm.toStringAsFixed(2)} km', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text('$durationMin min', style: const TextStyle(color: Colors.white54, fontSize: 14)),
                            ],
                          )
                        ],
                      ),
                    ),
                  );
                },
              ),
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

  Widget _buildDivider() {
    return Container(width: 1, height: 40, color: Colors.white.withOpacity(0.1));
  }
}