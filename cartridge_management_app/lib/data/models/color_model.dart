import 'package:flutter/material.dart';

class CartridgeColor {
  final String code;
  final String displayName;
  final Color backgroundColor;
  final Color textColor;
  final bool hasBorder;
  final String? description;

  const CartridgeColor({
    required this.code,
    required this.backgroundColor,
    this.displayName = '',
    this.textColor = Colors.white,
    this.hasBorder = false,
    this.description,
  });

  /// Creates a copy of this color with the given fields replaced with the new values
  CartridgeColor copyWith({
    String? code,
    String? displayName,
    Color? backgroundColor,
    Color? textColor,
    bool? hasBorder,
    String? description,
  }) {
    return CartridgeColor(
      code: code ?? this.code,
      displayName: displayName ?? this.displayName,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      textColor: textColor ?? this.textColor,
      hasBorder: hasBorder ?? this.hasBorder,
      description: description ?? this.description,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CartridgeColor &&
          runtimeType == other.runtimeType &&
          code == other.code;

  @override
  int get hashCode => code.hashCode;
}
