// lib/features/profile/presentation/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // 0 - Publications, 1 - Completed
  int _selectedTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final String username = user?.username ?? 'explorer';

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppTheme.bgDark,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text('@$username', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          centerTitle: true,
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

              // --- 2. ПЕРЕКЛЮЧАТЕЛЬ ВКЛАДОК ---
              Container(
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.1), width: 1)),
                ),
                child: Row(
                  children: [
                    _buildTabOption('Publications', 0),
                    _buildTabOption('Completed', 1),
                  ],
                ),
              ),

              // --- 3. КОНТЕНТ ВКЛАДОК ---
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: _selectedTabIndex == 0
                    ? _buildPublicationsList()
                    : _buildCompletedList(),
              ),

              const SizedBox(height: 100), // Отступ под нижнюю панель навигации
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

  // --- ВИДЖЕТЫ ВКЛАДОК ---

  Widget _buildTabOption(String title, int index) {
    final isActive = _selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTabIndex = index),
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isActive ? Colors.white : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.white54,
              fontSize: 16,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPublicationsList() {
    return Column(
      children: [
        _buildPublicationCard(
          location: 'Furmanov Peak',
          date: 'Yesterday at 14:30',
          imageUrl: 'https://images.unsplash.com/photo-1522163182402-834f871fd851?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80',
          caption: 'Great weather, but the last kilometer was tough! 🏔️☀️',
          likes: '124',
          comments: '12',
        ),
        _buildPublicationCard(
          location: 'Kok Tobe',
          date: 'Oct 12, 2025',
          imageUrl: 'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80',
          caption: 'Evening stroll. The city lights are mesmerizing from up here. 🌆',
          likes: '89',
          comments: '4',
        ),
      ],
    );
  }

  Widget _buildCompletedList() {
    return Column(
      children: [
        _buildCompletedWorkoutCard('Furmanov Peak', 'Oct 24, 2025', '14.5 km', '4h 20m', 'HARD'),
        _buildCompletedWorkoutCard('Kok Tobe', 'Oct 12, 2025', '6.2 km', '1h 15m', 'EASY'),
        _buildCompletedWorkoutCard('Butakovka Waterfall', 'Sep 28, 2025', '8.4 km', '2h 10m', 'MEDIUM'),
      ],
    );
  }

  // --- КОМПОНЕНТЫ ДЛЯ ПУБЛИКАЦИЙ ---

  Widget _buildPublicationCard({required String location, required String date, required String imageUrl, required String caption, required String likes, required String comments}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white10)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const Icon(Icons.location_on_rounded, color: Colors.blueAccent, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(location, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(date, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                      ],
                    ),
                  ),
                  const Icon(Icons.more_horiz_rounded, color: Colors.white54),
                ],
              ),
            ),
            Image.network(imageUrl, height: 250, width: double.infinity, fit: BoxFit.cover),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(caption, style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4)),
            ),
            const Divider(color: Colors.white10, height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                children: [
                  const Icon(Icons.favorite_border_rounded, color: Colors.white54, size: 24),
                  const SizedBox(width: 6),
                  Text(likes, style: const TextStyle(color: Colors.white54, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 24),
                  const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white54, size: 22),
                  const SizedBox(width: 6),
                  Text(comments, style: const TextStyle(color: Colors.white54, fontWeight: FontWeight.bold)),
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

  // --- КОМПОНЕНТЫ ДЛЯ ЗАВЕРШЕННЫХ МАРШРУТОВ ---

  Widget _buildCompletedWorkoutCard(String title, String date, String distance, String time, String difficulty) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              Text(date, style: const TextStyle(color: Colors.white54, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMiniStat(Icons.route_rounded, distance),
              _buildMiniStat(Icons.timer_outlined, time),
              _buildDifficultyBadge(difficulty),
            ],
          ),
        ],
      ),
    );
  }

  // --- ВСПОМОГАТЕЛЬНЫЕ ЭЛЕМЕНТЫ ---

  Widget _buildProfileStat(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 13)),
      ],
    );
  }

  Widget _buildMiniStat(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.cardSlate, size: 16),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildDifficultyBadge(String difficulty) {
    Color badgeColor;
    switch (difficulty.toUpperCase()) {
      case 'HARD': badgeColor = const Color(0xFFFF5252); break;
      case 'EASY': badgeColor = const Color(0xFF4CAF50); break;
      case 'MEDIUM': badgeColor = const Color(0xFFFF9F0A); break;
      default: badgeColor = const Color(0xFFFFC107);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: badgeColor.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
      child: Text(difficulty.toUpperCase(), style: TextStyle(color: badgeColor, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
    );
  }

  // --- ШТОРКА НАСТРОЕК ---
  void _showSettingsPanel(BuildContext context, AuthProvider authProvider) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Color(0xFF1E1E1E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 32),

            // --- СЮДА ПЕРЕЕХАЛИ КНОПКИ ---
            _buildSettingsItem(Icons.edit_rounded, 'Edit Profile'),
            _buildSettingsItem(Icons.ios_share_rounded, 'Share Profile'),

            // Остальные настройки
            _buildSettingsItem(Icons.person_outline_rounded, 'Account Settings'),
            _buildSettingsItem(Icons.notifications_none_rounded, 'Notifications'),
            _buildSettingsItem(Icons.download_done_rounded, 'Offline Maps'),
            _buildSettingsItem(Icons.help_outline_rounded, 'Help & Support'),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: Colors.redAccent.withOpacity(0.1), foregroundColor: Colors.redAccent, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Log Out', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                onPressed: () {
                  Navigator.pop(context);
                  authProvider.logout();
                },
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsItem(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 28),
          const SizedBox(width: 16),
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500)),
          const Spacer(),
          const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white24, size: 16),
        ],
      ),
    );
  }
}