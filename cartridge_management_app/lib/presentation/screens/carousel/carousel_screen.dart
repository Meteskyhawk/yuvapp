import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../logic/blocs/cartridge/cartridge_bloc.dart';
import '../../../logic/blocs/cartridge/cartridge_state.dart';
import '../../../data/models/cartridge_model.dart';
import '../../../data/models/color_constants.dart';
import 'dart:math' as math;

class CarouselScreen extends StatelessWidget {
  const CarouselScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Column(
          children: [
            Text(
              'Inventory levels',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black,
              ),
            ),
            Text(
              'YUV Lab 1',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: BlocBuilder<CartridgeBloc, CartridgeState>(
        builder: (context, state) {
          if (state is CartridgeLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is CartridgeLoaded) {
            final cartridges = state.cartridges;
            final duplicates = _findDuplicates(cartridges);
            const totalSlots = 11;

            return Column(
              children: [
                Expanded(
                  child: Center(
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width * 0.98,
                      height: MediaQuery.of(context).size.width * 0.98,
                      child: Stack(
                        alignment: Alignment.center,
                        children: List.generate(totalSlots, (index) {
                          final angle = (2 * math.pi * index) / totalSlots;
                          final cartridge = cartridges.firstWhere(
                            (c) => c.slot == index + 1,
                            orElse: () => CartridgeModel(
                              id: '',
                              colorCode: '',
                              quantity: 0,
                              slot: index + 1,
                            ),
                          );

                          return Transform.translate(
                            offset: Offset(
                              math.cos(angle - math.pi / 2) * 170,
                              math.sin(angle - math.pi / 2) * 170,
                            ),
                            child: CartridgeSlot(
                              cartridge: cartridge,
                              isEmpty: cartridge.colorCode.isEmpty,
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                ),
                Container(
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Color(0xFFE0E0E0)),
                    ),
                  ),
                  child: Column(
                    children: [
                      ...cartridges.where((c) {
                        // Only show cartridges that are either High, Change Now, or part of duplicates
                        return c.colorCode.isNotEmpty &&
                            (c.quantity >= 200 ||
                                c.quantity < 30 ||
                                duplicates.contains(c.colorCode));
                      }).map((cartridge) {
                        final color =
                            CartridgeColors.getColorByCode(cartridge.colorCode);
                        if (color == null) return const SizedBox.shrink();

                        // For duplicates, only show "High" for the first occurrence
                        bool isFirstOccurrence = true;
                        if (duplicates.contains(cartridge.colorCode)) {
                          final firstDuplicate = cartridges.firstWhere(
                            (c) => c.colorCode == cartridge.colorCode,
                          );
                          isFirstOccurrence = firstDuplicate.id == cartridge.id;
                        }

                        String status;
                        Color statusColor;

                        if (duplicates.contains(cartridge.colorCode) &&
                            !isFirstOccurrence) {
                          status = 'Duplicated';
                          statusColor = const Color(0xFFFF3B30);
                        } else if (cartridge.quantity >= 200) {
                          status = 'High';
                          statusColor = Colors.black;
                        } else if (cartridge.quantity < 30) {
                          status = 'Change cartridge';
                          statusColor = Colors.orange;
                        } else {
                          return const SizedBox.shrink();
                        }

                        return Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 90,
                                    height: 90,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      image: DecorationImage(
                                        image:
                                            AssetImage('assets/greyholder.png'),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    child: MetallicCartridgeIndicator(
                                      cartridge: cartridge,
                                    ),
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding:
                                          const EdgeInsets.only(right: 16.0),
                                      child: Align(
                                        alignment: Alignment.centerRight,
                                        child: Text(
                                          status,
                                          style: TextStyle(
                                            color: statusColor,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Divider(
                              height: 1,
                              thickness: 1,
                              color: Color(0xFFE0E0E0),
                            ),
                          ],
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Set<String> _findDuplicates(List<CartridgeModel> cartridges) {
    final seen = <String>{};
    final duplicates = <String>{};
    for (final cartridge in cartridges) {
      if (cartridge.colorCode.isEmpty) continue;
      if (!seen.add(cartridge.colorCode)) {
        duplicates.add(cartridge.colorCode);
      }
    }
    return duplicates;
  }
}

class CartridgeSlot extends StatelessWidget {
  final CartridgeModel cartridge;
  final bool isEmpty;

  const CartridgeSlot({
    Key? key,
    required this.cartridge,
    required this.isEmpty,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Dashed circle outline for all slots (empty and filled)
        SizedBox(
          width: 90,
          height: 90,
          child: CustomPaint(
            painter: DashedCirclePainter(
              color: const Color(0xFFAAAAAA),
              strokeWidth: 1.0,
              dashSize: 2,
              gapSize: 2,
            ),
          ),
        ),
        // Empty or filled slot content
        isEmpty
            ? const SizedBox(width: 80, height: 80)
            : SizedBox(
                width: 90,
                height: 90,
                child: Center(
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      image: DecorationImage(
                        image: AssetImage('assets/greyholder.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: MetallicCartridgeIndicator(cartridge: cartridge),
                  ),
                ),
              ),
      ],
    );
  }
}

class MetallicCartridgeIndicator extends StatelessWidget {
  final CartridgeModel cartridge;

  const MetallicCartridgeIndicator({
    Key? key,
    required this.cartridge,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final color = CartridgeColors.getColorByCode(cartridge.colorCode);
    if (color == null) return const SizedBox.shrink();

    return Center(
      child: Align(
        alignment: const Alignment(0, -0.18),
        child: Container(
          width: 35,
          height: 35,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.backgroundColor,
          ),
          child: Center(
            child: Text(
              cartridge.colorCode,
              style: TextStyle(
                color: color.textColor,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DashedCirclePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gapSize;
  final double dashSize;

  DashedCirclePainter({
    required this.color,
    required this.strokeWidth,
    required this.gapSize,
    required this.dashSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Create a dotted circle (many small dots)
    const double fullCircle = 2 * math.pi;
    // Increase the number of dots to make them appear closer together
    final int dotCount = 60; // More dots for a more dotted appearance
    final double anglePerDot = fullCircle / dotCount;

    // Make dots very small
    final double dotAngle = anglePerDot * 0.3; // Just a tiny arc for each dot

    for (var i = 0; i < dotCount; i++) {
      final double startAngle = i * anglePerDot;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        dotAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(DashedCirclePainter oldDelegate) =>
      color != oldDelegate.color ||
      strokeWidth != oldDelegate.strokeWidth ||
      gapSize != oldDelegate.gapSize ||
      dashSize != oldDelegate.dashSize;
}
