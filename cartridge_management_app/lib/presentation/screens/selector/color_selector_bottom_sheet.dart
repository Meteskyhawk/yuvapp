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
  String? selectedColorCode;

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
          const SizedBox(height: 4),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 16),
            child: Align(
              alignment: Alignment.topLeft,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFCE8E6),
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.close,
                    color: Color(0xFFE53935),
                    size: 18,
                  ),
                  padding: EdgeInsets.zero,
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ),
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.45,
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 5,
                crossAxisSpacing: 5,
                childAspectRatio: 1.0,
              ),
              itemCount: colors.length,
              itemBuilder: (context, index) {
                final entry = colors.entries.elementAt(index);
                final isSelected = selectedColorCode == entry.key;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedColorCode = entry.key;
                    });
                  },
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (isSelected)
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: CustomPaint(
                              size: const Size(90, 90),
                              painter: DashedCirclePainter(
                                color: const Color(0xFFAAAAAA),
                                strokeWidth: 2.0,
                                dashSize: 1,
                                gapSize: 1,
                              ),
                            ),
                          ),
                        ),
                      Container(
                        width: 100,
                        height: 100,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          image: DecorationImage(
                            image: AssetImage('assets/greyholder.png'),
                            fit: BoxFit.cover,
                          ),
                        ),
                        child: Center(
                          child: Align(
                            alignment: const Alignment(0, -0.18),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: entry.value.backgroundColor,
                              ),
                              child: Center(
                                child: Text(
                                  entry.key,
                                  style: TextStyle(
                                    color: entry.value.textColor,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: SizedBox(
              width: double.infinity,
              height: 55,
              child: TextButton(
                onPressed: () {
                  if (selectedColorCode != null) {
                    _saveSelectedColor(context);
                  }
                },
                style: TextButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9),
                  ),
                  padding: EdgeInsets.zero,
                ),
                child: const Text(
                  'Save',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _saveSelectedColor(BuildContext context) async {
    if (selectedColorCode == null) return;

    final state = context.read<CartridgeBloc>().state;
    if (state is CartridgeLoaded) {
      // Check if color is already in use
      final isColorDuplicate =
          state.cartridges.any((c) => c.colorCode == selectedColorCode);

      if (isColorDuplicate) {
        // Bottom sheet'i kapat
        Navigator.pop(context);

        // Callback aracılığıyla ana ekrandaki hata mesajını göster
        if (widget.onDuplicateColor != null) {
          widget.onDuplicateColor!(selectedColorCode!);
        }
        return;
      }

      final nextSlot = _getNextAvailableSlot(context);
      // Check if slot is already occupied
      final isSlotOccupied = state.cartridges.any((c) => c.slot == nextSlot);

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
        colorCode: selectedColorCode!,
        quantity: 200,
        slot: nextSlot,
      );
      context.read<CartridgeBloc>().add(AddCartridge(cartridge));
      Navigator.pop(context);
    }
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

class DashedCirclePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashSize;
  final double gapSize;

  DashedCirclePainter({
    required this.color,
    required this.strokeWidth,
    required this.dashSize,
    required this.gapSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final double radius = size.width / 2;
    final double centerX = size.width / 2;
    final double centerY = size.height / 2;

    // Dashed circle with more segments for better appearance
    final int numDashes = 30;
    final double angleDelta = 2 * 3.14159 / numDashes;
    final double gapAngle = angleDelta * 0.35; // Gap is 35% of segment

    for (int i = 0; i < numDashes; i++) {
      final double startAngle = i * angleDelta;

      canvas.drawArc(
        Rect.fromCircle(center: Offset(centerX, centerY), radius: radius),
        startAngle,
        angleDelta - gapAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
