import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../player.dart';
import 'theme.dart';
import 'widgets.dart';

class AppNavigationItem {
  final String label;
  final IconData icon;
  final IconData selectedIcon;

  const AppNavigationItem({
    required this.label,
    required this.icon,
    IconData? selectedIcon,
  }) : selectedIcon = selectedIcon ?? icon;
}

class AppSidebar extends StatelessWidget {
  final List<AppNavigationItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const AppSidebar({
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 248,
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.fromLTRB(12, 20, 12, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.graphic_eq_rounded,
                    color: Theme.of(context).colorScheme.onPrimary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    'Music Room',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          for (var index = 0; index < items.length; index++)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: _SidebarDestination(
                item: items[index],
                selected: index == selectedIndex,
                onTap: () => onSelected(index),
              ),
            ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              'SHARE THE SIGNAL',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 9,
                letterSpacing: 1.2,
                color: Theme.of(context).colorScheme.onSurface.withAlpha(120),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarDestination extends StatelessWidget {
  final AppNavigationItem item;
  final bool selected;
  final VoidCallback onTap;

  const _SidebarDestination({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final foreground = selected ? colors.onPrimary : colors.onSurface;
    return Material(
      color: selected ? colors.primary : Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            children: [
              Icon(selected ? item.selectedIcon : item.icon, size: 22),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  item.label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: foreground,
                      ),
                ),
              ),
              if (selected)
                Icon(Icons.chevron_right_rounded, size: 18, color: foreground),
            ],
          ),
        ),
      ),
    );
  }
}

class AppNavigationRail extends StatelessWidget {
  final List<AppNavigationItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const AppNavigationRail({
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationRail(
      selectedIndex: selectedIndex,
      onDestinationSelected: onSelected,
      labelType: NavigationRailLabelType.all,
      leading: Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 20),
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            Icons.graphic_eq_rounded,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
      ),
      destinations: [
        for (final item in items)
          NavigationRailDestination(
            icon: Icon(item.icon),
            selectedIcon: Icon(item.selectedIcon),
            label: Text(item.label),
          ),
      ],
    );
  }
}

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: PreviewPlayer.instance,
      builder: (context, _) {
        final player = PreviewPlayer.instance;
        final metadata = player.currentMeta;
        if (metadata == null || player.currentUrl == null) {
          return const SizedBox.shrink();
        }

        final durationMs = player.duration.inMilliseconds;
        final positionMs = player.position.inMilliseconds
            .clamp(0, durationMs)
            .toDouble();
        final maxMs = durationMs > 0 ? durationMs.toDouble() : 1.0;
        final value = durationMs > 0 ? positionMs / maxMs : 0.0;
        final colors = Theme.of(context).colorScheme;

        return Material(
          color: colors.surface,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      CoverArt(metadata, size: 48),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              metadata['title']?.toString() ?? 'Preview',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${metadata['artist'] ?? 'Unknown artist'} · 30s preview',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Back 10 seconds',
                        onPressed: player.isSeekable
                            ? () => player.skipBy(const Duration(seconds: -10))
                            : null,
                        icon: const Icon(Icons.replay_10_rounded),
                      ),
                      IconButton(
                        tooltip: player.playing ? 'Pause preview' : 'Play preview',
                        onPressed: player.isBuffering
                            ? null
                            : player.toggleCurrent,
                        icon: player.isBuffering
                            ? const SizedBox.square(
                                dimension: 22,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Icon(
                                player.playing
                                    ? Icons.pause_circle_filled
                                    : Icons.play_circle_fill,
                                size: 36,
                              ),
                      ),
                      IconButton(
                        tooltip: 'Forward 10 seconds',
                        onPressed: player.isSeekable
                            ? () => player.skipBy(const Duration(seconds: 10))
                            : null,
                        icon: const Icon(Icons.forward_10_rounded),
                      ),
                      IconButton(
                        tooltip: 'Close player',
                        onPressed: player.stop,
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        formatPlaybackTime(player.position),
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 10,
                          color: colors.onSurface.withAlpha(170),
                        ),
                      ),
                      Expanded(
                        child: Slider(
                          value: value.clamp(0.0, 1.0),
                          min: 0,
                          max: 1,
                          onChanged: player.isSeekable
                              ? (newValue) => player.seek(
                                    Duration(
                                      milliseconds:
                                          (newValue * durationMs).round(),
                                    ),
                                  )
                              : null,
                          semanticFormatterCallback: (newValue) =>
                              '${formatPlaybackTime(Duration(milliseconds: (newValue * durationMs).round()))} of ${formatPlaybackTime(player.duration)}',
                        ),
                      ),
                      Text(
                        formatPlaybackTime(player.duration),
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 10,
                          color: colors.onSurface.withAlpha(170),
                        ),
                      ),
                    ],
                  ),
                  if (player.errorMessage != null)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        player.errorMessage!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colors.error,
                            ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class SpotifySidebar extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onTap;
  final List<String> titles;
  final List<IconData> icons;

  const SpotifySidebar({
    required this.selected,
    required this.onTap,
    required this.titles,
    required this.icons,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AppSidebar(
      selectedIndex: selected,
      onSelected: onTap,
      items: [
        for (var i = 0; i < titles.length; i++)
          AppNavigationItem(label: titles[i], icon: icons[i]),
      ],
    );
  }
}