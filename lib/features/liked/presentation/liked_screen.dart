// lib/features/liked/presentation/liked_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';

class LikedScreen extends StatefulWidget {
  const LikedScreen({super.key});

  @override
  State<LikedScreen> createState() => _LikedScreenState();
}

class _LikedScreenState extends State<LikedScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Фейковые данные для вкладки "Активность"
  final List<Map<String, dynamic>> _activities = [
    {
      'type': 'like',
      'userName': 'Arman',
      'userImage': 'https://i.pravatar.cc/150?img=11',
      'timeAgo': '10m',
      'target': 'liked your post.',
      'postImage': 'https://images.unsplash.com/photo-1522163182402-834f871fd851?w=100&q=80'
    },
    {
      'type': 'follow',
      'userName': 'Madina',
      'userImage': 'https://i.pravatar.cc/150?img=5',
      'timeAgo': '2h',
      'target': 'started following you.',
      'postImage': null
    },
    {
      'type': 'comment',
      'userName': 'Sergey',
      'userImage': 'https://i.pravatar.cc/150?img=60',
      'timeAgo': '5h',
      'target': 'commented: "Wow, what a view! 😍"',
      'postImage': 'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=100&q=80'
    },
    {
      'type': 'like',
      'userName': 'Aruzhan',
      'userImage': 'https://i.pravatar.cc/150?img=44',
      'timeAgo': '1d',
      'target': 'liked your completed route.',
      'postImage': null
    },
  ];

  // Фейковые данные для вкладки "Сохраненные маршруты"
  final List<Map<String, dynamic>> _savedRoutes = [
    {
      'name': 'Пик Советов',
      'location': 'Большое Алматинское ущелье',
      'difficulty': 'MEDIUM',
      'distance': '16.4 km',
      'elevation': '4,317 m',
      'image': 'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?auto=format&fit=crop&w=500&q=60'
    },
    {
      'name': 'Кок-Жайляу',
      'location': 'Алматы, Медеу',
      'difficulty': 'EASY',
      'distance': '8.2 km',
      'elevation': '2,200 m',
      'image': 'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?auto=format&fit=crop&w=500&q=60'
    },
  ];

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

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppTheme.bgDark,
        appBar: AppBar(
          backgroundColor: AppTheme.bgDark,
          elevation: 0,
          title: const Text('Activity', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          centerTitle: false,
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.blueAccent,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white54,
            labelStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            tabs: const [
              Tab(text: 'Interactions'),
              Tab(text: 'Saved Routes'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildActivityTab(),
            _buildSavedRoutesTab(),
          ],
        ),
      ),
    );
  }

  // --- Вкладка 1: ВЗАИМОДЕЙСТВИЯ (Лайки, комменты, подписки) ---
  Widget _buildActivityTab() {
    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(top: 16, bottom: 100), // bottom 100 для отступа от навбара
      itemCount: _activities.length,
      separatorBuilder: (context, index) => Divider(color: Colors.white.withOpacity(0.05), height: 1),
      itemBuilder: (context, index) {
        final item = _activities[index];
        IconData actionIcon;
        Color actionColor;

        if (item['type'] == 'like') {
          actionIcon = Icons.favorite_rounded;
          actionColor = const Color(0xFFFF453A);
        } else if (item['type'] == 'comment') {
          actionIcon = Icons.chat_bubble_rounded;
          actionColor = Colors.blueAccent;
        } else {
          actionIcon = Icons.person_add_rounded;
          actionColor = const Color(0xFF32D74B);
        }

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          leading: Stack(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundImage: NetworkImage(item['userImage']),
              ),
              Positioned(
                bottom: 0, right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: actionColor, shape: BoxShape.circle, border: Border.all(color: AppTheme.bgDark, width: 2)),
                  child: Icon(actionIcon, color: Colors.white, size: 10),
                ),
              ),
            ],
          ),
          title: RichText(
            text: TextSpan(
              style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
              children: [
                TextSpan(text: '${item['userName']} ', style: const TextStyle(fontWeight: FontWeight.bold)),
                TextSpan(text: item['target']),
              ],
            ),
          ),
          subtitle: Text(item['timeAgo'], style: const TextStyle(color: Colors.white38, fontSize: 12)),
          trailing: item['postImage'] != null
              ? ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(item['postImage'], width: 44, height: 44, fit: BoxFit.cover),
          )
              : (item['type'] == 'follow'
              ? FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.15),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              minimumSize: const Size(0, 32),
            ),
            onPressed: () {},
            child: const Text('Follow back', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          )
              : const SizedBox.shrink()),
        );
      },
    );
  }

  // --- Вкладка 2: СОХРАНЕННЫЕ МАРШРУТЫ ---
  Widget _buildSavedRoutesTab() {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(top: 16, bottom: 100),
      itemCount: _savedRoutes.length,
      itemBuilder: (context, index) {
        final route = _savedRoutes[index];
        return Container(
          margin: const EdgeInsets.only(left: 24, right: 24, bottom: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white10),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), bottomLeft: Radius.circular(20)),
                child: Image.network(route['image'], width: 100, height: 120, fit: BoxFit.cover),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text(route['name'], style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))),
                          const Icon(Icons.bookmark_rounded, color: Colors.blueAccent, size: 20),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(route['location'], style: const TextStyle(color: Colors.white54, fontSize: 12)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.route_rounded, color: AppTheme.cardSlate, size: 14),
                          const SizedBox(width: 4),
                          Text(route['distance'], style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                          const SizedBox(width: 12),
                          _buildDifficultyBadge(route['difficulty']),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: badgeColor.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
      child: Text(difficulty.toUpperCase(), style: TextStyle(color: badgeColor, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}