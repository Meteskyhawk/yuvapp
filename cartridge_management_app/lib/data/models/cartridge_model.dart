import 'dart:convert';
import 'package:cartridge_management_app/data/models/color_constants.dart';
import 'package:cartridge_management_app/data/models/color_model.dart';
import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';

/// A data model representing a cartridge item in the system.
/// This model holds the necessary information for inventory and slot management.
class CartridgeModel extends Equatable {
  final String id; // Unique identifier for the cartridge (e.g., UUID)
  final String colorCode; // Color code label, e.g., RED, BLK
  final int quantity; // Measured in grams (g)
  final int slot; // Slot number from 1 to N

  /// Default constructor
  const CartridgeModel({
    required this.id,
    required this.colorCode,
    required this.quantity,
    required this.slot,
  });

  /// Returns true if this cartridge is running low (i.e., needs change soon)
  bool get isChangeNow => quantity < 30;

  /// Used to check if a slot is considered "empty"
  bool get isEmpty => quantity == 0;

  /// Returns the visual color style associated with this cartridge's color code
  CartridgeColor? get visualStyle => CartridgeColors.getColorByCode(colorCode);

  /// Returns a copy of this object with optional new values
  CartridgeModel copyWith({
    String? id,
    String? colorCode,
    int? quantity,
    int? slot,
  }) {
    return CartridgeModel(
      id: id ?? this.id,
      colorCode: colorCode ?? this.colorCode,
      quantity: quantity ?? this.quantity,
      slot: slot ?? this.slot,
    );
  }

  /// Creates a CartridgeModel from a Map (for SQLite or API parsing)
  factory CartridgeModel.fromMap(Map<String, dynamic> map) {
    return CartridgeModel(
      id: map['id'],
      colorCode: map['color_code'],
      quantity: map['quantity'],
      slot: map['slot'],
    );
  }

  /// Converts this object into a Map (for SQLite or API)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'color_code': colorCode,
      'quantity': quantity,
      'slot': slot,
    };
  }

  /// Updates the slot number
  CartridgeModel updateSlot(int newSlot) {
    return copyWith(slot: newSlot);
  }

  /// Updates the quantity
  CartridgeModel updateQuantity(int newQuantity) {
    return copyWith(quantity: newQuantity);
  }

  String toJson() => json.encode(toMap());

  factory CartridgeModel.fromJson(String source) =>
      CartridgeModel.fromMap(json.decode(source));

  @override
  List<Object?> get props => [id, colorCode, quantity, slot];

  @override
  String toString() {
    return 'CartridgeModel(id: $id, colorCode: $colorCode, quantity: $quantity, slot: $slot)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CartridgeModel &&
        other.id == id &&
        other.colorCode == colorCode &&
        other.quantity == quantity &&
        other.slot == slot;
  }

  @override
  int get hashCode {
    return id.hashCode ^ colorCode.hashCode ^ quantity.hashCode ^ slot.hashCode;
  }
}
