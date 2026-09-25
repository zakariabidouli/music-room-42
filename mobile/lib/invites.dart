import 'package:flutter/material.dart';

import 'screens_auth.dart' show showErr;
import 'ui/theme.dart';

class InviteSection extends StatefulWidget {
  final Future<List<String>> Function() load;
  final Future<void> Function(String userId) add;

  const InviteSection({
    required this.load,
    required this.add,
    super.key,
  });

  @override
  State<InviteSection> createState() => _InviteSectionState();
}

class _InviteSectionState extends State<InviteSection> {
  final _user = TextEditingController();
  List<String> _ids = [];
  bool _forbidden = false;
  bool _loading = true;
  bool _adding = false;

  @override
  void dispose() {
    _user.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    try {
      final ids = await widget.load();
      if (mounted) {
        setState(() {
          _ids = ids;
          _forbidden = false;
          _loading = false;
        });
      }
    } catch (_) {
      // Non-owners get 403: hide the section, the room stays usable.
      if (mounted) {
        setState(() {
          _forbidden = true;
          _loading = false;
        });
      }
    }
  }

  Future<void> _add() async {
    final value = _user.text.trim();
    if (value.isEmpty || _adding) return;
    setState(() => _adding = true);
    try {
      await widget.add(value);
      _user.clear();
      await _reload();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invitation added.')),
        );
      }
    } catch (error) {
      if (mounted) showErr(context, error);
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_forbidden) return const SizedBox.shrink();
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: LinearProgressIndicator(minHeight: 2),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        0,
      ),
      child: Card(
        child: ExpansionTile(
          leading: const Icon(Icons.people_alt_outlined),
          title: Text('Invited (${_ids.length})'),
          subtitle: const Text('Owner-managed access'),
          childrenPadding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            0,
            AppSpacing.md,
            AppSpacing.sm,
          ),
          children: [
            if (_ids.isEmpty)
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Text(
                    'No one has been invited yet.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              )
            else
              Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    for (final id in _ids)
                      Chip(
                        avatar: const Icon(Icons.person_outline, size: 16),
                        label: Text(id),
                      ),
                  ],
                ),
              ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _user,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _add(),
                    decoration: const InputDecoration(
                      labelText: 'User ID to invite',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                IconButton.filledTonal(
                  tooltip: 'Add invitation',
                  onPressed: _adding ? null : _add,
                  icon: _adding
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.person_add_alt_1_rounded),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}