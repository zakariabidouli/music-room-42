import 'dart:convert';
import 'package:http/http.dart' as http;
import 'config.dart';

// Every call sends X-Platform/X-Device/X-App-Version (subject V.6 logging).
class Api {
  final String token;
  Api(this.token);
  Map<String, String> get headers => {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'X-Platform': AppConfig.platform,
        'X-Device': AppConfig.device,
        'X-App-Version': AppConfig.appVersion,
      };
  Uri u(String p, [Map<String, String>? q]) =>
      Uri.parse('${AppConfig.backendUrl}$p').replace(queryParameters: q);

  Future<dynamic> vote(String suggestionId, {double? lat, double? lon}) async {
    final r = await http.post(u('/api/v1/suggestions/$suggestionId/vote', {
      if (lat != null) 'lat': '$lat',
      if (lon != null) 'lon': '$lon',
    }), headers: headers);
    if (r.statusCode == 409) throw Exception('Already voted / stale');
    if (r.statusCode == 403) throw Exception('License/geofence denied');
    return jsonDecode(r.body);
  }

  Future<dynamic> reorder(String playlistId, List<String> orderedIds, int version) async {
    final r = await http.patch(u('/api/v1/playlists/$playlistId/reorder'),
        headers: headers, body: jsonEncode({'orderedIds': orderedIds, 'version': version}));
    if (r.statusCode == 409) throw Exception('Stale version: reload order');
    return jsonDecode(r.body);
  }

  Future<dynamic> search(String q) async {
    final r = await http.get(u('/api/v1/music/search', {'q': q}), headers: headers);
    return jsonDecode(r.body);
  }
}
