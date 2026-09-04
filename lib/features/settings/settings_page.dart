import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../data/sync/drive_sync_service.dart';
import 'providers_settings.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final driveAsync = ref.watch(driveStatusProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
      children: [
        Text('Settings', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text(
          'Bring your own keys. Secrets stay in the device vault — never in the local DB.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: DotColors.textSecondary,
              ),
        ),
        if (kIsWeb) ...[
          const SizedBox(height: 16),
          const _SecurityNote(),
        ],
        const SizedBox(height: 28),
        Text('Providers', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        const ProvidersSettings(),
        const SizedBox(height: 32),
        Text('Context & memory', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.menu_book_outlined),
          title: const Text('Custom context & memory pins'),
          subtitle: const Text('Global, project, plan, and chat scopes'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.go('/context'),
        ),
        const SizedBox(height: 24),
        Text('Backup & sync', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(
          'Optional encrypted backup overlay (Google Drive when OAuth is '
          'configured, otherwise a local mirror). Local data remains the '
          'source of truth.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        driveAsync.when(
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => Text('$e'),
          data: (status) => _DriveSection(status: status),
        ),
      ],
    );
  }
}

class _SecurityNote extends StatelessWidget {
  const _SecurityNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3D6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DotColors.amber.withOpacity(0.5)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lock_outline, color: DotColors.inkMuted),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Web note: secure storage on browsers is weaker than OS keychains. '
              'Prefer desktop/mobile for long-lived API keys, and keep Drive key backup off.',
              style: TextStyle(color: DotColors.textPrimary, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _DriveSection extends ConsumerWidget {
  const _DriveSection({required this.status});

  final DriveSyncStatus status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.read(driveSyncServiceProvider);
    final connected = status.isConnected;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Status: ${status.state.name}'
          '${status.backendLabel != null ? ' (${status.backendLabel})' : ''}'
          '${status.message != null ? ' — ${status.message}' : ''}',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        if (status.lastSyncAt != null)
          Text(
            'Last sync: ${status.lastSyncAt!.toLocal()}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        if (status.isLocalMirror)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Local mirror mode: encrypted blob is stored on this device '
              '(documents/.drive_mirror/backup.ddd). Add Google OAuth client '
              'IDs to enable cloud Drive sync.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: DotColors.textSecondary,
                  ),
            ),
          ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (!connected)
              FilledButton.icon(
                onPressed: () => service.connect(),
                icon: const Icon(Icons.cloud_outlined),
                label: const Text('Connect sync'),
              )
            else ...[
              OutlinedButton.icon(
                onPressed: status.state == DriveConnectionState.syncing
                    ? null
                    : () => service.syncNow(),
                icon: const Icon(Icons.sync),
                label: const Text('Sync now'),
              ),
              TextButton(
                onPressed: () => service.disconnect(),
                child: const Text('Disconnect'),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Include API keys in backup'),
          subtitle: Text(
            kIsWeb
                ? 'Disabled recommendation on web'
                : 'Off by default — keys stay in the device vault',
          ),
          value: status.backupKeysEnabled,
          onChanged: kIsWeb
              ? null
              : (v) => service.setBackupKeysEnabled(v),
        ),
      ],
    );
  }
}
