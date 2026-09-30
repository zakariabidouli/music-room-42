import 'dart:convert';
import 'package:http/http.dart' as http;
import 'config.dart';

// Every call sends X-Platform/X-Device/X-App-Version (subject V.6 logging).
// Auth: Bearer token + X-User-Id (local backend accepts X-User-Id, prod
// verifies Supabase JWT — see backend/src/lib.ts).
class ApiException implements Exception {
  final int status;
  final String message;
  final dynamic body;
  ApiException(this.status, this.message, [this.body]);
  @override
  String toString() => message;
}

class Api {
  final String token;
  Api(this.token);

  Map<String, String> get headers => {
        'Authorization': 'Bearer $token',
        'X-User-Id': token,
        'Content-Type': 'application/json',
        'X-Platform': AppConfig.platform,
        'X-Device': AppConfig.device,
        'X-App-Version': AppConfig.appVersion,
      };

  Uri u(String p, [Map<String, String>? q]) =>
      Uri.parse('${AppConfig.backendUrl}$p').replace(queryParameters: q);

  dynamic _decode(http.Response r) {
    dynamic body;
    try {
      body = r.body.isEmpty ? null : jsonDecode(r.body);
    } catch (_) {
      body = r.body;
    }
    if (r.statusCode >= 400) {
      final msg = (body is Map && body['error'] is Map)
          ? '${body['error']['message']}'
          : 'Request failed (${r.statusCode})';
      throw ApiException(r.statusCode, msg, body);
    }
    return body;
  }

  Future<dynamic> _get(String p, [Map<String, String>? q]) async =>
      _decode(await http.get(u(p, q), headers: headers));

  Future<dynamic> _post(String p, Map<String, dynamic> b) async =>
      _decode(await http.post(u(p), headers: headers, body: jsonEncode(b)));

  Future<dynamic> _patch(String p, Map<String, dynamic> b) async =>
      _decode(await http.patch(u(p), headers: headers, body: jsonEncode(b)));

  Future<dynamic> _put(String p, Map<String, dynamic> b) async =>
      _decode(await http.put(u(p), headers: headers, body: jsonEncode(b)));

  // ---- Profile (V.1) ----
  Future<dynamic> getProfile() => _get('/api/v1/profile');
  Future<dynamic> updateProfile(Map<String, dynamic> b) =>
      _put('/api/v1/profile', b);

  // ---- Events / vote queue (V.2.1) ----
  Future<dynamic> listEvents() => _get('/api/v1/events');
  Future<dynamic> createEvent(Map<String, dynamic> b) =>
      _post('/api/v1/events', b);
  Future<dynamic> suggest(String eventId, Map<String, dynamic> b) =>
      _post('/api/v1/events/$eventId/suggest', b);
  Future<dynamic> queue(String eventId) =>
      _get('/api/v1/events/$eventId/queue');

  Future<dynamic> vote(String suggestionId,
      {double? lat, double? lon}) async {
    // Always send '{}': Fastify 400s on `Content-Type: application/json` with an
    // empty body (FST_ERR_CTP_EMPTY_JSON_BODY), which surfaced as
    // "Check the entered details and try again."
    final r = await http.post(
        u('/api/v1/suggestions/$suggestionId/vote', {
          if (lat != null) 'lat': '$lat',
          if (lon != null) 'lon': '$lon',
        }),
        headers: headers,
        body: '{}');
    return _decode(r);
  }

  // ---- Playlist editor (V.2.3, versioned reorder) ----
  Future<dynamic> createPlaylist(Map<String, dynamic> b) =>
      _post('/api/v1/playlists', b);
  Future<dynamic> listPlaylists() => _get('/api/v1/playlists');
  Future<dynamic> getPlaylist(String id) => _get('/api/v1/playlists/$id');
  Future<dynamic> addTrack(String playlistId, Map<String, dynamic> b) =>
      _post('/api/v1/playlists/$playlistId/tracks', b);
  Future<dynamic> reorder(
          String playlistId, List<String> orderedIds, int version) =>
      _patch('/api/v1/playlists/$playlistId/reorder',
          {'orderedIds': orderedIds, 'version': version});

  // ---- Invites (owner adds members to private rooms) ----
  Future<dynamic> inviteToEvent(String eventId, String userId) =>
      _post('/api/v1/events/$eventId/invites', {'userId': userId});
  Future<dynamic> eventInvites(String eventId) =>
      _get('/api/v1/events/$eventId/invites');
  Future<dynamic> inviteToPlaylist(String playlistId, String userId) =>
      _post('/api/v1/playlists/$playlistId/invites', {'userId': userId});
  Future<dynamic> playlistInvites(String playlistId) =>
      _get('/api/v1/playlists/$playlistId/invites');

  // ---- Deezer proxy (metadata only, never called directly) ----
  Future<dynamic> search(String q) async {
    final query = q.trim();
    if (query.isEmpty) throw ApiException(400, 'Type something to search');
    final r =
        await http.get(u('/api/v1/music/search', {'q': query}), headers: headers);
    return _decode(r);
  }

  /// Cold-start default: top tracks so Home/search never opens blank.
  Future<dynamic> chart() async {
    final r = await http.get(u('/api/v1/music/chart'), headers: headers);
    return _decode(r);
  }

  // ---- Bonus: nearby (VI.2), billing mock (VI.3), sync delta (VI.4) ----
  Future<dynamic> nearby(
          {required double lat,
          required double lon,
          double radiusM = 1000}) =>
      _get('/api/v1/events/nearby',
          {'lat': '$lat', 'lon': '$lon', 'radiusM': '$radiusM'});

  Future<dynamic> billingMe() => _get('/api/v1/billing/me');
  Future<dynamic> upgradeMock() => _post('/api/v1/billing/upgrade-mock', {});
  Future<dynamic> syncDelta({String? since}) =>
      _get('/api/v1/sync/delta', {if (since != null) 'since': since});
}
