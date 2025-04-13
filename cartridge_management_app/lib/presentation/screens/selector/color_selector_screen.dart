import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../../logic/blocs/cartridge/cartridge_bloc.dart';
import '../../../logic/blocs/cartridge/cartridge_event.dart';
import '../../../data/models/cartridge_model.dart';
import '../../../data/models/color_constants.dart';

class ColorSelectorScreen extends StatefulWidget {
  const ColorSelectorScreen({super.key});

  @override
  State<ColorSelectorScreen> createState() => _ColorSelectorScreenState();
}

class _ColorSelectorScreenState extends State<ColorSelectorScreen> {
  String? selectedColor;
  final TextEditingController _slotController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final colors = CartridgeColors.getAllColors();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Cartridge_Selector_002',
          style: TextStyle(color: Colors.grey),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(24),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
              ),
              itemCount: colors.length,
              itemBuilder: (context, index) {
                final color = colors[index];
                final isSelected = color.code == selectedColor;

                return GestureDetector(
                  onTap: () => setState(() => selectedColor = color.code),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFE0E0E0),
                      border: isSelected
                          ? Border.all(
                              color: Colors.blue,
                              width: 2,
                              style: BorderStyle.solid,
                            )
                          : null,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color.backgroundColor,
                          border: color.hasBorder
                              ? Border.all(color: Colors.grey[400]!)
                              : null,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            color.code,
                            style: TextStyle(
                              color: color.textColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
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
          if (selectedColor != null)
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _slotController,
                      decoration: const InputDecoration(
                        labelText: 'Slot',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _quantityController,
                      decoration: const InputDecoration(
                        labelText: 'Quantity (g)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: selectedColor == null ? null : _saveCartridge,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Save',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _saveCartridge() {
    if (selectedColor == null) return;

    final cartridge = CartridgeModel(
      id: const Uuid().v4(),
      colorCode: selectedColor!,
      quantity: int.tryParse(_quantityController.text) ?? 100,
      slot: int.tryParse(_slotController.text) ?? 1,
    );

    context.read<CartridgeBloc>().add(AddCartridge(cartridge));
    Navigator.pop(context);
  }
}
