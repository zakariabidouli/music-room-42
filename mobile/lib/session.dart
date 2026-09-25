// Session: mock auth for the school demo (subject V.1).
// Local/dev backend accepts X-User-Id (see backend/src/lib.ts); prod verifies
// Supabase JWT. Email/social buttons below mint a local token; "link" attaches
// extra providers to the same account. Token persists across restarts.
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Session extends ChangeNotifier {
  static const _tokenKey = 'mr_token';
  static const _emailKey = 'mr_email';
  static const _providersKey = 'mr_providers';

  String? token;
  String? email;
  List<String> providers = [];

  bool get isAuthed => token != null && token!.isNotEmpty;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString(_tokenKey);
    email = prefs.getString(_emailKey);
    providers = prefs.getStringList(_providersKey) ?? [];
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    if (token == null) {
      await prefs.remove(_tokenKey);
      await prefs.remove(_emailKey);
    } else {
      await prefs.setString(_tokenKey, token!);
      if (email != null) await prefs.setString(_emailKey, email!);
    }
    await prefs.setStringList(_providersKey, providers);
  }

  static bool validEmail(String v) =>
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim());

  /// Email/password mock signup+login (school demo: no real mail send).
  Future<void> signInWithPassword(String email, String password) async {
    final e = email.trim();
    if (!validEmail(e)) throw Exception('Invalid email address');
    if (password.length < 6) throw Exception('Password needs 6+ chars');
    token = 'pw_${e.hashCode.abs()}_${DateTime.now().millisecondsSinceEpoch}';
    this.email = e;
    if (!providers.contains('password')) providers.add('password');
    await _persist();
    notifyListeners();
  }

  /// Social mock (subject: Google/Facebook supported, linkable post-signup).
  Future<void> signInWithSocial(String provider) async {
    token =
        '${provider}_${DateTime.now().millisecondsSinceEpoch}';
    email ??= '$provider.user@example.com';
    if (!providers.contains(provider)) providers.add(provider);
    await _persist();
    notifyListeners();
  }

  /// Link another provider to the current account (post-signup linking).
  Future<void> link(String provider) async {
    if (!isAuthed) throw Exception('Sign in first');
    if (!providers.contains(provider)) providers.add(provider);
    await _persist();
    notifyListeners();
  }

  Future<void> signOut() async {
    token = null;
    email = null;
    providers = [];
    await _persist();
    notifyListeners();
  }
}
