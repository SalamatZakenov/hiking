// lib/features/routes/utils/gpx_parser.dart
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http; // Импортируем HTTP клиент
import '../data/models/route_model.dart';

class ParsedGpx {
  final List<LatLng> trackPoints;
  final List<WaypointData> waypoints;
  ParsedGpx({required this.trackPoints, required this.waypoints});
}

class GpxParser {
  // Теперь принимаем сетевой URL, а не путь к локальному ассету
  static Future<ParsedGpx?> loadRouteFromNetwork(String url) async {
    try {
      // 1. СКАЧИВАЕМ ФАЙЛ ПО ССЫЛКЕ ОТ БЭКЕНДА
      final response = await http.get(Uri.parse(url));

      if (response.statusCode != 200) {
        print("❌ Ошибка скачивания GPX. Статус: ${response.statusCode}");
        return null;
      }

      final String gpxString = response.body;

      // 2. Читаем линию (trackPoints)
      final List<LatLng> points = [];
      final RegExp trkRegExp = RegExp(r'<trkpt[^>]*lat="([^"]+)"[^>]*lon="([^"]+)"');
      for (final match in trkRegExp.allMatches(gpxString)) {
        final lat = double.tryParse(match.group(1) ?? '');
        final lon = double.tryParse(match.group(2) ?? '');
        if (lat != null && lon != null) points.add(LatLng(lat, lon));
      }

      final List<LatLng> optimizedPoints = [];
      for (int i = 0; i < points.length; i += 3) optimizedPoints.add(points[i]);

      // 3. Читаем метки (waypoints)
      final List<WaypointData> parsedWaypoints = [];
      final RegExp wptRegExp = RegExp(r'<wpt[^>]*lat="([^"]+)"[^>]*lon="([^"]+)">(.*?)</wpt>', dotAll: true);

      for (final match in wptRegExp.allMatches(gpxString)) {
        final lat = double.tryParse(match.group(1) ?? '');
        final lon = double.tryParse(match.group(2) ?? '');
        final innerXml = match.group(3) ?? '';

        final nameMatch = RegExp(r'<name>(.*?)</name>').firstMatch(innerXml);
        final name = nameMatch?.group(1) ?? 'Метка';

        String photoUrl = 'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?w=500';
        if (name.toLowerCase().contains('picnic') || name.toLowerCase().contains('пикник')) photoUrl = 'https://images.unsplash.com/photo-1596484552993-9c8491c7c216?w=500';
        if (name.toLowerCase().contains('swing') || name.toLowerCase().contains('качели')) photoUrl = 'https://images.unsplash.com/photo-1520085189392-5b945c269b56?w=500';
        if (name.toLowerCase().contains('barrier') || name.toLowerCase().contains('шлагбаум') || name.toLowerCase().contains('turn')) photoUrl = 'https://images.unsplash.com/photo-1453873531674-2151bcd01707?w=500';

        if (lat != null && lon != null) {
          parsedWaypoints.add(WaypointData(location: LatLng(lat, lon), name: name, imageUrl: photoUrl));
        }
      }

      print("✅ УСПЕХ! GPX загружен из сети: $url");
      return ParsedGpx(trackPoints: optimizedPoints, waypoints: parsedWaypoints);

    } catch (e) {
      print("❌ ОШИБКА GPX (Network): $e");
      return null;
    }
  }
}