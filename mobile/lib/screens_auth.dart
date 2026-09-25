import 'package:flutter/material.dart';

import 'api.dart';
import 'config.dart';
import 'session.dart';
import 'ui/theme.dart';
import 'ui/widgets.dart';

void showErr(BuildContext context, Object error) {
  final message = error is ApiException
      ? error.message
      : error.toString().replaceFirst('Exception: ', '');
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        action: SnackBarAction(label: 'Dismiss', onPressed: () {}),
      ),
    );
}

class AuthScreen extends StatefulWidget {
  final Session session;

  const AuthScreen(this.session, {super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } catch (error) {
      if (mounted) showErr(context, error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.session,
      builder: (context, _) => widget.session.isAuthed
          ? _account(context, widget.session)
          : _signIn(context),
    );
  }

  Widget _signIn(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: PageWidth(
              maxWidth: 520,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        width: 58,
                        height: 58,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Icon(
                          Icons.graphic_eq_rounded,
                          size: 30,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'Welcome back',
                        style: Theme.of(context).textTheme.displaySmall,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Sign in to create rooms, suggest tracks, and vote together.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      TextField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.email],
                        decoration: const InputDecoration(
                          labelText: 'Email address',
                          prefixIcon: Icon(Icons.alternate_email_rounded),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextField(
                        controller: _password,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.password],
                        onSubmitted: (_) => _run(
                          () => widget.session.signInWithPassword(
                            _email.text,
                            _password.text,
                          ),
                        ),
                        decoration: InputDecoration(
                          labelText: 'Password',
                          helperText: 'Use at least 6 characters',
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          suffixIcon: IconButton(
                            tooltip: _obscurePassword
                                ? 'Show password'
                                : 'Hide password',
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      FilledButton.icon(
                        onPressed: _busy
                            ? null
                            : () => _run(
                                  () => widget.session.signInWithPassword(
                                    _email.text,
                                    _password.text,
                                  ),
                                ),
                        icon: _busy
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.arrow_forward_rounded),
                        label: Text(_busy ? 'Signing in…' : 'Continue'),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _busy
                              ? null
                              : () {
                                  if (!Session.validEmail(_email.text)) {
                                    showErr(context, 'Enter your email first.');
                                    return;
                                  }
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Demo reset link created. Check your email.',
                                      ),
                                    ),
                                  );
                                },
                          child: const Text('Forgot password?'),
                        ),
                      ),
                      const Row(
                        children: [
                          Expanded(child: Divider()),
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                            ),
                            child: Text('or'),
                          ),
                          Expanded(child: Divider()),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      OutlinedButton.icon(
                        onPressed: _busy
                            ? null
                            : () => _run(
                                  () => widget.session.signInWithSocial('google'),
                                ),
                        icon: const Icon(Icons.g_mobiledata_rounded, size: 25),
                        label: const Text('Continue with Google'),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      OutlinedButton.icon(
                        onPressed: _busy
                            ? null
                            : () => _run(
                                  () => widget.session.signInWithSocial('facebook'),
                                ),
                        icon: const Icon(Icons.facebook_rounded, size: 22),
                        label: const Text('Continue with Facebook'),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Demo authentication stores a local session token. Production auth is designed for Supabase.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _account(BuildContext context, Session session) {
    return Scaffold(
      body: SafeArea(
        child: PageWidth(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              const AppPageHeader(
                eyebrow: 'Your profile',
                title: 'Account',
                subtitle: 'Manage your identity, visibility, and music preferences.',
              ),
              const SizedBox(height: AppSpacing.lg),
              SurfaceCard(
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor:
                          Theme.of(context).colorScheme.primary.withAlpha(28),
                      child: Icon(
                        Icons.person_rounded,
                        color: Theme.of(context).colorScheme.primary,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            session.email ?? 'Music Room member',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            session.providers.isEmpty
                                ? 'No linked providers'
                                : session.providers.join(' · '),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SectionHeader(
                'Linked accounts',
                subtitle: 'Attach providers without losing your room identity.',
              ),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  for (final provider in ['google', 'facebook'])
                    if (!session.providers.contains(provider))
                      OutlinedButton.icon(
                        onPressed: _busy
                            ? null
                            : () => _run(() => session.link(provider)),
                        icon: Icon(
                          provider == 'google'
                              ? Icons.g_mobiledata_rounded
                              : Icons.facebook_rounded,
                        ),
                        label: Text(
                          'Link ${provider[0].toUpperCase()}${provider.substring(1)}',
                        ),
                      ),
                ],
              ),
              const SectionHeader('Profile details'),
              ProfileEditor(token: session.token!),
              const SizedBox(height: AppSpacing.lg),
              OutlinedButton.icon(
                onPressed: _busy ? null : () => _run(session.signOut),
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Sign out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProfileEditor extends StatefulWidget {
  final String token;

  const ProfileEditor({required this.token, super.key});

  @override
  State<ProfileEditor> createState() => _ProfileEditorState();
}

class _ProfileEditorState extends State<ProfileEditor> {
  final _name = TextEditingController();
  final _prefs = TextEditingController();
  String _visibility = 'public';
  bool _loaded = false;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _prefs.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final genres = _prefs.text
          .split(',')
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty)
          .toSet()
          .toList();
      await Api(widget.token).updateProfile({
        if (_name.text.trim().isNotEmpty) 'displayName': _name.text.trim(),
        'visibility': _visibility,
        'musicPrefs': {'genres': genres},
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile saved.')),
        );
      }
    } catch (error) {
      if (mounted) showErr(context, error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<dynamic>(
      future: Api(widget.token).getProfile(),
      builder: (context, snapshot) {
        if (!_loaded && snapshot.hasData && snapshot.data is Map) {
          final profile = snapshot.data as Map;
          _name.text = profile['displayName']?.toString() ?? '';
          final visibility = profile['visibility']?.toString() ?? 'public';
          _visibility = ['public', 'friends', 'private'].contains(visibility)
              ? visibility
              : 'public';
          final preferences = profile['musicPrefs'];
          final genres = preferences is Map ? preferences['genres'] : null;
          _prefs.text = genres is List ? genres.join(', ') : '';
          _loaded = true;
        }

        if (snapshot.connectionState == ConnectionState.waiting && !_loaded) {
          return const ShimmerRow();
        }
        if (snapshot.hasError && !_loaded) {
          return ErrorState(
            message: friendlyErr(snapshot.error!),
            onRetry: () => setState(() => _loaded = false),
          );
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                TextField(
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Display name',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                DropdownButtonFormField<String>(
                  value: _visibility,
                  decoration: const InputDecoration(
                    labelText: 'Profile visibility',
                    prefixIcon: Icon(Icons.visibility_outlined),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'public', child: Text('Public')),
                    DropdownMenuItem(
                      value: 'friends',
                      child: Text('Friends only'),
                    ),
                    DropdownMenuItem(value: 'private', child: Text('Private')),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _visibility = value);
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: _prefs,
                  decoration: const InputDecoration(
                    labelText: 'Favorite genres',
                    hintText: 'Jazz, soul, electronic',
                    helperText: 'Separate genres with commas',
                    prefixIcon: Icon(Icons.library_music_outlined),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(_saving ? 'Saving…' : 'Save profile'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class SettingsScreen extends StatefulWidget {
  final Session session;
  final VoidCallback onUrlChanged;

  const SettingsScreen(this.session, {required this.onUrlChanged, super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _url;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _url = TextEditingController(text: AppConfig.backendUrl);
  }

  @override
  void dispose() {
    _url.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final value = _url.text.trim();
    final uri = Uri.tryParse(value);
    if (value.isEmpty ||
        uri == null ||
        !['http', 'https'].contains(uri.scheme)) {
      showErr(context, 'Enter a valid http:// or https:// backend URL.');
      return;
    }
    setState(() => _saving = true);
    try {
      await AppConfig.saveBackendUrl(value);
      widget.onUrlChanged();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Backend URL saved: $value')),
        );
      }
    } catch (error) {
      if (mounted) showErr(context, error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: PageWidth(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              const AppPageHeader(
                eyebrow: 'Preferences',
                title: 'Settings',
                subtitle: 'Connect the app to your Music Room backend and review device metadata.',
              ),
              const SizedBox(height: AppSpacing.lg),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Backend connection',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'The backend remains the source of truth. Change this only for local or test environments.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextField(
                        controller: _url,
                        keyboardType: TextInputType.url,
                        autocorrect: false,
                        decoration: const InputDecoration(
                          labelText: 'Backend URL',
                          hintText: 'http://localhost:3001',
                          prefixIcon: Icon(Icons.dns_outlined),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      FilledButton.icon(
                        onPressed: _saving ? null : _save,
                        icon: _saving
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.save_outlined),
                        label: Text(_saving ? 'Saving…' : 'Save backend URL'),
                      ),
                    ],
                  ),
                ),
              ),
              const SectionHeader(
                'Action logging',
                subtitle: 'Sent with every API request for auditability.',
              ),
              Card(
                child: Column(
                  children: [
                    _InfoRow(
                      icon: Icons.phone_android_rounded,
                      label: 'Platform',
                      value: AppConfig.platform,
                    ),
                    const Divider(height: 1),
                    _InfoRow(
                      icon: Icons.devices_other_rounded,
                      label: 'Device',
                      value: AppConfig.device,
                    ),
                    const Divider(height: 1),
                    _InfoRow(
                      icon: Icons.numbers_rounded,
                      label: 'App version',
                      value: AppConfig.appVersion,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      trailing: Text(
        value,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }
}