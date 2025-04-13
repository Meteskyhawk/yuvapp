import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meta/meta.dart';
import '../../../data/models/cartridge_model.dart';
import '../../../data/repositories/cartridge_repository.dart';
import '../../../data/datasources/remote_data_source.dart';
import 'cartridge_event.dart';
import 'cartridge_state.dart';

/// BLoC responsible for managing the cartridge inventory logic.
class CartridgeBloc extends Bloc<CartridgeEvent, CartridgeState> {
  final CartridgeRepository repository;

  CartridgeBloc({required this.repository}) : super(CartridgeInitial()) {
    on<LoadCartridges>(_onLoadCartridges);
    on<AddCartridge>(_onAddCartridge);
    on<UpdateCartridge>(_onUpdateCartridge);
    on<DeleteCartridge>(_onDeleteCartridge);
    on<ClearAllCartridges>(_onClearAll);
    on<ResetSlots>(_onResetSlots);
    on<SyncCartridgesFromRemote>(_onSyncFromRemote);
    on<LoadCartridgeColors>(_onLoadCartridgeColors);
  }

  Future<void> _onLoadCartridges(
      LoadCartridges event, Emitter<CartridgeState> emit) async {
    emit(CartridgeLoading());
    try {
      final cartridges = await repository.getAllCartridges();
      emit(CartridgeLoaded(cartridges));
    } catch (e) {
      emit(CartridgeError('Failed to load cartridges: $e'));
    }
  }

  Future<void> _onAddCartridge(
      AddCartridge event, Emitter<CartridgeState> emit) async {
    emit(CartridgeLoading());
    try {
      final isOccupied = await repository.isSlotOccupied(event.cartridge.slot);
      if (isOccupied) {
        emit(const CartridgeError('Slot is already occupied.'));
        return;
      }
      await repository.insertCartridge(event.cartridge);
      add(LoadCartridges());
    } catch (e) {
      emit(CartridgeError('Failed to add cartridge: $e'));
    }
  }

  Future<void> _onUpdateCartridge(
      UpdateCartridge event, Emitter<CartridgeState> emit) async {
    emit(CartridgeLoading());
    try {
      await repository.updateCartridge(event.cartridge);
      add(LoadCartridges());
    } catch (e) {
      emit(CartridgeError('Failed to update cartridge: $e'));
    }
  }

  Future<void> _onDeleteCartridge(
      DeleteCartridge event, Emitter<CartridgeState> emit) async {
    emit(CartridgeLoading());
    try {
      // Get the deleted cartridge's slot before deleting it
      final cartridges = await repository.getAllCartridges();
      final deletedCartridge = cartridges.firstWhere(
        (c) => c.id == event.id,
        orElse: () => CartridgeModel(
          id: '',
          colorCode: '',
          quantity: 0,
          slot: -1,
        ),
      );

      // Delete the cartridge
      await repository.deleteCartridge(event.id);

      // If the slot was valid, reindex all higher slot numbers
      if (deletedCartridge.slot > 0) {
        // Get all remaining cartridges
        final remainingCartridges = await repository.getAllCartridges();

        // Update slots for all cartridges with slot numbers higher than the deleted one
        for (var cartridge in remainingCartridges) {
          if (cartridge.slot > deletedCartridge.slot) {
            // Decrement the slot number by 1
            final updatedCartridge =
                cartridge.copyWith(slot: cartridge.slot - 1);
            await repository.updateCartridge(updatedCartridge);
          }
        }
      }

      // Reload cartridges to update the UI
      add(LoadCartridges());
    } catch (e) {
      emit(CartridgeError('Failed to delete cartridge: $e'));
    }
  }

  Future<void> _onClearAll(
      ClearAllCartridges event, Emitter<CartridgeState> emit) async {
    emit(CartridgeLoading());
    try {
      await repository.clearAll();
      add(LoadCartridges());
    } catch (e) {
      emit(CartridgeError('Failed to clear cartridges: $e'));
    }
  }

  Future<void> _onResetSlots(
      ResetSlots event, Emitter<CartridgeState> emit) async {
    emit(CartridgeLoading());
    try {
      await repository.resetToDefault();
      add(LoadCartridges());
    } catch (e) {
      emit(CartridgeError('Failed to reset slots: $e'));
    }
  }

  Future<void> _onSyncFromRemote(
      SyncCartridgesFromRemote event, Emitter<CartridgeState> emit) async {
    emit(CartridgeLoading());
    try {
      await repository.syncFromRemote();
      add(LoadCartridges());
    } catch (e) {
      emit(CartridgeError('Failed to sync from remote: $e'));
    }
  }

  Future<void> _onLoadCartridgeColors(
      LoadCartridgeColors event, Emitter<CartridgeState> emit) async {
    try {
      await repository.loadColorsFromApi();
      add(LoadCartridges());
    } catch (e) {
      emit(CartridgeError('Failed to load colors from API: $e'));
    }
  }
}
