import 'package:equatable/equatable.dart';
import '../../../data/models/cartridge_model.dart';

/// Base class for all cartridge-related events.
abstract class CartridgeEvent extends Equatable {
  const CartridgeEvent();

  @override
  List<Object?> get props => [];
}

/// Triggered to load all cartridges from the local database.
class LoadCartridges extends CartridgeEvent {}

/// Triggered to add a new cartridge.
class AddCartridge extends CartridgeEvent {
  final CartridgeModel cartridge;

  const AddCartridge(this.cartridge);

  @override
  List<Object?> get props => [cartridge];
}

/// Triggered to update an existing cartridge.
class UpdateCartridge extends CartridgeEvent {
  final CartridgeModel cartridge;

  const UpdateCartridge(this.cartridge);

  @override
  List<Object?> get props => [cartridge];
}

/// Triggered to delete a cartridge by its ID.
class DeleteCartridge extends CartridgeEvent {
  final String id;

  const DeleteCartridge(this.id);

  @override
  List<Object?> get props => [id];
}

/// Triggered to delete all cartridges.
class ClearAllCartridges extends CartridgeEvent {}

/// Triggered to reset the slot order to the default state.
class ResetSlots extends CartridgeEvent {}

/// Triggered to sync cartridge data from remote API and overwrite local storage.
class SyncCartridgesFromRemote extends CartridgeEvent {}

/// Triggered to load cartridge colors from the API.
class LoadCartridgeColors extends CartridgeEvent {}
