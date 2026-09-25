import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import 'api.dart';
import 'config.dart';
import 'invites.dart';
import 'player.dart';
import 'screens_auth.dart' show showErr;
import 'session.dart';
import 'ui/theme.dart';
import 'ui/widgets.dart';

class VoteScreen extends StatefulWidget {
  final Session session;

  const VoteScreen(this.session, {super.key});

  @override
  State<VoteScreen> createState() => _VoteScreenState();
}

class _VoteScreenState extends State<VoteScreen> {
  List<dynamic> _events = [];
  List<dynamic> _top = [];
  bool _loading = true;
  bool _wasAuthed = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _wasAuthed = widget.session.isAuthed;
    widget.session.addListener(_onSession);
    _reload();
  }

  @override
  void dispose() {
    widget.session.removeListener(_onSession);
    super.dispose();
  }

  void _onSession() {
    if (widget.session.isAuthed != _wasAuthed) {
      _wasAuthed = widget.session.isAuthed;
      _reload();
    }
  }

  Future<void> _reload() async {
    final token = widget.session.token;
    if (token == null) {
      if (mounted) {
        setState(() {
          _events = [];
          _top = [];
          _loading = false;
          _error = null;
        });
      }
      return;
    }
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final list = await Api(token).listEvents() as List;
      if (mounted) {
        setState(() {
          _events = list;
          _loading = false;
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
    _loadTop();
  }

  Future<void> _loadTop() async {
    final token = widget.session.token;
    if (token == null) return;
    try {
      final chart = await Api(token).chart() as List;
      if (mounted) setState(() => _top = chart);
    } catch (_) {
      // Discovery is a progressive enhancement; events remain usable.
    }
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }

  Future<void> _newEvent() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => EventForm(token: widget.session.token!),
      ),
    );
    if (mounted) await _reload();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.session.isAuthed) {
      return const EmptyState(
        icon: Icons.how_to_vote_rounded,
        title: 'Sign in to enter the room',
        subtitle: 'Create a live event, suggest tracks, and shape the queue together.',
      );
    }

    return RefreshIndicator(
      onRefresh: _reload,
      child: _loading
          ? ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: 7,
              itemBuilder: (_, __) => const ShimmerRow(),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                final horizontal = AppSpacing.page(constraints.maxWidth);
                return ListView(
                  padding: EdgeInsets.only(bottom: AppSpacing.xl),
                  children: [
                    GradientHeader(
                      _greeting,
                      subtitle: 'Discover the signal, then bring the room together.',
                      artUrl: _top.isNotEmpty && _top.first is Map
                          ? (_top.first as Map)['coverUrl']?.toString()
                          : null,
                      action: FilledButton.icon(
                        onPressed: _newEvent,
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('New event'),
                      ),
                    ),
                    PageWidth(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: horizontal),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (_error != null) ...[
                              const SizedBox(height: AppSpacing.md),
                              InlineMessage(
                                icon: Icons.cloud_off_rounded,
                                message: _error!,
                                color: Theme.of(context).colorScheme.error,
                                action: TextButton(
                                  onPressed: _reload,
                                  child: const Text('Retry'),
                                ),
                              ),
                            ],
                            if (_top.isNotEmpty) ...[
                              SectionHeader(
                                'Top tracks right now',
                                subtitle: 'Start a preview, then add it to a room.',
                                trailing: StatusPill(
                                  '${_top.length} tracks',
                                  icon: Icons.trending_up_rounded,
                                ),
                              ),
                              SizedBox(
                                height: 252,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  padding: const EdgeInsets.only(bottom: 4),
                                  itemCount: _top.length,
                                  itemBuilder: (context, index) {
                                    final track = _top[index] as Map;
                                    return Stagger(
                                      index: index,
                                      child: ShelfCard(
                                        track,
                                        onPlay: () => PreviewPlayer.instance.playTrack(track),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                            SectionHeader(
                              'Your events',
                              subtitle: 'Live queues stay synced through the backend.',
                              trailing: FilledButton.tonalIcon(
                                onPressed: _newEvent,
                                icon: const Icon(Icons.add_rounded),
                                label: const Text('Create'),
                              ),
                            ),
                            if (_events.isEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: AppSpacing.sm),
                                child: EmptyState(
                                  icon: Icons.celebration_rounded,
                                  title: 'No events yet',
                                  subtitle: 'Create the first room and let the queue begin.',
                                  actionLabel: 'Create event',
                                  onAction: _newEvent,
                                ),
                              )
                            else
                              for (var index = 0; index < _events.length; index++)
                                Stagger(
                                  index: index,
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                                    child: _EventCard(
                                      event: _events[index] as Map,
                                      onTap: () async {
                                        await Navigator.push<void>(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => EventDetail(
                                              token: widget.session.token!,
                                              event: _events[index] as Map,
                                            ),
                                          ),
                                        );
                                        if (mounted) await _reload();
                                      },
                                    ),
                                  ),
                                ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final Map event;
  final VoidCallback onTap;

  const _EventCard({required this.event, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final visibility = event['visibility']?.toString() ?? 'public';
    final license = event['license']?.toString() ?? 'open';
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.primary.withAlpha(90),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                child: const Icon(Icons.celebration_rounded),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event['title']?.toString() ?? 'Untitled event',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: 4,
                      children: [
                        StatusPill(visibility, icon: Icons.public_rounded),
                        StatusPill(license, icon: Icons.rule_rounded),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class EventForm extends StatefulWidget {
  final String token;

  const EventForm({required this.token, super.key});

  @override
  State<EventForm> createState() => _EventFormState();
}

class _EventFormState extends State<EventForm> {
  final _title = TextEditingController();
  final _lat = TextEditingController();
  final _lon = TextEditingController();
  final _radius = TextEditingController(text: '500');
  final _start = TextEditingController();
  final _end = TextEditingController();
  String _visibility = 'public';
  String _license = 'open';
  bool _busy = false;

  @override
  void dispose() {
    _title.dispose();
    _lat.dispose();
    _lon.dispose();
    _radius.dispose();
    _start.dispose();
    _end.dispose();
    super.dispose();
  }

  Map<String, dynamic> _geo() {
    final map = <String, dynamic>{};
    final lat = double.tryParse(_lat.text.trim());
    final lon = double.tryParse(_lon.text.trim());
    final radius = int.tryParse(_radius.text.trim());
    if (lat != null) map['lat'] = lat;
    if (lon != null) map['lon'] = lon;
    if (radius != null) map['radiusM'] = radius;
    if (_start.text.trim().isNotEmpty) map['startAt'] = _start.text.trim();
    if (_end.text.trim().isNotEmpty) map['endAt'] = _end.text.trim();
    return map;
  }

  Future<void> _create() async {
    if (_busy) return;
    if (_title.text.trim().isEmpty) {
      showErr(context, 'Give the event a title.');
      return;
    }
    if (_license == 'geofenced' &&
        (double.tryParse(_lat.text.trim()) == null ||
            double.tryParse(_lon.text.trim()) == null ||
            int.tryParse(_radius.text.trim()) == null)) {
      showErr(context, 'Geofenced events need latitude, longitude, and radius.');
      return;
    }
    setState(() => _busy = true);
    try {
      await Api(widget.token).createEvent({
        'title': _title.text.trim(),
        'visibility': _visibility,
        'license': _license,
        ..._geo(),
      });
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) showErr(context, friendlyErr(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create an event')),
      body: PageWidth(
        maxWidth: 760,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            const AppPageHeader(
              eyebrow: 'New room',
              title: 'Set the vibe',
              subtitle: 'Choose who can join and how the voting license behaves.',
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
                        labelText: 'Event title',
                        prefixIcon: Icon(Icons.celebration_outlined),
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
                        labelText: 'Vote license',
                        prefixIcon: Icon(Icons.rule_outlined),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'open',
                          child: Text('Open · everyone can vote'),
                        ),
                        DropdownMenuItem(
                          value: 'invited-only',
                          child: Text('Invited only'),
                        ),
                        DropdownMenuItem(
                          value: 'geofenced',
                          child: Text('Geofenced + timeboxed'),
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
            if (_license == 'geofenced') ...[
              const SectionHeader(
                'Geofence and timebox',
                subtitle: 'Voting opens only inside this place and window.',
              ),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _lat,
                              keyboardType: const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              decoration: const InputDecoration(labelText: 'Latitude'),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: TextField(
                              controller: _lon,
                              keyboardType: const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              decoration: const InputDecoration(labelText: 'Longitude'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextField(
                        controller: _radius,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Radius in meters',
                          prefixIcon: Icon(Icons.radar_rounded),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextField(
                        controller: _start,
                        decoration: const InputDecoration(
                          labelText: 'Start (ISO 8601, optional)',
                          hintText: '2026-09-23T16:00:00Z',
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextField(
                        controller: _end,
                        decoration: const InputDecoration(
                          labelText: 'End (ISO 8601, optional)',
                          hintText: '2026-09-23T18:00:00Z',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: _busy ? null : _create,
              icon: _busy
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.arrow_forward_rounded),
              label: Text(_busy ? 'Creating…' : 'Create event'),
            ),
          ],
        ),
      ),
    );
  }
}

class EventDetail extends StatefulWidget {
  final String token;
  final Map event;

  const EventDetail({required this.token, required this.event, super.key});

  @override
  State<EventDetail> createState() => _EventDetailState();
}

class _EventDetailState extends State<EventDetail> {
  List<dynamic> _queue = [];
  bool _loading = true;
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
      socket.onConnect((_) => socket.emit('join:event', widget.event['id']));
      socket.on('vote:updated', (_) => _reload());
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
      final queue = await Api(widget.token).queue(widget.event['id']) as List;
      if (mounted) {
        setState(() {
          _queue = queue;
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

  Future<void> _vote(Map suggestion) async {
    try {
      await Api(widget.token).vote(suggestion['id']);
      await _reload();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Vote added to ${suggestion['title'] ?? 'track'}.')),
        );
      }
    } catch (error) {
      if (mounted) showErr(context, friendlyErr(error));
    }
  }

  Future<void> _suggest() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => SuggestForm(
          token: widget.token,
          eventId: widget.event['id'],
        ),
      ),
    );
    if (mounted) await _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.event['title']?.toString() ?? 'Event')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _suggest,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Suggest'),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            color: Theme.of(context).colorScheme.surface,
            child: PageWidth(
              child: Row(
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: [
                        StatusPill(
                          widget.event['visibility']?.toString() ?? 'public',
                          icon: Icons.public_rounded,
                        ),
                        StatusPill(
                          widget.event['license']?.toString() ?? 'open',
                          icon: Icons.rule_rounded,
                        ),
                        StatusPill('Live queue', icon: Icons.wifi_tethering_rounded),
                      ],
                    ),
                  ),
                  Text(
                    '${_queue.length} tracks',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ],
              ),
            ),
          ),
          InviteSection(
            load: () async =>
                (await Api(widget.token).eventInvites(widget.event['id']) as List)
                    .map((value) => '$value')
                    .toList(),
            add: (userId) => Api(widget.token).inviteToEvent(widget.event['id'], userId),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _reload,
              child: _loading
                  ? ListView.builder(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      itemCount: 7,
                      itemBuilder: (_, __) => const ShimmerRow(),
                    )
                  : _error != null
                      ? ListView(
                          children: [
                            const SizedBox(height: 64),
                            ErrorState(message: _error!, onRetry: _reload),
                          ],
                        )
                      : _queue.isEmpty
                          ? ListView(
                              children: const [
                                SizedBox(height: 64),
                                EmptyState(
                                  icon: Icons.queue_music_rounded,
                                  title: 'The queue is quiet',
                                  subtitle: 'Suggest the first track and give the room a starting point.',
                                ),
                              ],
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(
                                AppSpacing.md,
                                AppSpacing.sm,
                                AppSpacing.md,
                                96,
                              ),
                              itemCount: _queue.length,
                              itemBuilder: (context, index) {
                                final track = _queue[index] as Map;
                                return Stagger(
                                  index: index,
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: TrackTile(
                                      track,
                                      badge: '${index + 1}',
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          PreviewButtonWithHint(track),
                                          const SizedBox(width: 4),
                                          FilledButton.tonal(
                                            onPressed: () => _vote(track),
                                            child: Text(
                                              'Vote · ${track['votesCount'] ?? 0}',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
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

class SuggestForm extends StatefulWidget {
  final String token;
  final String eventId;

  const SuggestForm({required this.token, required this.eventId, super.key});

  @override
  State<SuggestForm> createState() => _SuggestFormState();
}

class _SuggestFormState extends State<SuggestForm> {
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
      await Api(widget.token).suggest(widget.eventId, {
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
      appBar: AppBar(title: const Text('Suggest a track')),
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