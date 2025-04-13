import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../../logic/blocs/cartridge/cartridge_bloc.dart';
import '../../../logic/blocs/cartridge/cartridge_event.dart';
import '../../../logic/blocs/cartridge/cartridge_state.dart';
import '../../../data/models/cartridge_model.dart';
import '../../../data/models/color_constants.dart';

class ColorSelectorBottomSheet extends StatefulWidget {
  final List<CartridgeModel>? existingCartridges;
  final Function(String colorCode)? onDuplicateColor;
  final Function(int slotNumber)? onSlotOccupied;

  const ColorSelectorBottomSheet({
    super.key,
    this.existingCartridges,
    this.onDuplicateColor,
    this.onSlotOccupied,
  });

  @override
  State<ColorSelectorBottomSheet> createState() =>
      _ColorSelectorBottomSheetState();
}

class _ColorSelectorBottomSheetState extends State<ColorSelectorBottomSheet> {
  @override
  Widget build(BuildContext context) {
    final colorsList = CartridgeColors.getAllColors();
    final colors = {for (var color in colorsList) color.code: color};

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Cartridge_Selector_002',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.4,
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
              ),
              itemCount: colors.length,
              itemBuilder: (context, index) {
                final entry = colors.entries.elementAt(index);

                return GestureDetector(
                  onTap: () async {
                    final state = context.read<CartridgeBloc>().state;
                    if (state is CartridgeLoaded) {
                      // Check if color is already in use
                      final isColorDuplicate =
                          state.cartridges.any((c) => c.colorCode == entry.key);

                      if (isColorDuplicate) {
                        // Bottom sheet'i kapat
                        Navigator.pop(context);

                        // Callback aracılığıyla ana ekrandaki hata mesajını göster
                        if (widget.onDuplicateColor != null) {
                          widget.onDuplicateColor!(entry.key);
                        }
                        return;
                      }

                      final nextSlot = _getNextAvailableSlot(context);
                      // Check if slot is already occupied
                      final isSlotOccupied =
                          state.cartridges.any((c) => c.slot == nextSlot);

                      if (isSlotOccupied) {
                        // Bottom sheet'i kapat
                        Navigator.pop(context);

                        // Callback aracılığıyla ana ekrandaki hata mesajını göster
                        if (widget.onSlotOccupied != null) {
                          widget.onSlotOccupied!(nextSlot);
                        }
                        return;
                      }

                      final cartridge = CartridgeModel(
                        id: const Uuid().v4(),
                        colorCode: entry.key,
                        quantity: 200,
                        slot: nextSlot,
                      );
                      context
                          .read<CartridgeBloc>()
                          .add(AddCartridge(cartridge));
                      Navigator.pop(context);
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.grey[300]!,
                          Colors.grey[600]!,
                        ],
                        stops: const [0.3, 1.0],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: entry.value.backgroundColor,
                          border: Border.all(
                            color: Colors.grey[400]!,
                            width: 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            entry.key,
                            style: TextStyle(
                              color: entry.value.textColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  int _getNextAvailableSlot(BuildContext context) {
    final state = context.read<CartridgeBloc>().state;
    if (state is! CartridgeLoaded) return 1;

    final usedSlots = state.cartridges.map((c) => c.slot).toList();
    if (usedSlots.isEmpty) return 1;

    for (int i = 1; i <= usedSlots.length + 1; i++) {
      if (!usedSlots.contains(i)) {
        return i;
      }
    }
    return usedSlots.length + 1;
  }
}
