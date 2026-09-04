import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../domain/models/model_info.dart';

class ModelPicker extends ConsumerWidget {
  const ModelPicker({
    super.key,
    required this.selectedModelId,
    required this.onSelected,
    this.filterCapability,
  });

  final String selectedModelId;
  final ValueChanged<String> onSelected;
  final ModelCapability? filterCapability;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalogAsync = ref.watch(modelCatalogProvider);
    return catalogAsync.when(
      loading: () => const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      error: (e, _) => Text('Catalog error', style: TextStyle(color: Theme.of(context).colorScheme.error)),
      data: (catalog) {
        var models = filterCapability == null
            ? catalog.all()
            : catalog.byCapability(filterCapability!);
        if (models.isEmpty) models = catalog.all();

        final selected = catalog.find(selectedModelId) ??
            (models.isNotEmpty ? models.first : null);

        return PopupMenuButton<String>(
          tooltip: 'Select model',
          onSelected: onSelected,
          itemBuilder: (context) {
            return [
              for (final m in models)
                PopupMenuItem(
                  value: m.id,
                  child: _ModelRow(model: m, selected: m.id == selectedModelId),
                ),
            ];
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: DotColors.paperLine),
              borderRadius: BorderRadius.circular(10),
              color: DotColors.paperElevated,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.smart_toy_outlined, size: 18),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    selected?.name ?? selectedModelId,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
                const SizedBox(width: 6),
                if (selected != null) ...[
                  for (final cap in _visibleCaps(selected.capabilities))
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: CapabilityChip(capability: cap, compact: true),
                    ),
                ],
                const Icon(Icons.expand_more, size: 18),
              ],
            ),
          ),
        );
      },
    );
  }

  List<ModelCapability> _visibleCaps(Set<ModelCapability> caps) {
    const order = [
      ModelCapability.chat,
      ModelCapability.image,
      ModelCapability.video,
      ModelCapability.audio,
    ];
    return order.where(caps.contains).toList();
  }
}

class _ModelRow extends StatelessWidget {
  const _ModelRow({required this.model, required this.selected});

  final ModelInfo model;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (selected)
          const Icon(Icons.check, size: 16, color: DotColors.amberDeep)
        else
          const SizedBox(width: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(model.name, style: Theme.of(context).textTheme.bodyMedium),
              Text(
                model.providerType.name,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        for (final cap in [
          ModelCapability.chat,
          ModelCapability.image,
          ModelCapability.video,
          ModelCapability.audio,
        ])
          if (model.capabilities.contains(cap))
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: CapabilityChip(capability: cap, compact: true),
            ),
      ],
    );
  }
}

class CapabilityChip extends StatelessWidget {
  const CapabilityChip({
    super.key,
    required this.capability,
    this.compact = false,
  });

  final ModelCapability capability;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final label = switch (capability) {
      ModelCapability.chat => 'chat',
      ModelCapability.image => 'image',
      ModelCapability.video => 'video',
      ModelCapability.audio => 'audio',
      ModelCapability.embedding => 'embed',
    };
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 5 : 8,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE8B8),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: compact ? 9 : 11,
          fontWeight: FontWeight.w700,
          color: DotColors.ink,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
