import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import 'comments_sheet.dart';

import '../../tracking/providers/tracking_provider.dart';
import '../../tracking/data/models/local_track.dart';
import '../../profile/presentation/track_detail_screen.dart';

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

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Community', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24)),
      ),
      body: RefreshIndicator(
        onRefresh: () => tracker.fetchCommunityPosts(),
        child: posts.isEmpty
            ? const Center(child: Text("No posts yet. Start hiking!", style: TextStyle(color: Colors.white54)))
            : ListView.builder(
          itemCount: posts.length,
          itemBuilder: (context, index) => _buildFeedPost(context, posts[index]),
        ),
      ),
    );
  }

  Widget _buildFeedPost(BuildContext context, LocalTrack track) {
    final dateStr = "${track.date.day.toString().padLeft(2, '0')}.${track.date.month.toString().padLeft(2, '0')}.${track.date.year}";
    final String realUserName = track.username.isNotEmpty ? track.username : 'User';

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05)), bottom: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                CircleAvatar(
                    backgroundColor: const Color(0xFF32D74B).withOpacity(0.2),
                    child: Text(realUserName[0].toUpperCase(), style: const TextStyle(color: Color(0xFF32D74B), fontWeight: FontWeight.bold))
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(realUserName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('$dateStr • ${track.activityType}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(track.name, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 16),
          _PostCarousel(track: track),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Provider.of<TrackingProvider>(context, listen: false).toggleLike(track.id),
                  child: Icon(
                      track.likedByMe ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      color: track.likedByMe ? Colors.redAccent : Colors.white, size: 28),
                ),
                const SizedBox(width: 8),
                Text('${track.likeCount}', style: const TextStyle(color: Colors.white, fontSize: 14)),
                const SizedBox(width: 24),
                GestureDetector(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => CommentsSheet(trackId: track.id),
                    );
                  },
                  child: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white, size: 26),
                ),
                const SizedBox(width: 8),
                Text('${track.commentCount}', style: const TextStyle(color: Colors.white, fontSize: 14)),
                const Spacer(),
                if (track.imageUrls.isNotEmpty)
                  const Icon(Icons.photo_library_outlined, color: Colors.white54, size: 20),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class _PostCarousel extends StatefulWidget {
  final LocalTrack track;
  const _PostCarousel({required this.track});
  @override
  State<_PostCarousel> createState() => _PostCarouselState();
}

class _PostCarouselState extends State<_PostCarousel> {
  int _currentIndex = 0;
  @override
  Widget build(BuildContext context) {
    final pages = [
      GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => TrackDetailScreen(track: widget.track))),
          child: _FeedMapWidget(track: widget.track)
      ),
      ...widget.track.imageUrls.map((url) => Image.network(url, fit: BoxFit.cover))
    ];

    return SizedBox(
      height: 300,
      child: Stack(
        children: [
          PageView(
            onPageChanged: (i) => setState(() => _currentIndex = i),
            children: pages,
          ),
          if (pages.length > 1)
            Positioned(
              bottom: 10, left: 0, right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(pages.length, (i) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: _currentIndex == i ? 12 : 6, height: 6,
                  decoration: BoxDecoration(color: _currentIndex == i ? const Color(0xFF32D74B) : Colors.white54, borderRadius: BorderRadius.circular(3)),
                )),
              ),
            )
        ],
      ),
    );
  }
}

class _FeedMapWidget extends StatefulWidget {
  final LocalTrack track;
  const _FeedMapWidget({required this.track});
  @override
  State<_FeedMapWidget> createState() => _FeedMapWidgetState();
}

class _FeedMapWidgetState extends State<_FeedMapWidget> {
  List<LatLng> points = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      String xmlString = "";
      if (widget.track.gpxFilePath.startsWith('http')) {
        final response = await Dio().get(widget.track.gpxFilePath);
        xmlString = response.data.toString();
      } else {
        final file = File(widget.track.gpxFilePath);
        if (await file.exists()) {
          xmlString = await file.readAsString();
        }
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
      print('Ошибка загрузки GPX в сообществе: $e');
    }
  }

  Widget _buildMapMarker(Color color, IconData icon) {
    return Container(
      decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
      child: Icon(icon, color: Colors.white, size: 15),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) return Container(color: Colors.white.withOpacity(0.05), child: const Center(child: CircularProgressIndicator(color: Color(0xFF32D74B))));

    LatLngBounds? bounds;
    if (points.length > 1) bounds = LatLngBounds.fromPoints(points);

    return AbsorbPointer(
      child: FlutterMap(
        options: MapOptions(
          initialCameraFit: bounds != null ? CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(20), maxZoom: 16) : null,
          initialCenter: bounds == null && points.isNotEmpty ? points.first : const LatLng(43.2220, 76.8512),
        ),
        children: [
          TileLayer(urlTemplate: 'https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png', subdomains: const ['a','b','c'], userAgentPackageName: 'com.salamat.hiking_app'),
          if (points.isNotEmpty)
            PolylineLayer(polylines: [Polyline(points: points, color: const Color(0xFF007AFF), strokeWidth: 5, strokeCap: StrokeCap.round, strokeJoin: StrokeJoin.round)]),
          if (points.isNotEmpty)
            MarkerLayer(markers: [
              Marker(point: points.first, width: 30, height: 30, child: _buildMapMarker(const Color(0xFF32D74B), Icons.play_arrow_rounded)),
              Marker(point: points.last, width: 30, height: 30, child: _buildMapMarker(Colors.redAccent, Icons.flag_rounded)),
            ]),
        ],
      ),
    );
  }
}