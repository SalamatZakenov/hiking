// lib/features/routes/presentation/routes_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:geolocator/geolocator.dart'; // Для получения локации
import 'package:latlong2/latlong.dart';      // Для работы с координатами

import '../../auth/providers/auth_provider.dart';
import '../providers/route_provider.dart';
import '../data/models/route_model.dart';
import '../../../core/widgets/custom_header.dart';
import '../../../core/theme/app_theme.dart';

class RoutesScreen extends StatefulWidget {
  const RoutesScreen({super.key});

  @override
  State<RoutesScreen> createState() => _RoutesScreenState();
}

class _RoutesScreenState extends State<RoutesScreen> {
  LatLng? _userLocation;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  // Метод для получения локации пользователя при открытии экрана
  Future<void> _initLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      if (mounted) {
        setState(() {
          _userLocation = LatLng(position.latitude, position.longitude);
        });
      }
    } catch (e) {
      debugPrint("Не удалось получить локацию: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final routeProvider = Provider.of<RouteProvider>(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppTheme.bgDark,
        body: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            color: const Color(0xFFFFFFFF),
            backgroundColor: AppTheme.bgDark,
            onRefresh: () => routeProvider.fetchRoutes(),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverAppBar(
                  backgroundColor: AppTheme.bgDark,
                  floating: true,
                  snap: true,
                  elevation: 0,
                  automaticallyImplyLeading: false,
                  titleSpacing: 0,
                  toolbarHeight: 80, // ЕДИНАЯ ВЫСОТА
                  title: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24), // ЕДИНЫЙ ОТСТУП
                    child: CustomHeader(title: 'ROUTES'),
                  ),
                  // КОМПАКТНЫЙ ПОИСК + ФИЛЬТР
                  bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(60), // Высота как в Community
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 44, // Компактный размер
                              decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(16)
                              ),
                              child: TextField(
                                style: const TextStyle(color: Colors.white, fontSize: 15),
                                decoration: const InputDecoration(
                                  hintText: 'Search routes...',
                                  hintStyle: TextStyle(color: Colors.white54, fontSize: 15),
                                  prefixIcon: Icon(Icons.search_rounded, color: Colors.white54, size: 22),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                                ),
                                onChanged: (val) => routeProvider.searchRoutes(val),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // КНОПКА ФИЛЬТРА (тоже 44x44)
                          Container(
                            height: 44,
                            width: 44,
                            decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(16)
                            ),
                            child: IconButton(
                                icon: const Icon(Icons.tune_rounded, color: Colors.white, size: 20),
                                onPressed: () { HapticFeedback.lightImpact(); }
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
                if (routeProvider.isLoading)
                  const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: Color(0xFF32D74B))))
                else if (routeProvider.filteredRoutes.isEmpty)
                  const SliverFillRemaining(child: Center(child: Text('No routes found.', style: TextStyle(color: Colors.white54))))
                else
                  SliverPadding(
                    padding: const EdgeInsets.only(left: 16, right: 16, bottom: 120),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                            (context, index) {
                          final route = routeProvider.filteredRoutes[index];
                          return _buildPremiumRouteCard(context, route);
                        },
                        childCount: routeProvider.filteredRoutes.length,
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

  // --- ОБНОВЛЕННАЯ КАРТОЧКА С ДИНАМИЧЕСКОЙ ДИСТАНЦИЕЙ ---
  Widget _buildPremiumRouteCard(BuildContext context, RouteModel route) {
    String distanceStr = '-- KM';

    // РАСЧЕТ ДИСТАНЦИИ ДО ПИКА
    if (_userLocation != null) {
      // Пытаемся взять самую последнюю точку трека (Пик), если она уже загружена.
      // Если нет - берем базовые координаты маршрута (они тоже обычно указывают на пик)
      double targetLat = route.trackPoints.isNotEmpty ? route.trackPoints.last.latitude : route.latitude;
      double targetLon = route.trackPoints.isNotEmpty ? route.trackPoints.last.longitude : route.longitude;

      if (targetLat != 0.0 && targetLon != 0.0) {
        double distanceInMeters = Geolocator.distanceBetween(
          _userLocation!.latitude,
          _userLocation!.longitude,
          targetLat,
          targetLon,
        );
        distanceStr = '${(distanceInMeters / 1000).toStringAsFixed(1)} KM';
      } else if (route.calculatedDistance != null) {
        // Резервный вариант, если пик почему-то 0.0
        distanceStr = '${route.calculatedDistance!.toStringAsFixed(1)} KM';
      }
    } else if (route.calculatedDistance != null) {
      // Резервный вариант, пока локация пользователя загружается
      distanceStr = '${route.calculatedDistance!.toStringAsFixed(1)} KM';
    }

    return GestureDetector(
      onTap: () => context.push('/routes/${route.id}'),
      child: Container(
        height: 280,
        margin: const EdgeInsets.only(bottom: 24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. КАРТИНКА (ФОН)
            ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: CachedNetworkImage(
                imageUrl: route.imageUrls.isNotEmpty ? route.imageUrls.first : 'https://via.placeholder.com/600x400',
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.white.withOpacity(0.05),
                  child: const Center(child: CircularProgressIndicator(color: Color(0xFF32D74B))),
                ),
              ),
            ),

            // 2. СЛОЖНОСТЬ (СВЕРХУ СЛЕВА)
            Positioned(
              top: 16, left: 16,
              child: _buildDifficultyBadge(route.difficulty),
            ),

            // 3. НИЖНЯЯ ПАНЕЛЬ: ULTRA-GLASS (КОМПАКТНАЯ)
            Positioned(
              bottom: 12, left: 12, right: 12,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withOpacity(0.15)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // ЛОКАЦИЯ (Верхняя строчка)
                        Text(
                          route.location.toUpperCase(),
                          style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2
                          ),
                          maxLines: 1,
                        ),
                        const SizedBox(height: 4),

                        // НАЗВАНИЕ + ДИНАМИЧЕСКАЯ ДИСТАНЦИЯ (В одну строку)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Text(
                                route.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.5,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 12),
                            // ДИСТАНЦИЯ ТЕПЕРЬ ПОКАЗЫВАЕТ КМ ОТ ТЕБЯ ДО ПИКА
                            Text(
                              distanceStr,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Стили бейджиков сложности
  Widget _buildDifficultyBadge(String difficulty) {
    Color bgColor;
    Color textColor;

    switch (difficulty.toUpperCase()) {
      case 'HARD':
        bgColor = const Color(0xFFFFEDD6);
        textColor = const Color(0xFF93000A);
        break;
      case 'EASY':
        bgColor = const Color(0xFFD6FFD7);
        textColor = const Color(0xFF00930A);
        break;
      case 'MEDIUM':
        bgColor = const Color(0xFFF9FFD6);
        textColor = const Color(0xFF937600);
        break;
      default:
        bgColor = Colors.white.withOpacity(0.1);
        textColor = Colors.white;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        difficulty.toUpperCase(),
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}