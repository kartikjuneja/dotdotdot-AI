import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../domain/models/provider_account.dart';

class ProvidersSettings extends ConsumerWidget {
  const ProvidersSettings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(providerAccountsStreamProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        accountsAsync.when(
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => Text('$e'),
          data: (accounts) {
            if (accounts.isEmpty) {
              return const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text(
                  'No providers yet. Add OpenAI, Gemini, or OpenRouter below.',
                  style: TextStyle(color: DotColors.textSecondary),
                ),
              );
            }
            return Column(
              children: [
                for (final account in accounts)
                  _AccountTile(account: account),
              ],
            );
          },
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: () => _showAddDialog(context, ref),
            icon: const Icon(Icons.vpn_key_outlined),
            label: const Text('Add provider key'),
          ),
        ),
      ],
    );
  }

  Future<void> _showAddDialog(BuildContext context, WidgetRef ref) async {
    await showDialog<void>(
      context: context,
      builder: (context) => const _AddProviderDialog(),
    );
  }
}

class _AccountTile extends ConsumerWidget {
  const _AccountTile({required this.account});

  final ProviderAccount account;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        Icons.cloud_done_outlined,
        color: account.enabled ? DotColors.success : DotColors.textSecondary,
      ),
      title: Text(
        account.displayName,
        style: const TextStyle(color: DotColors.textPrimary),
      ),
      subtitle: Text(
        '${account.providerType.name} · vault:${account.keyVaultRef}',
        style: const TextStyle(color: DotColors.textSecondary),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Switch(
            value: account.enabled,
            onChanged: (v) async {
              await ref.read(providerRepositoryProvider).save(
                    account.copyWith(
                      enabled: v,
                      updatedAt: ref.read(clockProvider).now(),
                    ),
                  );
            },
          ),
          IconButton(
            tooltip: 'Remove',
            onPressed: () async {
              await ref.read(keyVaultProvider).deleteKey(account.keyVaultRef);
              await ref.read(providerRepositoryProvider).softDelete(
                    account.id,
                    deletedAt: ref.read(clockProvider).now(),
                  );
            },
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
    );
  }
}

class _AddProviderDialog extends ConsumerStatefulWidget {
  const _AddProviderDialog();

  @override
  ConsumerState<_AddProviderDialog> createState() => _AddProviderDialogState();
}

class _AddProviderDialogState extends ConsumerState<_AddProviderDialog> {
  ProviderType _type = ProviderType.openai;
  final _nameCtrl = TextEditingController();
  final _keyCtrl = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameCtrl.text = 'OpenAI';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _keyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add provider'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<ProviderType>(
              value: _type,
              decoration: const InputDecoration(labelText: 'Provider'),
              items: [
                for (final t in ProviderType.values)
                  DropdownMenuItem(
                    value: t,
                    child: Text(_label(t)),
                  ),
              ],
              onChanged: (v) {
                if (v == null) return;
                setState(() {
                  _type = v;
                  if (_nameCtrl.text.isEmpty ||
                      _nameCtrl.text == 'OpenAI' ||
                      _nameCtrl.text == 'Gemini' ||
                      _nameCtrl.text == 'OpenRouter') {
                    _nameCtrl.text = _label(v);
                  }
                });
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Display name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _keyCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'API key',
                hintText: 'Paste key — stored in secure vault only',
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: DotColors.danger)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }

  String _label(ProviderType t) => switch (t) {
        ProviderType.openai => 'OpenAI',
        ProviderType.gemini => 'Gemini',
        ProviderType.openrouter => 'OpenRouter',
      };

  Future<void> _save() async {
    final key = _keyCtrl.text.trim();
    final name = _nameCtrl.text.trim();
    if (key.isEmpty || name.isEmpty) {
      setState(() => _error = 'Name and API key are required');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final id = ref.read(uuidProvider).next();
      final vaultRef = id;
      await ref.read(keyVaultProvider).saveKey(vaultRef, key);
      final account = ProviderAccount(
        id: id,
        providerType: _type,
        displayName: name,
        keyVaultRef: vaultRef,
        enabled: true,
        updatedAt: ref.read(clockProvider).now(),
      );
      await ref.read(providerRepositoryProvider).save(account);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() {
        _error = '$e';
        _saving = false;
      });
    }
  }
}
