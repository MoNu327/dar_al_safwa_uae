import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../data/model/property_details_model.dart';

class UnitTypeSelector extends StatefulWidget {
  final List<UnitTypeData> unitTypes;
  final int initialSelection;
  final ValueChanged<int> onSelectionConfirmed;

  const UnitTypeSelector({
    super.key,
    required this.unitTypes,
    required this.initialSelection,
    required this.onSelectionConfirmed,
  });

  @override
  State<UnitTypeSelector> createState() => _UnitTypeSelectorState();
}

class _UnitTypeSelectorState extends State<UnitTypeSelector> {
  late int selectedId;

  @override
  void initState() {
    super.initState();
    selectedId = widget.initialSelection;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 500),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Select Unit Type',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),
              const Divider(height: 24),
              if (widget.unitTypes.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text('No units available'),
                )
              else
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: widget.unitTypes.map((unit) {
                        final isSelected = selectedId == unit.id;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () => setState(() => selectedId = unit.id!),
                            child: Container(
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withOpacity(0.1)
                                    : null,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected
                                      ? Theme.of(context).colorScheme.primary
                                      : Colors.grey.shade300,
                                ),
                              ),
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  Radio<int>(
                                    value: unit!.id!,
                                    groupValue: selectedId,
                                    onChanged: (value) =>
                                        setState(() => selectedId = value!),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          unit?.unitType?.name?.en ?? 'Unit',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 4,
                                          children: [
                                            if (unit.beds != null)
                                              _UnitFeatureChip(
                                                icon: Icons.bed,
                                                label:
                                                    '${unit.beds} ${unit.beds == 1 ? 'Bed' : 'Beds'}',
                                              ),
                                            if (unit.baths != null)
                                              _UnitFeatureChip(
                                                icon: Icons.bathtub,
                                                label:
                                                    '${unit.baths} ${unit.baths == 1 ? 'Bath' : 'Baths'}',
                                              ),
                                            if (unit.area?.en != null)
                                              _UnitFeatureChip(
                                                icon: Icons.aspect_ratio,
                                                label: unit.area!.en!,
                                              ),
                                          ],
                                        ),
                                        if (unit.baseRentAmount?.formatted
                                                ?.en !=
                                            null)
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(top: 8),
                                            child: Text(
                                              unit.baseRentAmount!.formatted!
                                                  .en!,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primary,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  widget.onSelectionConfirmed(selectedId);
                  Get.back();
                },
                child: const Text('Confirm Selection'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Helper widget for unit features
class _UnitFeatureChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _UnitFeatureChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Chip(
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      labelPadding: const EdgeInsets.symmetric(horizontal: 4),
      backgroundColor: Colors.grey.shade200,
      side: BorderSide.none,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
