import 'package:equatable/equatable.dart';
import '../../../data/models/cartridge_model.dart';

/// Base class for all cartridge-related states.
abstract class CartridgeState extends Equatable {
  const CartridgeState();

  @override
  List<Object?> get props => [];
}

/// Initial state before any action has taken place.
class CartridgeInitial extends CartridgeState {}

/// State shown while data is being loaded or written.
class CartridgeLoading extends CartridgeState {}

/// State when cartridge data is successfully loaded.
class CartridgeLoaded extends CartridgeState {
  final List<CartridgeModel> cartridges;

  const CartridgeLoaded(this.cartridges);

  @override
  List<Object?> get props => [cartridges];
}

/// State when an error occurs during data processing.
class CartridgeError extends CartridgeState {
  final String message;

  const CartridgeError(this.message);

  @override
  List<Object?> get props => [message];
}
