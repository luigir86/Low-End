import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../widgets/pulsing_dot.dart';

/// A sound that is currently playing somewhere in the app.
class ActiveSound {
  const ActiveSound({
    required this.icon,
    required this.label,
    required this.onStop,
  });

  final IconData icon;
  final String label;
  final VoidCallback onStop;
}

/// Thin strip above the navigation bar listing the sounds that are playing,
/// each with its own stop button. Hidden when nothing plays.
class NowPlayingStrip extends StatelessWidget {
  const NowPlayingStrip({super.key, required this.sounds});

  final List<ActiveSound> sounds;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      child: sounds.isEmpty
          ? const SizedBox(width: double.infinity)
          : Material(
              color: colors.secondaryContainer,
              child: SafeArea(
                top: false,
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      for (final sound in sounds)
                        SizedBox(
                          height: 48,
                          child: Row(
                            children: [
                              const PulsingDot(),
                              const SizedBox(width: 12),
                              Icon(sound.icon, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  sound.label,
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.stop_rounded),
                                tooltip: l10n.stopSound(sound.label),
                                onPressed: sound.onStop,
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
