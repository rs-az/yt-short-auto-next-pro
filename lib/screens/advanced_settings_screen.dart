import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/app_settings.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';

class AdvancedSettingsScreen extends StatefulWidget {
  const AdvancedSettingsScreen({super.key});

  @override
  State<AdvancedSettingsScreen> createState() => _AdvancedSettingsScreenState();
}

class _AdvancedSettingsScreenState extends State<AdvancedSettingsScreen> {
  int _tabIndex = 0;
  bool _showSavedToast = false;

  static const _priorityMeta = {
    'keyboard': (
      title: 'Simulate Arrow Down Key',
      desc: 'Dispatches arrow event to document/video',
    ),
    'button': (
      title: 'Click Next Button',
      desc: 'Finds and clicks the next-video DOM button',
    ),
    'scroll': (
      title: 'Viewport Scroll',
      desc: 'Scrolls to the next Short in the reel',
    ),
  };

  void _showToast() {
    setState(() => _showSavedToast = true);
    Future<void>.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _showSavedToast = false);
    });
  }

  Future<void> _save(AppState appState, AppSettings Function(AppSettings) patch) async {
    await appState.patchSettings(patch);
    _showToast();
  }

  Future<void> _exportSettings(AppState appState) async {
    final backup = await appState.exportBackup();
    final jsonText = const JsonEncoder.withIndent('  ').convert(backup);
    await SharePlus.instance.share(
      ShareParams(text: jsonText, subject: 'YouTube Shorts Auto Next Pro Backup'),
    );
  }

  Future<void> _importSettings(AppState appState) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result == null || result.files.single.bytes == null) return;

    try {
      final text = utf8.decode(result.files.single.bytes!);
      final backup = jsonDecode(text) as Map<String, dynamic>;
      await appState.importBackup(backup);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Configuration imported successfully')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to parse settings JSON')),
        );
      }
    }
  }

  Future<void> _factoryReset(AppState appState) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Factory reset?'),
        content: const Text(
          'Restore the app to factory defaults? All settings and today\'s statistics will be erased.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Reset')),
        ],
      ),
    );
    if (confirmed == true) {
      await appState.factoryReset();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('App restored to factory defaults')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final settings = appState.settings;

    return Scaffold(
      appBar: AppBar(title: const Text('Advanced Settings')),
      body: Stack(
        children: [
          Row(
            children: [
              NavigationRail(
                selectedIndex: _tabIndex,
                onDestinationSelected: (index) => setState(() => _tabIndex = index),
                labelType: NavigationRailLabelType.all,
                destinations: const [
                  NavigationRailDestination(
                    icon: Icon(Icons.tune),
                    label: Text('General'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.navigation),
                    label: Text('Navigation'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.backup),
                    label: Text('Data'),
                  ),
                ],
              ),
              const VerticalDivider(width: 1),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: switch (_tabIndex) {
                    0 => _GeneralTab(
                        settings: settings,
                        onSave: (patch) => _save(appState, patch),
                      ),
                    1 => _NavigationTab(
                        settings: settings,
                        onSave: (patch) => _save(appState, patch),
                      ),
                    2 => _DataTab(
                        onExport: () => _exportSettings(appState),
                        onImport: () => _importSettings(appState),
                        onFactoryReset: () => _factoryReset(appState),
                      ),
                    _ => const SizedBox.shrink(),
                  },
                ),
              ),
            ],
          ),
          if (_showSavedToast)
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Settings saved',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _GeneralTab extends StatelessWidget {
  const _GeneralTab({required this.settings, required this.onSave});

  final AppSettings settings;
  final Future<void> Function(AppSettings Function(AppSettings)) onSave;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'General Settings',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        _SettingsCard(
          title: 'Theme & Appearance',
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                initialValue: settings.theme,
                decoration: const InputDecoration(labelText: 'Visual Theme'),
                items: const [
                  DropdownMenuItem(value: 'system', child: Text('Follow System')),
                  DropdownMenuItem(value: 'dark', child: Text('Dark Theme')),
                  DropdownMenuItem(value: 'light', child: Text('Light Theme')),
                ],
                onChanged: (value) {
                  if (value != null) onSave((s) => s.copyWith(theme: value));
                },
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Enable UI Transitions & Animations'),
                value: settings.animationEnabled,
                onChanged: (value) => onSave((s) => s.copyWith(animationEnabled: value)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _SettingsCard(
          title: 'Behavior & Alerts',
          child: Column(
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Enable Notifications on Auto Advance'),
                value: settings.notificationsEnabled,
                onChanged: (value) => onSave((s) => s.copyWith(notificationsEnabled: value)),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Enable Debug Console Logging'),
                value: settings.loggingEnabled,
                onChanged: (value) => onSave((s) => s.copyWith(loggingEnabled: value)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NavigationTab extends StatelessWidget {
  const _NavigationTab({required this.settings, required this.onSave});

  final AppSettings settings;
  final Future<void> Function(AppSettings Function(AppSettings)) onSave;

  void _movePriority(BuildContext context, int index, int direction) {
    final list = List<String>.from(settings.navigationPriority);
    final target = index + direction;
    if (target < 0 || target >= list.length) return;
    final item = list.removeAt(index);
    list.insert(target, item);
    onSave((s) => s.copyWith(navigationPriority: list));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Navigation & Robustness',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        _SettingsCard(
          title: 'Navigation Priority',
          child: Column(
            children: [
              for (var i = 0; i < settings.navigationPriority.length; i++)
                _PriorityRow(
                  method: settings.navigationPriority[i],
                  onMoveUp: i > 0 ? () => _movePriority(context, i, -1) : null,
                  onMoveDown: i < settings.navigationPriority.length - 1
                      ? () => _movePriority(context, i, 1)
                      : null,
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _SettingsCard(
          title: 'Retry Policy',
          child: TextFormField(
            initialValue: settings.maxRetries.toString(),
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Max Retries per Navigation Method',
            ),
            onChanged: (text) {
              final value = int.tryParse(text) ?? 3;
              onSave((s) => s.copyWith(maxRetries: value));
            },
          ),
        ),
      ],
    );
  }
}

class _DataTab extends StatelessWidget {
  const _DataTab({
    required this.onExport,
    required this.onImport,
    required this.onFactoryReset,
  });

  final Future<void> Function() onExport;
  final Future<void> Function() onImport;
  final Future<void> Function() onFactoryReset;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Data & Backup',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        _SettingsCard(
          title: 'Backup & Restore',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton(onPressed: onExport, child: const Text('Export Settings JSON')),
              const SizedBox(height: 10),
              OutlinedButton(onPressed: onImport, child: const Text('Import Settings JSON')),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _SettingsCard(
          title: 'Factory Reset',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Restore all settings and statistics to defaults.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger),
                onPressed: onFactoryReset,
                child: const Text('Factory Reset'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _PriorityRow extends StatelessWidget {
  const _PriorityRow({
    required this.method,
    required this.onMoveUp,
    required this.onMoveDown,
  });

  final String method;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;

  @override
  Widget build(BuildContext context) {
    final meta = _AdvancedSettingsScreenState._priorityMeta[method];
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(meta?.title ?? method, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(
                  meta?.desc ?? '',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(onPressed: onMoveUp, icon: const Icon(Icons.arrow_upward)),
          IconButton(onPressed: onMoveDown, icon: const Icon(Icons.arrow_downward)),
        ],
      ),
    );
  }
}
