// lib/features/profile/presentation/profile_screen.dart
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../auth/providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  List<Map<String, dynamic>> _completedRoutes = [];
  bool _isLoading = true;
  double _totalDistanceAllTime = 0.0;

  @override
  void initState() {
    super.initState();
    _loadCompletedRoutes();
  }

  // --- Читаем сохраненные маршруты из памяти ---
  Future<void> _loadCompletedRoutes() async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedData = prefs.getString('completed_routes');

    if (savedData != null) {
      final List<dynamic> decoded = jsonDecode(savedData);
      double totalDist = 0;

      final routes = decoded.map((e) {
        final route = Map<String, dynamic>.from(e);
        totalDist += (route['distanceKm'] as num).toDouble();
        return route;
      }).toList();

      setState(() {
        _completedRoutes = routes;
        _totalDistanceAllTime = totalDist;
      });
    }
    setState(() => _isLoading = false);
  }

  // Форматируем дату в красивый вид
  String _formatDate(String isoString) {
    try {
      final date = DateTime.parse(isoString);
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${date.day} ${months[date.month - 1]}, ${date.year} • ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Unknown date';
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppTheme.bgDark,
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // --- ШАПКА ПРОФИЛЯ ---
            SliverToBoxAdapter(
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Profile', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                          IconButton(
                            icon: const Icon(Icons.logout_rounded, color: Colors.white54),
                            onPressed: () => authProvider.logout(), // Кнопка выхода!
                          )
                        ],
                      ),
                      const SizedBox(height: 30),

                      // Аватарка и Имя
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.blueAccent.withOpacity(0.2),
                        child: Text(
                          user?.username.substring(0, 1).toUpperCase() ?? 'U',
                          style: const TextStyle(fontSize: 40, color: Colors.blueAccent, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(user?.username ?? 'Hiker', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                      Text(user?.email ?? '', style: const TextStyle(color: Colors.white54, fontSize: 14)),

                      const SizedBox(height: 30),

                      // ГЛОБАЛЬНАЯ СТАТИСТИКА
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1C1C1E),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildGlobalStat('HIKES', _completedRoutes.length.toString()),
                            Container(width: 1, height: 40, color: Colors.white10),
                            _buildGlobalStat('DISTANCE', '${_totalDistanceAllTime.toStringAsFixed(1)} km'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // --- ЗАГОЛОВОК СПИСКА ---
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(24, 30, 24, 16),
                child: Text('Completed Routes', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              ),
            ),

            // --- СПИСОК МАРШРУТОВ (ИЗ ПАМЯТИ) ---
            if (_isLoading)
              const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator(color: Colors.blueAccent)))
            else if (_completedRoutes.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(40.0),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.directions_walk_rounded, size: 64, color: Colors.white.withOpacity(0.1)),
                        const SizedBox(height: 16),
                        const Text('No hikes yet.', style: TextStyle(color: Colors.white54, fontSize: 16)),
                        const Text('Go track your first adventure!', style: TextStyle(color: Colors.white38, fontSize: 14)),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    final route = _completedRoutes[index];
                    return _buildCompletedRouteCard(route);
                  },
                  childCount: _completedRoutes.length,
                ),
              ),

            // Отступ под нижнюю панель навигации
            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
    );
  }

  // Виджет глобальной статистики
  Widget _buildGlobalStat(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
      ],
    );
  }

  // Карточка одного пройденного маршрута
  Widget _buildCompletedRouteCard(Map<String, dynamic> route) {
    final double dist = (route['distanceKm'] as num).toDouble();

    return Container(
      margin: const EdgeInsets.only(left: 24, right: 24, bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          route['name'] ?? 'Unknown Route',
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)
                      ),
                      const SizedBox(height: 4),
                      Text(
                          _formatDate(route['date']),
                          style: const TextStyle(color: Colors.blueAccent, fontSize: 12, fontWeight: FontWeight.w600)
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle_rounded, color: Colors.blueAccent, size: 24),
                )
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _buildRouteMiniStat(Icons.route_rounded, '${dist.toStringAsFixed(2)} km'),
                const SizedBox(width: 24),
                _buildRouteMiniStat(Icons.timer_outlined, route['durationStr'] ?? '00:00:00'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteMiniStat(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.white54, size: 18),
        const SizedBox(width: 6),
        Text(value, style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }
}