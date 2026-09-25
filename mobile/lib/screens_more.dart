import 'package:flutter/material.dart';

import 'api.dart';
import 'screens_auth.dart' show showErr;
import 'session.dart';
import 'ui/theme.dart';
import 'ui/widgets.dart';

class MoreScreen extends StatefulWidget {
  final Session session;

  const MoreScreen(this.session, {super.key});

  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> {
  final _latitude = TextEditingController(text: '48.8566');
  final _longitude = TextEditingController(text: '2.3522');
  List<dynamic> _nearby = [];
  Map? _billing;
  Map? _delta;
  bool _billingBusy = false;
  bool _nearbyBusy = false;
  bool _syncBusy = false;

  Api get _api => Api(widget.session.token!);

  @override
  void initState() {
    super.initState();
    if (widget.session.isAuthed) _loadBilling();
  }

  @override
  void dispose() {
    _latitude.dispose();
    _longitude.dispose();
    super.dispose();
  }

  Future<void> _loadBilling() async {
    if (mounted) setState(() => _billingBusy = true);
    try {
      final billing = await _api.billingMe() as Map;
      if (mounted) setState(() => _billing = billing);
    } catch (error) {
      if (mounted) showErr(context, friendlyErr(error));
    } finally {
      if (mounted) setState(() => _billingBusy = false);
    }
  }

  Future<void> _findNearby() async {
    final latitude = double.tryParse(_latitude.text.trim());
    final longitude = double.tryParse(_longitude.text.trim());
    if (latitude == null || longitude == null) {
      showErr(context, 'Enter valid latitude and longitude values.');
      return;
    }
    if (mounted) setState(() => _nearbyBusy = true);
    try {
      final result = await _api.nearby(lat: latitude, lon: longitude) as List;
      if (mounted) setState(() => _nearby = result);
    } catch (error) {
      if (mounted) showErr(context, friendlyErr(error));
    } finally {
      if (mounted) setState(() => _nearbyBusy = false);
    }
  }

  Future<void> _upgrade() async {
    if (mounted) setState(() => _billingBusy = true);
    try {
      final billing = await _api.upgradeMock() as Map;
      if (mounted) {
        setState(() => _billing = billing);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mock tier updated.')),
        );
      }
    } catch (error) {
      if (mounted) showErr(context, friendlyErr(error));
    } finally {
      if (mounted) setState(() => _billingBusy = false);
    }
  }

  Future<void> _sync() async {
    if (mounted) setState(() => _syncBusy = true);
    try {
      final delta = await _api.syncDelta() as Map;
      if (mounted) setState(() => _delta = delta);
    } catch (error) {
      if (mounted) showErr(context, friendlyErr(error));
    } finally {
      if (mounted) setState(() => _syncBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.session.isAuthed) {
      return const EmptyState(
        icon: Icons.explore_off_rounded,
        title: 'Sign in to explore more',
        subtitle: 'Nearby rooms, sync tools, and account features live here.',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadBilling,
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
              const AppPageHeader(
                eyebrow: 'Beyond the queue',
                title: 'Discover',
                subtitle:
                    'Explore nearby rooms, sync state, and the free school demo tier.',
              ),
              const SizedBox(height: AppSpacing.lg),
              _SectionCard(
                icon: Icons.workspace_premium_rounded,
                title: 'Your tier',
                subtitle: 'Mock billing · no payment is collected',
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _billing?['tier']?.toString() ?? 'Loading…',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    if (_billingBusy)
                      const SizedBox.square(
                        dimension: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      IconButton(
                        tooltip: 'Refresh tier',
                        onPressed: _loadBilling,
                        icon: const Icon(Icons.refresh_rounded),
                      ),
                  ],
                ),
                footer: Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _billingBusy ? null : _loadBilling,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Refresh'),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: _billingBusy ? null : _upgrade,
                      icon: const Icon(Icons.auto_awesome_rounded),
                      label: const Text('Mock upgrade'),
                    ),
                  ],
                ),
              ),
              const SectionHeader(
                'Nearby public events',
                subtitle: 'Use coordinates to test the proximity experience.',
              ),
              _SectionCard(
                icon: Icons.near_me_rounded,
                title: 'Find a room',
                subtitle: 'Default coordinates point to Paris for quick testing.',
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _latitude,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Latitude',
                              prefixIcon: Icon(Icons.explore_outlined),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: TextField(
                            controller: _longitude,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration:
                                const InputDecoration(labelText: 'Longitude'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _nearbyBusy ? null : _findNearby,
                        icon: _nearbyBusy
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.search_rounded),
                        label: Text(
                          _nearbyBusy ? 'Searching…' : 'Find nearby events',
                        ),
                      ),
                    ),
                    if (_nearby.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.md),
                      for (final event in _nearby)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.place_rounded),
                          title: Text(event['title']?.toString() ?? 'Event'),
                          subtitle:
                              Text('lat ${event['lat']} · lon ${event['lon']}'),
                        ),
                    ],
                  ],
                ),
              ),
              const SectionHeader(
                'Offline sync delta',
                subtitle: 'Compare playlist versions before reconnecting.',
              ),
              _SectionCard(
                icon: Icons.sync_rounded,
                title: 'Sync status',
                subtitle: 'The backend returns the current version snapshot.',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FilledButton.tonalIcon(
                      onPressed: _syncBusy ? null : _sync,
                      icon: _syncBusy
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.cloud_download_outlined),
                      label: Text(_syncBusy ? 'Fetching delta…' : 'Fetch delta'),
                    ),
                    if (_delta != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      InlineMessage(
                        icon: Icons.check_circle_outline_rounded,
                        message: '${_delta!['since']} · ${_delta!['note']}',
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;
  final Widget? footer;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withAlpha(24),
                    borderRadius: BorderRadius.circular(AppRadii.md),
                  ),
                  child: Icon(icon, color: Theme.of(context).colorScheme.primary),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 2),
                      Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            child,
            if (footer != null) ...[
              const SizedBox(height: AppSpacing.md),
              footer!,
            ],
          ],
        ),
      ),
    );
  }
}