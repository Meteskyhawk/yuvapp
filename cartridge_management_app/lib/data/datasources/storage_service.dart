import '../models/cartridge_model.dart';
import 'sqlite_database.dart';

/// Abstract class that defines contract for cartridge storage.
/// This allows for swapping underlying storage implementation (e.g., SQLite, API, mock).
class StorageService {
  final SQLiteDatabase _database;

  StorageService({required SQLiteDatabase database}) : _database = database;

  /// Fetch all cartridges from storage.
  Future<List<CartridgeModel>> getAllCartridges() {
    return _database.getAllCartridges();
  }

  /// Save a new cartridge to storage.
  Future<void> insertCartridge(CartridgeModel cartridge) {
    return _database.insertCartridge(cartridge);
  }

  /// Update an existing cartridge in storage.
  Future<void> updateCartridge(CartridgeModel cartridge) {
    return _database.updateCartridge(cartridge);
  }

  /// Delete a cartridge by its ID.
  Future<void> deleteCartridge(String id) {
    return _database.deleteCartridge(id);
  }

  /// Delete all cartridges (used for reset functionality).
  Future<void> clearAll() {
    return _database.clearAll();
  }

  /// Check if a slot already has a cartridge (for validation).
  Future<bool> isSlotOccupied(int slot) {
    return _database.isSlotOccupied(slot);
  }

  /// Optional: Reset slots to default state (optional feature from PDF).
  Future<void> resetToDefault() async {
    final cartridges = await getAllCartridges();
    if (cartridges.isEmpty) return;

    // Sort cartridges by color code to maintain consistent default order
    final sortedCartridges = List<CartridgeModel>.from(cartridges)
      ..sort((a, b) => a.colorCode.compareTo(b.colorCode));

    // Reassign slots from 1 to n based on sorted order
    for (int i = 0; i < sortedCartridges.length; i++) {
      final cartridge = sortedCartridges[i];
      final updatedCartridge = cartridge.copyWith(slot: i + 1);
      await updateCartridge(updatedCartridge);
    }
  }

  Future<void> updateSlotOrder(List<CartridgeModel> cartridges) {
    return _database.updateSlotOrder(cartridges);
  }
}
