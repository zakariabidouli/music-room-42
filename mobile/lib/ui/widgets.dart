// Shared, responsive components for every Music Room screen. The visual
// language intentionally avoids generic ListTile-only pages and keeps actions,
// loading, empty, and error states consistent.
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../api.dart';
import '../player.dart';
import 'theme.dart';

class PageWidth extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const PageWidth({required this.child, this.maxWidth = 1120, super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const SectionHeader(
    this.title, {
    this.subtitle,
    this.trailing,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleLarge),
                if (subtitle != null) ...[
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    subtitle!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: AppSpacing.md),
            trailing!,
          ],
        ],
      ),
    );
  }
}

class AppPageHeader extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String? subtitle;
  final Widget? action;

  const AppPageHeader({
    required this.eyebrow,
    required this.title,
    this.subtitle,
    this.action,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final copy = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              eyebrow.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    letterSpacing: 1.4,
                  ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(title, style: Theme.of(context).textTheme.displaySmall),
            if (subtitle != null) ...[
              const SizedBox(height: AppSpacing.xs),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: Text(
                  subtitle!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withAlpha(170),
                      ),
                ),
              ),
            ],
          ],
        );

        if (action == null || constraints.maxWidth < 620) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              copy,
              if (action != null) ...[
                const SizedBox(height: AppSpacing.md),
                Align(alignment: Alignment.centerLeft, child: action),
              ],
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(child: copy),
            const SizedBox(width: AppSpacing.lg),
            action!,
          ],
        );
      },
    );
  }
}

class SurfaceCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  const SurfaceCard({
    required this.child,
    this.padding,
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: padding ?? const EdgeInsets.all(AppSpacing.md),
      child: child,
    );
    return Card(
      child: onTap == null
          ? content
          : InkWell(onTap: onTap, child: content),
    );
  }
}

class StatusPill extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color? color;

  const StatusPill(this.label, {this.icon, this.color, super.key});

  @override
  Widget build(BuildContext context) {
    final foreground = color ?? Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: foreground.withAlpha(24),
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(color: foreground.withAlpha(70)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: foreground),
            const SizedBox(width: 5),
          ],
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: foreground,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class AppSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool busy;
  final VoidCallback onSearch;
  final ValueChanged<String>? onChanged;

  const AppSearchBar({
    required this.controller,
    required this.hint,
    required this.onSearch,
    this.busy = false,
    this.onChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 430;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                textInputAction: TextInputAction.search,
                onChanged: onChanged,
                onSubmitted: busy ? null : (_) => onSearch(),
                decoration: InputDecoration(
                  hintText: hint,
                  prefixIcon: const Icon(Icons.search_rounded, size: 21),
                  suffixIcon: busy
                      ? const Padding(
                          padding: EdgeInsets.all(14),
                          child: SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : null,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Tooltip(
              message: 'Search',
              child: compact
                  ? IconButton.filled(
                      onPressed: busy ? null : onSearch,
                      icon: const Icon(Icons.arrow_forward_rounded),
                    )
                  : FilledButton.icon(
                      onPressed: busy ? null : onSearch,
                      icon: const Icon(Icons.travel_explore_rounded, size: 19),
                      label: const Text('Search'),
                    ),
            ),
          ],
        );
      },
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool compact;

  const EmptyState({
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.compact = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(compact ? AppSpacing.md : AppSpacing.lg),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: compact ? 56 : 72,
                height: compact ? 56 : 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).colorScheme.primary.withAlpha(22),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary.withAlpha(70),
                  ),
                ),
                child: Icon(
                  icon,
                  size: compact ? 26 : 34,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              SizedBox(height: compact ? AppSpacing.sm : AppSpacing.md),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              if (subtitle != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  subtitle!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withAlpha(165),
                      ),
                ),
              ],
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: AppSpacing.lg),
                FilledButton.icon(
                  onPressed: onAction,
                  icon: const Icon(Icons.add_rounded),
                  label: Text(actionLabel!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final String retryLabel;

  const ErrorState({
    required this.message,
    this.onRetry,
    this.retryLabel = 'Try again',
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.cloud_off_rounded,
      title: 'Something interrupted the signal',
      subtitle: message,
      actionLabel: onRetry == null ? null : retryLabel,
      onAction: onRetry,
    );
  }
}

class InlineMessage extends StatelessWidget {
  final IconData icon;
  final String message;
  final Color? color;
  final Widget? action;

  const InlineMessage({
    required this.icon,
    required this.message,
    this.color,
    this.action,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = color ?? Theme.of(context).colorScheme.onSurface;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: foreground.withAlpha(14),
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: foreground.withAlpha(45)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: foreground),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: foreground),
            ),
          ),
          if (action != null) ...[
            const SizedBox(width: AppSpacing.sm),
            action!,
          ],
        ],
      ),
    );
  }
}

class CoverArt extends StatelessWidget {
  final Map track;
  final double size;
  final bool round;

  const CoverArt(
    this.track, {
    this.size = 52,
    this.round = false,
    super.key,
  });

  Widget _fallback(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF294A37), Color(0xFF132019)],
        ),
        borderRadius: BorderRadius.circular(round ? size / 2 : AppRadii.sm),
      ),
      child: Icon(
        Icons.graphic_eq_rounded,
        size: size * 0.46,
        color: Theme.of(context).colorScheme.primary.withAlpha(190),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rawUrl = track['coverUrl']?.toString().trim();
    final hasUrl = rawUrl != null && rawUrl.isNotEmpty && rawUrl != 'null';
    final title = track['title']?.toString() ?? 'Track cover';
    final radius = BorderRadius.circular(round ? size / 2 : AppRadii.sm);

    return Semantics(
      image: true,
      label: '$title cover',
      child: ClipRRect(
        borderRadius: radius,
        child: !hasUrl
            ? _fallback(context)
            : Image.network(
                rawUrl!,
                width: size,
                height: size,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.low,
                frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                  if (wasSynchronouslyLoaded || frame != null) return child;
                  return _fallback(context);
                },
                errorBuilder: (_, __, ___) => _fallback(context),
              ),
      ),
    );
  }
}

class TrackTile extends StatelessWidget {
  final Map track;
  final Widget? trailing;
  final VoidCallback? onTap;
  final String? badge;
  final bool selected;
  final String? subtitle;

  const TrackTile(
    this.track, {
    this.trailing,
    this.onTap,
    this.badge,
    this.selected = false,
    this.subtitle,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final artist = track['artist']?.toString().trim();
    final detail = subtitle ??
        (artist == null || artist.isEmpty || artist == 'null'
            ? 'Unknown artist'
            : artist);

    return Material(
      color: selected
          ? theme.colorScheme.primary.withAlpha(18)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            children: [
              if (badge != null)
                SizedBox(
                  width: 36,
                  child: Text(
                    badge!,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: selected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface.withAlpha(145),
                    ),
                  ),
                ),
              CoverArt(track),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      track['title']?.toString() ?? 'Untitled track',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      detail,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: AppSpacing.xs),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class PreviewButtonWithHint extends StatelessWidget {
  final Map track;

  const PreviewButtonWithHint(this.track, {super.key});

  @override
  Widget build(BuildContext context) {
    final url = track['previewUrl']?.toString().trim();
    if (url == null || url.isEmpty || url == 'null') {
      return Tooltip(
        message: 'No preview is available for this track',
        child: IconButton(
          onPressed: null,
          icon: const Icon(Icons.music_off_rounded),
        ),
      );
    }
    return PreviewButton(track);
  }
}

String friendlyErr(Object error, {String fallback = 'Something went wrong'}) {
  if (error is ApiException) {
    final message = error.message.trim();
    if (error.status == 400 || message.contains('Validation')) {
      return 'Check the entered details and try again.';
    }
    if (error.status == 401) {
      return 'Your session has expired. Sign in again and retry.';
    }
    if (error.status == 403) {
      return 'You do not have permission for this action. Ask the room owner.';
    }
    if (error.status == 404) {
      return 'That item no longer exists. Refresh and try again.';
    }
    if (error.status == 409) {
      return message.toLowerCase().contains('already')
          ? 'You have already voted for this track.'
          : 'Someone changed this first. The latest version was loaded.';
    }
    if (error.status >= 500) {
      return 'The server could not complete the request. Try again shortly.';
    }
    return message.isEmpty ? fallback : message;
  }

  final message = error.toString().replaceFirst('Exception: ', '').trim();
  final lower = message.toLowerCase();
  if (lower.contains('socket') ||
      lower.contains('failed host lookup') ||
      lower.contains('connection refused')) {
    return 'Cannot reach the Music Room server. Check the backend URL and connection.';
  }
  if (lower.contains('timeout')) {
    return 'The request took too long. Check your connection and retry.';
  }
  return message.isEmpty ? fallback : message;
}

class GradientHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? artUrl;
  final double height;
  final Widget? action;

  const GradientHeader(
    this.title, {
    this.subtitle,
    this.artUrl,
    this.height = 220,
    this.action,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final rawUrl = artUrl?.toString().trim();
    final hasUrl = rawUrl != null && rawUrl.isNotEmpty && rawUrl != 'null';

    return LayoutBuilder(
      builder: (context, constraints) {
        final responsiveHeight = height.clamp(
          190.0,
          constraints.maxWidth < 600 ? 210.0 : 260.0,
        );
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(AppRadii.lg),
          ),
          child: SizedBox(
            height: responsiveHeight,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF315A3D), Color(0xFF10251A)],
                    ),
                  ),
                ),
                if (hasUrl)
                  Opacity(
                    opacity: 0.5,
                    child: ImageFiltered(
                      imageFilter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                      child: Transform.scale(
                        scale: 1.12,
                        child: Image.network(
                          rawUrl!,
                          fit: BoxFit.cover,
                          filterQuality: FilterQuality.low,
                          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                        ),
                      ),
                    ),
                  ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x18000000),
                        Color(0xCC07100B),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'MUSIC ROOM · LIVE',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      letterSpacing: 1.5,
                                    ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .displaySmall
                                    ?.copyWith(color: Colors.white),
                              ),
                              if (subtitle != null) ...[
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  subtitle!,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Colors.white.withAlpha(190),
                                      ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (action != null) ...[
                          const SizedBox(width: AppSpacing.md),
                          action!,
                        ],
                      ],
                    ),
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

class ShelfCard extends StatelessWidget {
  final Map track;
  final VoidCallback? onPlay;
  final VoidCallback? onTap;

  const ShelfCard(this.track, {this.onPlay, this.onTap, super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final preview = track['previewUrl']?.toString().trim();
    final hasPreview = preview != null && preview.isNotEmpty && preview != 'null';

    return SizedBox(
      width: 168,
      child: Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CoverArt(track, size: 144),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Tooltip(
                          message: hasPreview
                              ? 'Play preview'
                              : 'Preview unavailable',
                          child: IconButton.filled(
                            onPressed:
                                hasPreview && onPlay != null ? onPlay : null,
                            icon: const Icon(Icons.play_arrow_rounded),
                            style: IconButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: theme.colorScheme.onPrimary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  track['title']?.toString() ?? 'Untitled track',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 2),
                Text(
                  track['artist']?.toString() ?? 'Unknown artist',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CollageHeader extends StatelessWidget {
  final List<dynamic> tracks;
  final String title;
  final String subtitle;

  const CollageHeader({
    required this.tracks,
    required this.title,
    required this.subtitle,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 470;
        final artSize = compact ? 88.0 : 116.0;
        final copy = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        );

        final collage = ClipRRect(
          borderRadius: BorderRadius.circular(AppRadii.md),
          child: SizedBox.square(
            dimension: artSize,
            child: GridView.count(
              crossAxisCount: 2,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              children: List.generate(4, (index) {
                if (index < tracks.length && tracks[index] is Map) {
                  return CoverArt(tracks[index] as Map, size: artSize);
                }
                return ColoredBox(
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest,
                  child: const Icon(Icons.music_note_rounded),
                );
              }),
            ),
          ),
        );

        if (compact) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              collage,
              const SizedBox(width: AppSpacing.md),
              Expanded(child: copy),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            collage,
            const SizedBox(width: AppSpacing.lg),
            Expanded(child: copy),
          ],
        );
      },
    );
  }
}

class Stagger extends StatefulWidget {
  final int index;
  final Widget child;

  const Stagger({required this.index, required this.child, super.key});

  @override
  State<Stagger> createState() => _StaggerState();
}

class _StaggerState extends State<Stagger> {
  bool _shown = false;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) {
      _shown = true;
      return;
    }
    Future<void>.delayed(
      Duration(milliseconds: (widget.index * 45).clamp(0, 450)),
      () {
        if (mounted) setState(() => _shown = true);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: AppDurations.reveal,
      opacity: _shown ? 1 : 0,
      child: AnimatedSlide(
        duration: AppDurations.reveal,
        curve: Curves.easeOutCubic,
        offset: _shown ? Offset.zero : const Offset(0, 0.06),
        child: widget.child,
      ),
    );
  }
}

class ShimmerRow extends StatefulWidget {
  const ShimmerRow({super.key});

  @override
  State<ShimmerRow> createState() => _ShimmerRowState();
}

class _ShimmerRowState extends State<ShimmerRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.surfaceContainerHighest;
    return FadeTransition(
      opacity: Tween<double>(begin: 0.35, end: 0.8).animate(_controller),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: base,
                borderRadius: BorderRadius.circular(AppRadii.sm),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FractionallySizedBox(
                    widthFactor: 0.82,
                    child: Container(
                      height: 12,
                      decoration: BoxDecoration(
                        color: base,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  FractionallySizedBox(
                    widthFactor: 0.48,
                    child: Container(
                      height: 10,
                      decoration: BoxDecoration(
                        color: base,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}