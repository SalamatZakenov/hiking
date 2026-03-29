// lib/features/profile/presentation/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppTheme.bgDark,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('My Diary', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          centerTitle: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.settings_outlined, color: Colors.white),
              onPressed: () => _showSettingsPanel(context, authProvider),
            ),
          ],
        ),
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- 1. ШАПКА ПРОФИЛЯ С ПОДПИСЧИКАМИ ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Аватар
                    Container(
                      width: 86, height: 86,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.cardSlate, width: 2),
                        color: const Color(0xFF2C2C2E),
                      ),
                      child: const Icon(Icons.person, size: 40, color: Colors.white54),
                    ),
                    const SizedBox(width: 20),
                    // Имя, локация и ПОДПИСЧИКИ
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.username ?? 'Explorer',
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.5),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Almaty, Kazakhstan',
                            style: TextStyle(color: Colors.white54, fontSize: 14),
                          ),
                          const SizedBox(height: 12),
                          // Блок Подписчики / Подписки
                          Row(
                            children: [
                              _buildSocialStat('430', 'Followers'),
                              const SizedBox(width: 16),
                              _buildSocialStat('120', 'Following'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // --- 2. СПОРТИВНАЯ СТАТИСТИКА ---
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildSportStat('12', 'Hikes'),
                    Container(width: 1, height: 40, color: Colors.white10),
                    _buildSportStat('145', 'Kilometers'),
                    Container(width: 1, height: 40, color: Colors.white10),
                    _buildSportStat('4.2k', 'Elevation (m)'),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // --- 3. ЗАГОЛОВОК ЛЕНТЫ ---
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.0),
                child: Text('Recent Activities', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 16),

              // --- 4. ЛЕНТА ПОСТОВ (ACTIVITY FEED) ---
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 3,
                itemBuilder: (context, index) {
                  return ActivityPostCard(
                    username: user?.username ?? 'Explorer',
                    routeName: index == 0 ? 'Kok Tobe Night Trail' : 'Big Almaty Peak',
                    date: index == 0 ? 'Yesterday at 18:30' : 'Oct 12, 2025',
                    caption: index == 0
                        ? 'Great evening hike! The city lights were amazing. A bit muddy on the way down, but totally worth it. 🌃🥾'
                        : 'Finally conquered BAP! The altitude hit hard, but the view is breathtaking.',
                    distance: index == 0 ? '4.2 km' : '8.5 km',
                    duration: index == 0 ? '1h 15m' : '4h 30m',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Открываем детали маршрута ${index == 0 ? "Kok Tobe" : "BAP"}...')),
                      );
                    },
                  );
                },
              ),

              const SizedBox(height: 100), // Отступ под навигацию
            ],
          ),
        ),
      ),
    );
  }

  // Виджет для Подписчиков
  Widget _buildSocialStat(String count, String label) {
    return Row(
      children: [
        Text(count, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 13)),
      ],
    );
  }

  // Виджет для Спортивной статы
  Widget _buildSportStat(String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }

  void _showSettingsPanel(BuildContext context, AuthProvider authProvider) {
    showModalBottomSheet(
        context: context, useRootNavigator: true, backgroundColor: const Color(0xFF1E1E1E),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (context) {
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 24),
                const Text('Settings', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.edit_outlined, color: Colors.white54),
                  title: const Text('Edit Profile', style: TextStyle(color: Colors.white)),
                  onTap: () => Navigator.pop(context),
                ),
                const Divider(color: Colors.white10, height: 32),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.redAccent),
                  title: const Text('Log Out', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                  onTap: () {
                    Navigator.pop(context);
                    authProvider.logout();
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        }
    );
  }
}

// --- ВИДЖЕТ КАРТОЧКИ ПОСТА (ДНЕВНИКА) ---
class ActivityPostCard extends StatelessWidget {
  final String username;
  final String routeName;
  final String date;
  final String caption;
  final String distance;
  final String duration;
  final VoidCallback onTap;

  const ActivityPostCard({
    super.key, required this.username, required this.routeName,
    required this.date, required this.caption, required this.distance,
    required this.duration, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
        decoration: BoxDecoration(
            color: const Color(0xFF2C2C2E),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 5))
            ]
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  CircleAvatar(radius: 18, backgroundColor: Colors.white10, child: const Icon(Icons.person, size: 20, color: Colors.white54)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(username, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                        Text(date, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                      ],
                    ),
                  ),
                  const Icon(Icons.more_vert, color: Colors.white54, size: 20),
                ],
              ),
            ),
            Container(
              height: 200, width: double.infinity, color: const Color(0xFF1E1E1E),
              child: Stack(
                children: [
                  const Center(child: Icon(Icons.terrain_rounded, size: 80, color: Colors.white10)),
                  Positioned(
                    top: 12, left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        children: [
                          const Icon(Icons.location_on, color: AppTheme.accentYellow, size: 14),
                          const SizedBox(width: 4),
                          Text(routeName, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _buildMiniStat(Icons.route_outlined, distance),
                      const SizedBox(width: 16),
                      _buildMiniStat(Icons.timer_outlined, duration),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(caption, style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4)),
                ],
              ),
            ),
            const Divider(color: Colors.white10, height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                children: [
                  const Icon(Icons.favorite_border_rounded, color: Colors.white54, size: 24),
                  const SizedBox(width: 6),
                  const Text('24', style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 24),
                  const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white54, size: 22),
                  const SizedBox(width: 6),
                  const Text('5', style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  const Icon(Icons.share_outlined, color: Colors.white54, size: 22),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.cardSlate, size: 16),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }
}