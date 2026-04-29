import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../tracking/providers/tracking_provider.dart';
import '../../../core/widgets/custom_header.dart';
import '../../../core/theme/app_theme.dart';


class LikedScreen extends StatefulWidget {
  const LikedScreen({super.key});

  @override
  State<LikedScreen> createState() => _LikedScreenState();
}

class _LikedScreenState extends State<LikedScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Метод, который генерирует ленту активности на лету из доступных данных
  List<Map<String, dynamic>> _generateActivities(TrackingProvider tracker) {
    List<Map<String, dynamic>> activities = [];

    // 1. Активность на ТВОИХ постах (Лайки и Комменты от других)
    for (var track in tracker.savedTracks) {
      if (track.likeCount > 0) {
        activities.add({
          'icon': Icons.favorite_rounded,
          'color': Colors.redAccent,
          'title': 'People liked your route',
          'subtitle': 'Your route "${track.name}" has ${track.likeCount} likes.',
          'date': track.date, // Используем дату поста для сортировки
        });
      }
      if (track.commentCount > 0) {
        activities.add({
          'icon': Icons.chat_bubble_rounded,
          'color': const Color(0xFF007AFF),
          'title': 'New comments',
          'subtitle': 'Your route "${track.name}" has ${track.commentCount} comments.',
          'date': track.date,
        });
      }
    }

    // 2. ТВОИ действия (Посты, которые ты лайкнул в ленте)
    for (var track in tracker.communityTracks) {
      // Исключаем свои же посты из этого списка, чтобы не дублировать
      bool isMyOwnPost = tracker.savedTracks.any((myTrack) => myTrack.id == track.id);

      if (track.likedByMe && !isMyOwnPost) {
        activities.add({
          'icon': Icons.favorite_border_rounded,
          'color': const Color(0xFF32D74B),
          'title': 'You liked a route',
          'subtitle': 'You liked ${track.username}\'s route "${track.name}".',
          'date': track.date,
        });
      }
    }

    // Сортируем активность от новых к старым
    activities.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));

    return activities;
  }

  @override
  Widget build(BuildContext context) {
    final tracker = Provider.of<TrackingProvider>(context);
    final activities = _generateActivities(tracker);

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        toolbarHeight: 80, // ЕДИНАЯ ВЫСОТА
        titleSpacing: 0,
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24), // ЕДИНЫЙ ОТСТУП
          child: CustomHeader(title: 'ACTIVITY'),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF00E5FF),
          labelColor: const Color(0xFF00E5FF),
          unselectedLabelColor: Colors.white54,
          dividerColor: Colors.transparent,
          tabs: const [
            Tab(text: 'Notifications'),
            Tab(text: 'Saved routes'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildActivityTab(activities),
          const Center(child: Text("No saved routes yet.", style: TextStyle(color: Colors.white54))),
        ],
      ),
    );
  }

  Widget _buildActivityTab(List<Map<String, dynamic>> activities) {
    if (activities.isEmpty) {
      return const Center(
        child: Text("No recent activity.", style: TextStyle(color: Colors.white54)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: activities.length,
      itemBuilder: (context, index) {
        final activity = activities[index];
        final date = activity['date'] as DateTime;
        final dateStr = "${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}";

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: activity['color'].withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(activity['icon'], color: activity['color'], size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(activity['title'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                        Text(dateStr, style: const TextStyle(color: Colors.white38, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(activity['subtitle'], style: const TextStyle(color: Colors.white70, fontSize: 14)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}