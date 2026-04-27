// lib/features/community/presentation/community_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../tracking/providers/tracking_provider.dart';
import '../../../core/widgets/custom_header.dart';
import '../../../core/widgets/feed_post_card.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  @override
  Widget build(BuildContext context) {
    final tracker = Provider.of<TrackingProvider>(context);
    final posts = tracker.communityTracks;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          bottom: false,
          // Оборачиваем CustomScrollView в RefreshIndicator для свайпа "обновить"
          child: RefreshIndicator(
            color: const Color(0xFF32D74B),
            backgroundColor: Colors.black,
            onRefresh: () => tracker.fetchCommunityPosts(),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // --- 1. ПЛАВАЮЩАЯ ШАПКА И ПОИСК ---
                SliverAppBar(
                  backgroundColor: Colors.black,
                  floating: true, // Появляется при скролле вверх
                  snap: true, // Плавное доведение анимации
                  elevation: 0,
                  automaticallyImplyLeading: false,
                  titleSpacing: 0,
                  toolbarHeight: 80, // Единая высота шапки
                  title: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: CustomHeader(
                      title: 'COMMUNITY',
                      actions: [
                        GlassButton(
                            icon: Icons.add_rounded,
                            onTap: () {
                              HapticFeedback.lightImpact();
                              // Логика создания поста
                            }
                        )
                      ],
                    ),
                  ),
                  // КОМПАКТНЫЙ ПОИСК ПОЛЬЗОВАТЕЛЕЙ ПОД ШАПКОЙ
                  bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(60), // Высота блока под поиск
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                      child: Container(
                        height: 44, // Компактный размер
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: TextField(
                          style: const TextStyle(color: Colors.white, fontSize: 15),
                          decoration: const InputDecoration(
                            hintText: 'Search users...',
                            hintStyle: TextStyle(color: Colors.white54, fontSize: 15),
                            prefixIcon: Icon(Icons.search_rounded, color: Colors.white54, size: 22),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 12),
                          ),
                          onChanged: (val) {
                            // Логика поиска пользователей
                          },
                        ),
                      ),
                    ),
                  ),
                ),

                // --- 2. ЛЕНТА ПОСТОВ ---
                if (posts.isEmpty)
                  const SliverFillRemaining(
                    child: Center(child: Text("No posts yet.", style: TextStyle(color: Colors.white54))),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.only(bottom: 120), // Отступ для нижнего TabBar
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                            (context, index) => FeedPostCard(track: posts[index]),
                        childCount: posts.length,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}