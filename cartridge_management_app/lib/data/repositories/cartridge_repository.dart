import '../datasources/remote_data_source.dart';
import '../datasources/storage_service.dart';
import '../models/cartridge_model.dart';
import 'dart:math' as math;

/// Repository layer that connects business logic with the data source.
/// It wraps around the [StorageService] and exposes business-friendly methods.
class CartridgeRepository {
  final StorageService _storageService;
  final RemoteDataSource? _remoteDataSource;

  CartridgeRepository({
    required StorageService storageService,
    RemoteDataSource? remoteDataSource,
  })  : _storageService = storageService,
        _remoteDataSource = remoteDataSource;

  /// Get all cartridges sorted by slot
  Future<List<CartridgeModel>> getAllCartridges() async {
    return _storageService.getAllCartridges();
  }

  /// Get cartridges with duplicated color codes highlighted
  Future<List<CartridgeModel>> getCartridgesWithDuplicates() async {
    final cartridges = await getAllCartridges();

    // Count occurrences of each color code
    final colorCounts = <String, int>{};
    for (var cartridge in cartridges) {
      colorCounts[cartridge.colorCode] =
          (colorCounts[cartridge.colorCode] ?? 0) + 1;
    }

    // Mark cartridges that have duplicate color codes
    final result = <CartridgeModel>[];
    for (var cartridge in cartridges) {
      result.add(cartridge);
    }

    return result;
  }

  /// Get cartridges that need to be changed (quantity < 30g)
  Future<List<CartridgeModel>> getChangeNowCartridges() async {
    final cartridges = await getAllCartridges();
    return cartridges.where((c) => c.isChangeNow).toList();
  }

  /// Get empty slots (slot numbers that are not occupied)
  Future<List<int>> getEmptySlots() async {
    final cartridges = await getAllCartridges();
    final usedSlots = cartridges.map((c) => c.slot).toSet();
    final maxSlot =
        cartridges.isEmpty ? 0 : cartridges.map((c) => c.slot).reduce(math.max);
    final emptySlots = <int>[];
    for (int i = 1; i <= maxSlot + 1; i++) {
      if (!usedSlots.contains(i)) {
        emptySlots.add(i);
      }
    }
    return emptySlots;
  }

  /// Load colors from the API
  Future<void> loadColorsFromApi() async {
    if (_remoteDataSource != null) {
      await _remoteDataSource!.fetchColors();
    }
  }

  Future<void> insertCartridge(CartridgeModel cartridge) {
    return _storageService.insertCartridge(cartridge);
  }

  Future<void> updateCartridge(CartridgeModel cartridge) {
    return _storageService.updateCartridge(cartridge);
  }

  Future<void> deleteCartridge(String id) {
    return _storageService.deleteCartridge(id);
  }

  Future<void> clearAll() {
    return _storageService.clearAll();
  }

  Future<bool> isSlotOccupied(int slot) {
    return _storageService.isSlotOccupied(slot);
  }

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

  Future<void> updateSlotOrder(List<CartridgeModel> cartridges) async {
    for (var cartridge in cartridges) {
      await updateCartridge(cartridge);
    }
  }

  Future<void> syncFromRemote() async {
    if (_remoteDataSource == null) {
      throw Exception('Remote data source not configured');
    }

    try {
      // Fetch data from remote API
      final remoteCartridges = await _remoteDataSource!.fetchCartridges();

      // If data is received from the remote API, update local data while preserving it
      if (remoteCartridges.isNotEmpty) {
        // Get existing data
        final existingCartridges = await _storageService.getAllCartridges();
        final existingMap = {for (var c in existingCartridges) c.id: c};

        // Update or add each cartridge from the API
        for (var remoteCart in remoteCartridges) {
          if (existingMap.containsKey(remoteCart.id)) {
            // Update existing cartridge
            await _storageService.updateCartridge(remoteCart);
          } else {
            // Add new cartridge
            await _storageService.insertCartridge(remoteCart);
          }
        }
      }
      // If remoteCartridges is empty, do nothing (preserve data)
    } catch (e) {
      print('Sync error: $e');
      rethrow; // Propagate error upward
    }
  }

  Future<void> syncToRemote() async {
    if (_remoteDataSource == null) {
      throw Exception('Remote data source not configured');
    }
    final localCartridges = await _storageService.getAllCartridges();
    await _remoteDataSource!.syncCartridges(localCartridges);
  }
}
