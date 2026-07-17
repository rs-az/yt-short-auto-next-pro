import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/app_state.dart';
import '../theme/app_theme.dart';
import 'advanced_settings_screen.dart';

class QuickSettingsSheet extends StatelessWidget {
  const QuickSettingsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final settings = appState.settings;
    final stats = appState.stats;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              _Header(enabled: settings.enabled, onChanged: (value) {
                appState.patchSettings((s) => s.copyWith(enabled: value));
              }),
              const SizedBox(height: 16),
              _StatusBanner(enabled: settings.enabled),
              const SizedBox(height: 20),
              const _SectionTitle('Quick Settings'),
              const SizedBox(height: 12),
              _DropdownField(
                label: 'Delay Before Next',
                value: settings.delay.toString(),
                items: const {
                  '0': 'Immediate (0s)',
                  '1': '1 second',
                  '2': '2 seconds',
                  '3': '3 seconds',
                  '5': '5 seconds',
                  'custom': 'Custom value...',
                },
                onChanged: (value) {
                  if (value == null) return;
                  appState.patchSettings(
                    (s) => s.copyWith(
                      delay: value == 'custom' ? 'custom' : int.tryParse(value) ?? 0,
                    ),
                  );
                },
              ),
              if (settings.delay.toString() == 'custom') ...[
                const SizedBox(height: 12),
                _NumberField(
                  label: 'Custom Delay (seconds)',
                  value: settings.customDelay,
                  onChanged: (value) {
                    appState.patchSettings((s) => s.copyWith(customDelay: value));
                  },
                ),
              ],
              const SizedBox(height: 12),
              _DropdownField(
                label: 'Skip Long Videos',
                value: settings.skipLongVideos,
                items: const {
                  'disabled': 'Disabled',
                  '30': 'Longer than 30s',
                  '45': 'Longer than 45s',
                  '60': 'Longer than 60s',
                  '90': 'Longer than 90s',
                },
                onChanged: (value) {
                  if (value == null) return;
                  appState.patchSettings((s) => s.copyWith(skipLongVideos: value));
                },
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Randomize Delay',
                  style: TextStyle(color: AppColors.textPrimary),
                ),
                subtitle: const Text(
                  'Adds 0–1.5s delay to mimic human behavior',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
                value: settings.randomDelay,
                onChanged: (value) {
                  appState.patchSettings((s) => s.copyWith(randomDelay: value));
                },
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Expanded(child: _SectionTitle("Today's Statistics")),
                  TextButton(
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Reset statistics?'),
                          content: const Text(
                            "Are you sure you want to reset today's statistics?",
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Reset'),
                            ),
                          ],
                        ),
                      );
                      if (confirmed == true && context.mounted) {
                        await appState.resetStats();
                      }
                    },
                    child: const Text('Reset'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _StatsGrid(stats: stats),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const AdvancedSettingsScreen(),
                      ),
                    );
                  },
                  child: const Text('Open Advanced Settings'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.enabled, required this.onChanged});

  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text('⏭️', style: TextStyle(fontSize: 24)),
        const SizedBox(width: 10),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Auto Next Pro',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'v1.0.0',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
              ),
            ],
          ),
        ),
        Switch(value: enabled, onChanged: onChanged),
      ],
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.enabled});

  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: enabled
            ? AppColors.accent.withValues(alpha: 0.12)
            : AppColors.bgCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: enabled ? AppColors.accent.withValues(alpha: 0.4) : AppColors.border,
        ),
      ),
      child: Text(
        enabled ? 'Auto Next is Active' : 'Auto Next is Paused',
        style: TextStyle(
          color: enabled ? AppColors.accent : AppColors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _DropdownField extends StatelessWidget {
  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final String value;
  final Map<String, String> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: value,
          dropdownColor: AppColors.bgCard,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          items: items.entries
              .map(
                (entry) => DropdownMenuItem<String>(
                  value: entry.key,
                  child: Text(entry.value),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        const SizedBox(height: 6),
        TextFormField(
          initialValue: value.toString(),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          onChanged: (text) => onChanged(double.tryParse(text) ?? 0),
        ),
      ],
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.stats});

  final dynamic stats;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.8,
      children: [
        _StatCard(label: 'Watched', value: '${stats.watchedCount}'),
        _StatCard(label: 'Skipped', value: '${stats.skippedCount}'),
        _StatCard(label: 'Session', value: '${stats.sessionDuration}m'),
        _StatCard(label: 'Avg Watch', value: '${stats.averageWatchTime}s'),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        ],
      ),
    );
  }
}
