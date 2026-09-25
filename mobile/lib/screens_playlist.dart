import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import 'api.dart';
import 'config.dart';
import 'invites.dart';
import 'screens_auth.dart' show showErr;
import 'session.dart';
import 'ui/theme.dart';
import 'ui/widgets.dart';

class PlaylistScreen extends StatefulWidget {
  final Session session;

  const PlaylistScreen(this.session, {super.key});

  @override
  State<PlaylistScreen> createState() => _PlaylistScreenState();
}

class _PlaylistScreenState extends State<PlaylistScreen> {
  static const _idsKey = 'mr_playlist_ids';
  final _openId = TextEditingController();
  List<String> _ids = [];
  List<dynamic> _server = [];
  bool _loading = true;
  bool _wasAuthed = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _wasAuthed = widget.session.isAuthed;
    widget.session.addListener(_onSession);
    _boot();
  }

  @override
  void dispose() {
    widget.session.removeListener(_onSession);
    _openId.dispose();
    super.dispose();
  }

  void _onSession() {
    if (widget.session.isAuthed != _wasAuthed) {
      _wasAuthed = widget.session.isAuthed;
      _boot();
    }
  }

  Future<void> _boot() async {
    await _loadIds();
    await _reloadServer();
  }

  Future<void> _loadIds() async {
    final preferences = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() => _ids = preferences.getStringList(_idsKey) ?? []);
    }
  }

  Future<void> _reloadServer() async {
    final token = widget.session.token;
    if (token == null) {
      if (mounted) {
        setState(() {
          _server = [];
          _loading = false;
          _error = null;
        });
      }
      return;
    }
    if (mounted) setState(() => _loading = true);
    try {
      final list = await Api(token).listPlaylists() as List;
      if (mounted) {
        setState(() {
          _server = list;
          _loading = false;
          _error = null;
        });
        for (final playlist in list) {
          if (playlist is Map && playlist['id'] != null) {
            _remember('${playlist['id']}');
          }
        }
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = friendlyErr(error);
        });
      }
    }
  }

  Future<void> _remember(String id) async {
    if (_ids.contains(id)) return;
    final next = [..._ids, id];
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(_idsKey, next);
    if (mounted) setState(() => _ids = next);
  }

  Future<void> _newPlaylist() async {
    final id = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => PlaylistForm(token: widget.session.token!),
      ),
    );
    if (id == null || !mounted) return;
    await _remember(id);
    await _reloadServer();
    if (mounted) _open(id);
  }

  void _open(String id) {
    Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => PlaylistDetail(
          token: widget.session.token!,
          playlistId: id,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.session.isAuthed) {
      return const EmptyState(
        icon: Icons.queue_music_rounded,
        title: 'Sign in to edit playlists',
        subtitle: 'Collaborative mixes, ordering, and invitations live here.',
      );
    }

    return RefreshIndicator(
      onRefresh: _reloadServer,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final padding = AppSpacing.page(constraints.maxWidth);
          return ListView(
            padding: EdgeInsets.fromLTRB(
              padding,
              padding,
              padding,
              AppSpacing.xl,
            ),
            children: [
              AppPageHeader(
                eyebrow: 'Collaborative editor',
                title: 'Your playlists',
                subtitle: 'Shape the order together. Every save is versioned by the backend.',
                action: FilledButton.icon(
                  onPressed: _newPlaylist,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('New playlist'),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              if (_loading)
                ...List.generate(4, (_) => const ShimmerRow())
              else ...[
                if (_error != null) ...[
                  InlineMessage(
                    icon: Icons.cloud_off_rounded,
                    message: _error!,
                    color: Theme.of(context).colorScheme.error,
                    action: TextButton(
                      onPressed: _reloadServer,
                      child: const Text('Retry'),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _openId,
                            textInputAction: TextInputAction.go,
                            onSubmitted: (_) {
                              final id = _openId.text.trim();
                              if (id.isNotEmpty) _open(id);
                            },
                            decoration: const InputDecoration(
                              labelText: 'Open playlist by ID',
                              prefixIcon: Icon(Icons.tag_rounded),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        IconButton.filledTonal(
                          tooltip: 'Open playlist',
                          onPressed: () {
                            final id = _openId.text.trim();
                            if (id.isEmpty) {
                              showErr(context, 'Enter a playlist ID first.');
                            } else {
                              _open(id);
                            }
                          },
                          icon: const Icon(Icons.arrow_forward_rounded),
                        ),
                      ],
                    ),
                  ),
                ),
                SectionHeader(
                  'Available playlists',
                  subtitle: 'Public rooms and private rooms shared with you.',
                  trailing: StatusPill(
                    '${_server.length} total',
                    icon: Icons.collections_bookmark_outlined,
                  ),
                ),
                if (_server.isEmpty)
                  EmptyState(
                    icon: Icons.queue_music_rounded,
                    title: 'No playlists yet',
                    subtitle: 'Create a shared mix and invite the people who shape it.',
                    actionLabel: 'Create playlist',
                    onAction: _newPlaylist,
                  )
                else
                  for (var index = 0; index < _server.length; index++)
                    Stagger(
                      index: index,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: _PlaylistCard(
                          playlist: _server[index] as Map,
                          onTap: () => _open('${_server[index]['id']}'),
                        ),
                      ),
                    ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _PlaylistCard extends StatelessWidget {
  final Map playlist;
  final VoidCallback onTap;

  const _PlaylistCard({required this.playlist, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final trackCount = playlist['trackCount'] ??
        (playlist['tracks'] is List ? (playlist['tracks'] as List).length : 0);
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withAlpha(24),
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                child: Icon(
                  Icons.queue_music_rounded,
                  color: Theme.of(context).colorScheme.primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      playlist['title']?.toString() ?? 'Untitled playlist',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '$trackCount tracks · v${playlist['version'] ?? 1}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: AppSpacing.xs,
                      children: [
                        StatusPill(
                          playlist['visibility']?.toString() ?? 'public',
                          icon: Icons.public_rounded,
                        ),
                        StatusPill(
                          playlist['license']?.toString() ?? 'open',
                          icon: Icons.rule_rounded,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class PlaylistForm extends StatefulWidget {
  final String token;

  const PlaylistForm({required this.token, super.key});

  @override
  State<PlaylistForm> createState() => _PlaylistFormState();
}

class _PlaylistFormState extends State<PlaylistForm> {
  final _title = TextEditingController();
  String _visibility = 'public';
  String _license = 'open';
  bool _busy = false;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (_busy) return;
    if (_title.text.trim().isEmpty) {
      showErr(context, 'Give the playlist a title.');
      return;
    }
    setState(() => _busy = true);
    try {
      final playlist = await Api(widget.token).createPlaylist({
        'title': _title.text.trim(),
        'visibility': _visibility,
        'license': _license,
      }) as Map;
      if (mounted) Navigator.pop(context, '${playlist['id']}');
    } catch (error) {
      if (mounted) showErr(context, friendlyErr(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New playlist')),
      body: PageWidth(
        maxWidth: 760,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            const AppPageHeader(
              eyebrow: 'New collection',
              title: 'Build a shared mix',
              subtitle: 'Invite collaborators and let everyone shape the order.',
            ),
            const SizedBox(height: AppSpacing.lg),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  children: [
                    TextField(
                      controller: _title,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Playlist title',
                        prefixIcon: Icon(Icons.playlist_play_rounded),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    DropdownButtonFormField<String>(
                      value: _visibility,
                      decoration: const InputDecoration(
                        labelText: 'Visibility',
                        prefixIcon: Icon(Icons.public_outlined),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'public', child: Text('Public')),
                        DropdownMenuItem(
                          value: 'private',
                          child: Text('Private · invited only'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) setState(() => _visibility = value);
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    DropdownButtonFormField<String>(
                      value: _license,
                      decoration: const InputDecoration(
                        labelText: 'Edit license',
                        prefixIcon: Icon(Icons.rule_outlined),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'open',
                          child: Text('Open · everyone edits'),
                        ),
                        DropdownMenuItem(
                          value: 'invited-only',
                          child: Text('Invited only'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) setState(() => _license = value);
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: _busy ? null : _create,
              icon: _busy
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.arrow_forward_rounded),
              label: Text(_busy ? 'Creating…' : 'Create playlist'),
            ),
          ],
        ),
      ),
    );
  }
}

class PlaylistDetail extends StatefulWidget {
  final String token;
  final String playlistId;

  const PlaylistDetail({
    required this.token,
    required this.playlistId,
    super.key,
  });

  @override
  State<PlaylistDetail> createState() => _PlaylistDetailState();
}

class _PlaylistDetailState extends State<PlaylistDetail> {
  Map? _playlist;
  List<dynamic> _tracks = [];
  int _version = 1;
  bool _loading = true;
  bool _saving = false;
  String? _error;
  io.Socket? _socket;

  @override
  void initState() {
    super.initState();
    _connect();
    _reload();
  }

  void _connect() {
    try {
      final socket = io.io(
        AppConfig.backendUrl,
        io.OptionBuilder()
            .setTransports(['websocket'])
            .disableAutoConnect()
            .build(),
      );
      socket.onConnect((_) => socket.emit('join:playlist', widget.playlistId));
      socket.on('playlist:updated', (_) => _reload());
      socket.connect();
      _socket = socket;
    } catch (_) {
      // Realtime is best-effort; pull-to-refresh still works.
    }
  }

  @override
  void dispose() {
    _socket?.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    try {
      final playlist =
          await Api(widget.token).getPlaylist(widget.playlistId) as Map;
      if (mounted) {
        setState(() {
          _playlist = playlist;
          _tracks = (playlist['tracks'] as List?) ?? [];
          _version = (playlist['version'] as num?)?.toInt() ?? 1;
          _loading = false;
          _error = null;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = friendlyErr(error);
        });
      }
    }
  }

  Future<void> _saveOrder() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final ids = _tracks.map((track) => '${track['id']}').toList();
      final result =
          await Api(widget.token).reorder(widget.playlistId, ids, _version) as Map;
      if (mounted) {
        setState(() => _version = (result['version'] as num).toInt());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Order saved · version $_version.')),
        );
      }
    } on ApiException catch (error) {
      if (error.status == 409) {
        final current = error.body is Map ? error.body['current'] : null;
        if (current is List && mounted) {
          setState(() {
            _tracks = current;
            final version = error.body is Map ? error.body['version'] : null;
            if (version is num) _version = version.toInt();
          });
        } else {
          await _reload();
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Someone edited first. The latest order is loaded.'),
            ),
          );
        }
      } else if (mounted) {
        showErr(context, friendlyErr(error));
      }
    } catch (error) {
      if (mounted) showErr(context, friendlyErr(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _addTrack() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => AddTrackForm(
          token: widget.token,
          playlistId: widget.playlistId,
        ),
      ),
    );
    if (mounted) await _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${_playlist?['title'] ?? widget.playlistId} · v$_version'),
        actions: [
          IconButton(
            tooltip: 'Refresh playlist',
            onPressed: _reload,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addTrack,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add track'),
      ),
      body: _loading
          ? ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: 7,
              itemBuilder: (_, __) => const ShimmerRow(),
            )
          : Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  color: Theme.of(context).colorScheme.surface,
                  child: PageWidth(
                    child: CollageHeader(
                      tracks: _tracks,
                      title: _playlist?['title']?.toString() ?? widget.playlistId,
                      subtitle:
                          'v$_version · ${_tracks.length} tracks · ${_playlist?['visibility'] ?? ''} · ${_playlist?['license'] ?? ''}',
                    ),
                  ),
                ),
                InviteSection(
                  load: () async =>
                      (await Api(widget.token)
                              .playlistInvites(widget.playlistId) as List)
                          .map((value) => '$value')
                          .toList(),
                  add: (userId) => Api(widget.token)
                      .inviteToPlaylist(widget.playlistId, userId),
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.md,
                      AppSpacing.md,
                      0,
                    ),
                    child: InlineMessage(
                      icon: Icons.cloud_off_rounded,
                      message: _error!,
                      color: Theme.of(context).colorScheme.error,
                      action: TextButton(
                        onPressed: _reload,
                        child: const Text('Retry'),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: PageWidth(
                    child: FilledButton.icon(
                      onPressed: _saving || _tracks.isEmpty ? null : _saveOrder,
                      icon: _saving
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save_outlined),
                      label: Text(_saving ? 'Saving order…' : 'Save order · v$_version'),
                    ),
                  ),
                ),
                Expanded(
                  child: _tracks.isEmpty
                      ? const EmptyState(
                          icon: Icons.music_note_rounded,
                          title: 'This playlist is empty',
                          subtitle: 'Add a track to give the room a starting point.',
                        )
                      : ReorderableListView.builder(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.md,
                            0,
                            AppSpacing.md,
                            96,
                          ),
                          itemCount: _tracks.length,
                          onReorder: (oldIndex, newIndex) {
                            setState(() {
                              if (newIndex > oldIndex) newIndex -= 1;
                              final track = _tracks.removeAt(oldIndex);
                              _tracks.insert(newIndex, track);
                            });
                          },
                          itemBuilder: (context, index) {
                            final track = _tracks[index] as Map;
                            return TrackTile(
                              track,
                              key: ValueKey('${track['id']}'),
                              badge: '${index + 1}',
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  PreviewButtonWithHint(track),
                                  const SizedBox(width: 4),
                                  ReorderableDragStartListener(
                                    index: index,
                                    child: const Padding(
                                      padding: EdgeInsets.all(12),
                                      child: Icon(Icons.drag_handle_rounded),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

class AddTrackForm extends StatefulWidget {
  final String token;
  final String playlistId;

  const AddTrackForm({
    required this.token,
    required this.playlistId,
    super.key,
  });

  @override
  State<AddTrackForm> createState() => _AddTrackFormState();
}

class _AddTrackFormState extends State<AddTrackForm> {
  final _query = TextEditingController();
  List<dynamic> _results = [];
  bool _busy = false;
  bool _isChart = true;
  String? _error;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadChart();
  }

  Future<void> _loadChart() async {
    if (mounted) setState(() => _busy = true);
    try {
      final result = await Api(widget.token).chart();
      if (mounted) {
        setState(() {
          _results = result as List;
          _isChart = true;
          _busy = false;
          _error = null;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = friendlyErr(error);
        });
      }
    }
  }

  Future<void> _search() async {
    if (_query.text.trim().isEmpty) {
      await _loadChart();
      return;
    }
    if (mounted) setState(() => _busy = true);
    try {
      final result = await Api(widget.token).search(_query.text.trim());
      if (mounted) {
        setState(() {
          _results = result as List;
          _isChart = false;
          _busy = false;
          _error = null;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = friendlyErr(error);
        });
      }
    }
  }

  Future<void> _pick(Map track) async {
    final title = track['title']?.toString().trim() ?? '';
    final artist = track['artist']?.toString().trim() ?? '';
    final trackId = track['deezerTrackId']?.toString().trim() ?? '';
    if (title.isEmpty || artist.isEmpty || trackId.isEmpty) {
      showErr(context, 'That track has incomplete information.');
      return;
    }
    try {
      await Api(widget.token).addTrack(widget.playlistId, {
        'deezerTrackId': trackId,
        'title': title,
        'artist': artist,
        if (track['previewUrl'] != null) 'previewUrl': '${track['previewUrl']}',
        if (track['coverUrl'] != null) 'coverUrl': '${track['coverUrl']}',
      });
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) showErr(context, friendlyErr(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add a track')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: PageWidth(
              maxWidth: 820,
              child: AppSearchBar(
                controller: _query,
                hint: 'Search artists, tracks, or moods',
                busy: _busy,
                onSearch: _search,
              ),
            ),
          ),
          if (_busy) const LinearProgressIndicator(minHeight: 2),
          PageWidth(
            maxWidth: 820,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.xs,
                AppSpacing.md,
                AppSpacing.xs,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _isChart ? 'Top tracks right now' : '${_results.length} results',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
            ),
          ),
          Expanded(
            child: PageWidth(
              maxWidth: 820,
              child: _error != null
                  ? ErrorState(message: _error!, onRetry: _search)
                  : _results.isEmpty && !_busy
                      ? EmptyState(
                          icon: Icons.search_rounded,
                          title: _query.text.trim().isEmpty
                              ? 'Search or browse top tracks'
                              : 'No matching tracks',
                          subtitle: 'Try another artist, title, or mood.',
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.md,
                            0,
                            AppSpacing.md,
                            AppSpacing.xl,
                          ),
                          itemCount: _results.length,
                          itemBuilder: (context, index) {
                            final track = _results[index] as Map;
                            return Stagger(
                              index: index,
                              child: TrackTile(
                                track,
                                trailing: const Icon(Icons.add_circle_outline_rounded),
                                onTap: () => _pick(track),
                              ),
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }
}