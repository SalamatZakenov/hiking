// lib/features/profile/presentation/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Profile', style: TextStyle(color: AppTheme.textGrey)),
        actions: [
          IconButton(icon: const Icon(Icons.settings_outlined, color: AppTheme.accentYellow), onPressed: () {}),
          IconButton(icon: const Icon(Icons.more_horiz, color: AppTheme.accentYellow), onPressed: () {}),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Аватар и Имя
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 45,
                    backgroundColor: AppTheme.cardDark,
                    child: const Icon(Icons.person, size: 50, color: AppTheme.textGrey),
                  ),
                  const SizedBox(width: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user?.username ?? 'Yana Yerzhanova',
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                      const Text('Almaty, KZ', style: TextStyle(color: AppTheme.textGrey)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Статистика (Followers / Following / Activity)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStat('—', 'Followers'),
                _buildStat('—', 'Following'),
                _buildStat('—', 'Activity'),
              ],
            ),
            const SizedBox(height: 30),

            // Большая центральная карточка
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppTheme.cardDark,
                borderRadius: BorderRadius.circular(32),
              ),
              child: Column(
                children: [
                  const Icon(Icons.style_outlined, size: 100, color: AppTheme.accentYellow),
                  const SizedBox(height: 24),
                  const Text('Collect your hiking history',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 12),
                  const Text(
                    'Start exploring trails and you can track your statistics for the month, year, or all time.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.textGrey, fontSize: 14),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Кнопка Try Navigator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: FilledButton(
                onPressed: () {},
                child: const Text('Try Navigator'),
              ),
            ),
            const SizedBox(height: 100), // Отступ под навигацию
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: AppTheme.textGrey, fontSize: 12)),
      ],
    );
  }
}