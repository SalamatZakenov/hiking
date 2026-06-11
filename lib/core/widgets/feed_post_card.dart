// lib/core/widgets/feed_post_card.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../features/tracking/providers/tracking_provider.dart';
import '../../features/tracking/data/models/local_track.dart';
import '../../features/community/presentation/comments_sheet.dart';
import '../../features/profile/presentation/track_detail_screen.dart';

class FeedPostCard extends StatelessWidget {
  final LocalTrack track;

  const FeedPostCard({super.key, required this.track});

  @override
  Widget build(BuildContext context) {
    final dateStr = "${track.date.day.toString().padLeft(2, '0')}.${track.date.month.toString().padLeft(2, '0')}.${track.date.year}";
    final String realUserName = track.username.isNotEmpty ? track.username : 'Explorer';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFF00E5FF).withOpacity(0.2), // Изменен цвет
                  child: Text(
                    realUserName[0].toUpperCase(),
                    style: const TextStyle(color: Color(0xFF00E5FF), fontWeight: FontWeight.bold), // Изменен цвет
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        realUserName,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        '$dateStr • ${track.activityType}',
                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_horiz, color: Colors.white54),
                  color: const Color(0xFF2C2C2E),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  onSelected: (value) {
                    HapticFeedback.lightImpact();
                  },
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: 'share',
                      child: Row(
                        children: [
                          Icon(Icons.share_rounded, color: Colors.white, size: 20),
                          SizedBox(width: 12),
                          Text('Share', style: TextStyle(color: Colors.white, fontSize: 16)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              track.name,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.2
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: _PostContentBlock(track: track),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => CommentsSheet(trackId: track.id),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white70, size: 20),
                        const SizedBox(width: 6),
                        Text('${track.commentCount}', style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Provider.of<TrackingProvider>(context, listen: false).toggleLike(track.id);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          track.likedByMe ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          color: track.likedByMe ? const Color(0xFFFF453A) : Colors.white70,
                          size: 20,
                        ),
                        const SizedBox(width: 6),
                        Text('${track.likeCount}', style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PostContentBlock extends StatefulWidget {
  final LocalTrack track;
  const _PostContentBlock({required this.track});
  @override
  State<_PostContentBlock> createState() => _PostContentBlockState();
}

class _PostContentBlockState extends State<_PostContentBlock> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final imageUrls = widget.track.imageUrls;

    if (imageUrls.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: SizedBox(
          height: 250,
          width: double.infinity,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                _MiniMapWidget(track: widget.track),
                Positioned.fill(
                  child: GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => TrackDetailScreen(track: widget.track))),
                    child: Container(color: Colors.transparent),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        height: 250,
        width: double.infinity,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              PageView.builder(
                itemCount: imageUrls.length,
                onPageChanged: (i) => setState(() => _currentIndex = i),
                itemBuilder: (context, index) {
                  return CachedNetworkImage(
                    imageUrl: imageUrls[index],
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(color: Colors.white.withOpacity(0.05), child: const Center(child: CircularProgressIndicator(color: Color(0xFF00E5FF)))), // Изменен цвет
                  );
                },
              ),

              Positioned(
                bottom: 12, right: 12,
                child: GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => TrackDetailScreen(track: widget.track))),
                  child: Container(
                    width: 90, height: 90,
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))]
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: _MiniMapWidget(track: widget.track),
                    ),
                  ),
                ),
              ),

              if (imageUrls.length > 1)
                Positioned(
                  bottom: 16, left: 0, right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(imageUrls.length, (i) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentIndex == i ? 10 : 6, height: 6,
                      decoration: BoxDecoration(
                          color: _currentIndex == i ? Colors.white : Colors.white.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(3)
                      ),
                    )),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniMapWidget extends StatefulWidget {
  final LocalTrack track;
  const _MiniMapWidget({required this.track});
  @override
  State<_MiniMapWidget> createState() => _MiniMapWidgetState();
}

class _MiniMapWidgetState extends State<_MiniMapWidget> {
  List<LatLng> points = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      String xmlString = "";
      // Понимаем локальные файлы assets/gpx/...
      if (widget.track.gpxFilePath.startsWith('assets/')) {
        xmlString = await rootBundle.loadString(widget.track.gpxFilePath);
      }
      else if (widget.track.gpxFilePath.startsWith('http')) {
        final response = await Dio().get(widget.track.gpxFilePath);
        xmlString = response.data.toString();
      } else {
        final file = File(widget.track.gpxFilePath);
        if (await file.exists()) xmlString = await file.readAsString();
      }

      if (xmlString.isNotEmpty) {
        final RegExp regExp = RegExp(r'<trkpt lat="([^"]+)" lon="([^"]+)".*?>');
        final matches = regExp.allMatches(xmlString);
        if (mounted) {
          setState(() {
            points = matches.map((m) => LatLng(double.parse(m.group(1)!), double.parse(m.group(2)!))).toList();
          });
        }
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) return Container(color: const Color(0xFFF0F0F0), child: const Center(child: CircularProgressIndicator(color: Color(0xFF00E5FF), strokeWidth: 2))); // Изменен цвет
    LatLngBounds? bounds;
    if (points.length > 1) bounds = LatLngBounds.fromPoints(points);

    return AbsorbPointer(
      child: FlutterMap(
        options: MapOptions(
          initialCameraFit: bounds != null ? CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(12), maxZoom: 15) : null,
          initialCenter: bounds == null && points.isNotEmpty ? points.first : const LatLng(43.2220, 76.8512),
        ),
        children: [
          TileLayer(urlTemplate: 'https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png', subdomains: const ['a','b','c'], userAgentPackageName: 'com.salamat.hiking_app'),
          if (points.isNotEmpty) PolylineLayer(polylines: [Polyline(points: points, color: const Color(0xFF00E5FF), strokeWidth: 4, strokeCap: StrokeCap.round, strokeJoin: StrokeJoin.round)]), // Изменен цвет
        ],
      ),
    );
  }
}