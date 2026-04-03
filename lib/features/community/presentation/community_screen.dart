// lib/features/community/presentation/community_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  // Фейковые данные для статусов/историй
  final List<Map<String, String>> _stories = [
    {'name': 'Arman', 'image': 'https://i.pravatar.cc/150?img=11'},
    {'name': 'Madina', 'image': 'https://i.pravatar.cc/150?img=5'},
    {'name': 'Sergey', 'image': 'https://i.pravatar.cc/150?img=60'},
    {'name': 'Aruzhan', 'image': 'https://i.pravatar.cc/150?img=44'},
    {'name': 'Denis', 'image': 'https://i.pravatar.cc/150?img=50'},
  ];

  // Фейковые данные для ленты
  final List<Map<String, dynamic>> _posts = [
    {
      'userName': 'Arman',
      'userImage': 'https://i.pravatar.cc/150?img=11',
      'location': 'Пик Нурсултан',
      'timeAgo': '2 hours ago',
      'postImage': 'https://images.unsplash.com/photo-1522163182402-834f871fd851?auto=format&fit=crop&w=1000&q=80',
      'caption': 'It was a tough climb, but the view from the top is absolutely worth every step! 🏔️✨',
      'distance': '12.4 km',
      'elevation': '1,450 m',
      'likes': 142,
      'comments': 18,
    },
    {
      'userName': 'Madina',
      'userImage': 'https://i.pravatar.cc/150?img=5',
      'location': 'Кок-Жайляу',
      'timeAgo': '5 hours ago',
      'postImage': 'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?auto=format&fit=crop&w=1000&q=80',
      'caption': 'Easy sunday hike with friends. The weather was perfect! ☀️🌲',
      'distance': '8.2 km',
      'elevation': '600 m',
      'likes': 89,
      'comments': 4,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppTheme.bgDark,
        appBar: AppBar(
          backgroundColor: AppTheme.bgDark,
          elevation: 0,
          title: const Text('Community', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          centerTitle: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.search_rounded, color: Colors.white),
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.add_box_outlined, color: Colors.white),
              onPressed: () {},
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: RefreshIndicator(
          color: Colors.blueAccent,
          backgroundColor: const Color(0xFF1E1E1E),
          onRefresh: () async {
            await Future.delayed(const Duration(seconds: 1)); // Имитация загрузки
          },
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            slivers: [
              // --- БЛОК ИСТОРИЙ (СТАТУСОВ) ---
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 110,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _stories.length + 1, // +1 для кнопки "Мой статус"
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return _buildAddStoryBtn();
                      }
                      final story = _stories[index - 1];
                      return _buildStoryItem(story['name']!, story['image']!);
                    },
                  ),
                ),
              ),

              // Разделитель
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Divider(color: Colors.white.withOpacity(0.05), thickness: 1),
                ),
              ),

              // --- ЛЕНТА ПОСТОВ ---
              SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    final post = _posts[index];
                    return _buildPostCard(post);
                  },
                  childCount: _posts.length,
                ),
              ),

              // Отступ снизу для нижней панели навигации
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
    );
  }

  // --- КОМПОНЕНТ: КНОПКА "ДОБАВИТЬ СТАТУС" ---
  Widget _buildAddStoryBtn() {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            children: [
              Container(
                width: 70, height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF2C2C2E),
                  border: Border.all(color: Colors.white10, width: 2),
                ),
                child: ClipOval(
                  child: Image.network('https://i.pravatar.cc/150?img=32', fit: BoxFit.cover),
                ),
              ),
              Positioned(
                bottom: 0, right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: Colors.blueAccent, shape: BoxShape.circle),
                  child: const Icon(Icons.add, color: Colors.white, size: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text('Your Story', style: TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }

  // --- КОМПОНЕНТ: ИСТОРИЯ ДРУГА ---
  Widget _buildStoryItem(String name, String imageUrl) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 70, height: 70,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF32D74B), Colors.blueAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Container(
              decoration: const BoxDecoration(shape: BoxShape.circle, color: AppTheme.bgDark),
              padding: const EdgeInsets.all(2),
              child: ClipOval(
                child: Image.network(imageUrl, fit: BoxFit.cover),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(name, style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }

  // --- КОМПОНЕНТ: КАРТОЧКА ПОСТА ---
  Widget _buildPostCard(Map<String, dynamic> post) {
    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Шапка поста (Аватар + Имя + Локация)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(backgroundImage: NetworkImage(post['userImage']), radius: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(post['userName'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(post['location'], style: const TextStyle(color: Colors.blueAccent, fontSize: 12, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                IconButton(icon: const Icon(Icons.more_horiz, color: Colors.white54), onPressed: () {}),
              ],
            ),
          ),

          // Фотография поста
          Image.network(
            post['postImage'],
            width: double.infinity,
            height: 300,
            fit: BoxFit.cover,
          ),

          // Спортивная статистика (Дистанция / Высота)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(color: Colors.black.withOpacity(0.2)),
            child: Row(
              children: [
                const Icon(Icons.route_outlined, color: Colors.white70, size: 20),
                const SizedBox(width: 6),
                Text(post['distance'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                const SizedBox(width: 24),
                const Icon(Icons.height_rounded, color: Colors.white70, size: 20),
                const SizedBox(width: 6),
                Text(post['elevation'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              ],
            ),
          ),

          // Кнопки лайков/комментариев
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.favorite_border_rounded, color: Colors.white, size: 28),
                const SizedBox(width: 8),
                Text('${post['likes']}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(width: 24),
                const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white, size: 26),
                const SizedBox(width: 8),
                Text('${post['comments']}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                const Spacer(),
                const Icon(Icons.bookmark_border_rounded, color: Colors.white, size: 28),
              ],
            ),
          ),

          // Текст поста
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 20),
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
                children: [
                  TextSpan(text: '${post['userName']} ', style: const TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: post['caption']),
                ],
              ),
            ),
          ),

          // Время назад
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 20),
            child: Text(post['timeAgo'], style: const TextStyle(color: Colors.white38, fontSize: 12)),
          )
        ],
      ),
    );
  }
}