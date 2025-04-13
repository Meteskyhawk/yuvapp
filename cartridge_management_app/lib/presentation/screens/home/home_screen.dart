import 'package:cartridge_management_app/presentation/screens/selector/color_selector_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../logic/blocs/cartridge/cartridge_bloc.dart';
import '../../../logic/blocs/cartridge/cartridge_event.dart';
import '../../../logic/blocs/cartridge/cartridge_state.dart';
import '../../../data/services/sync_service.dart';
import '../carousel/carousel_screen.dart';
import '../../../data/models/color_constants.dart';
import '../dialogs/slot_picker_dialog.dart';
import '../dialogs/quantity_picker_dialog.dart';
import 'package:http/http.dart' as http;
import '../dialogs/color_palette_manager_dialog.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final SyncService _syncService;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncService = context.read<SyncService>();
      _syncService.startPeriodicSync();
    });
  }

  @override
  void dispose() {
    _syncService.stopPeriodicSync();
    _focusNode.dispose();
    super.dispose();
  }

  void _showColorSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BlocBuilder<CartridgeBloc, CartridgeState>(
        builder: (context, state) {
          if (state is CartridgeLoaded) {
            return ColorSelectorBottomSheet(
              existingCartridges: state.cartridges,
              onDuplicateColor: (colorCode) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Color $colorCode is already in use. Please choose a different color.',
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
              },
              onSlotOccupied: (slotNumber) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Slot $slotNumber is already occupied. Please try again.',
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
              },
            );
          }
          return const ColorSelectorBottomSheet();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Inventory levels',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
            Consumer<SyncService>(
              builder: (context, syncService, child) {
                return ValueListenableBuilder<bool>(
                  valueListenable: syncService.syncStatus,
                  builder: (context, isSyncing, child) {
                    return Row(
                      children: [
                        Text(
                          'VUV Lab 1',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        if (isSyncing) ...[
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.grey[600]!,
                              ),
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              context.read<CartridgeBloc>().add(ClearAllCartridges());
            },
            child: Text(
              'Delete all',
              style: TextStyle(
                color: Colors.red[300],
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Reset Slots'),
                  content: const Text(
                    'This will reset all cartridges to their default positions. Are you sure?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        context.read<CartridgeBloc>().add(ResetSlots());
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Slots have been reset to default positions',
                            ),
                          ),
                        );
                      },
                      child: const Text('Reset'),
                    ),
                  ],
                ),
              );
            },
            child: const Text(
              'Reset slots',
              style: TextStyle(
                color: Colors.blue,
              ),
            ),
          ),
          Consumer<SyncService>(
            builder: (context, syncService, child) => IconButton(
              icon: const Icon(Icons.sync),
              onPressed: () => syncService.syncWithBackend(),
              tooltip: 'Sync now',
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showSettingsPanel(context),
            tooltip: 'Settings',
          ),
        ],
      ),
      body: Focus(
        focusNode: _focusNode,
        child: BlocBuilder<CartridgeBloc, CartridgeState>(
          builder: (context, state) {
            if (state is CartridgeLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is CartridgeLoaded) {
              return RefreshIndicator(
                onRefresh: () async {
                  try {
                    // Show a loading message while syncing
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Syncing data...'),
                        duration: Duration(seconds: 1),
                      ),
                    );

                    // Trigger backend synchronization
                    final syncResult =
                        await context.read<SyncService>().syncWithBackend();

                    // Dispatch events through the bloc to update UI
                    context
                        .read<CartridgeBloc>()
                        .add(SyncCartridgesFromRemote());

                    // Load colors from API
                    context.read<CartridgeBloc>().add(LoadCartridgeColors());

                    // Wait for operations to complete
                    await Future.delayed(const Duration(milliseconds: 500));

                    // Reload cartridges to refresh the UI
                    context.read<CartridgeBloc>().add(LoadCartridges());

                    // Show success or error message based on sync result
                    if (syncResult) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Sync completed successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } else {
                      String errorMessage =
                          context.read<SyncService>().lastError.value ??
                              'Unknown error';
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Sync error: $errorMessage'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  } catch (e) {
                    print('Refresh error: $e');
                    // In case of error, still reload local data
                    context.read<CartridgeBloc>().add(LoadCartridges());

                    // Show error message
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error during sync: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                  // Complete the refresh
                  return Future.value();
                },
                // Ensure the indicator is visible and has appropriate colors
                color: Colors.blue,
                backgroundColor: Colors.white,
                displacement: 40,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.all(16),
                      sliver: SliverReorderableList(
                        itemCount: state.cartridges.length,
                        onReorder: (oldIndex, newIndex) {
                          if (oldIndex < newIndex) {
                            newIndex -= 1;
                          }
                          final cartridge = state.cartridges[oldIndex];
                          final targetSlot = state.cartridges[newIndex].slot;

                          context.read<CartridgeBloc>().add(
                                UpdateCartridge(
                                    cartridge.updateSlot(targetSlot)),
                              );
                        },
                        itemBuilder: (context, index) {
                          final cartridge = state.cartridges[index];
                          final color = CartridgeColors.getColorByCode(
                              cartridge.colorCode);
                          if (color == null)
                            return const SizedBox(key: ValueKey('empty'));

                          return Padding(
                            key: ValueKey(cartridge.id),
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey[200]!),
                              ),
                              child: Row(
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
                                    child: Center(
                                      child: Align(
                                        alignment: const Alignment(0, -0.18),
                                        child: Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: color.backgroundColor,
                                          ),
                                          child: Center(
                                            child: Text(
                                              color.code,
                                              style: TextStyle(
                                                color: color.textColor,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 15,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 80),
                                  Expanded(
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        Expanded(
                                          flex: 1,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'Slot',
                                                style: TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 12,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Align(
                                                alignment: Alignment.centerLeft,
                                                child: Container(
                                                  width: 60,
                                                  height: 40,
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 10,
                                                      vertical: 0),
                                                  decoration: BoxDecoration(
                                                    border: Border.all(
                                                        color:
                                                            Colors.grey[300]!),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                  ),
                                                  child: InkWell(
                                                    onTap: () async {
                                                      final result =
                                                          await showDialog<int>(
                                                        context: context,
                                                        builder: (context) =>
                                                            SlotPickerDialog(
                                                          currentSlot:
                                                              cartridge.slot,
                                                        ),
                                                      );
                                                      if (result != null) {
                                                        context
                                                            .read<
                                                                CartridgeBloc>()
                                                            .add(
                                                              UpdateCartridge(
                                                                cartridge
                                                                    .updateSlot(
                                                                        result),
                                                              ),
                                                            );
                                                      }
                                                    },
                                                    child: Center(
                                                      child: Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .spaceBetween,
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .center,
                                                        children: [
                                                          Text(
                                                            cartridge.slot
                                                                .toString(),
                                                            style:
                                                                const TextStyle(
                                                                    fontSize:
                                                                        16),
                                                          ),
                                                          const Icon(
                                                              Icons
                                                                  .arrow_drop_down,
                                                              color:
                                                                  Colors.grey,
                                                              size: 18),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Expanded(
                                          flex: 1,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'Quantity (g)',
                                                style: TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 12,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Align(
                                                alignment: Alignment.centerLeft,
                                                child: Container(
                                                  width: 80,
                                                  height: 40,
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 10,
                                                      vertical: 0),
                                                  decoration: BoxDecoration(
                                                    border: Border.all(
                                                        color:
                                                            Colors.grey[300]!),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                  ),
                                                  child: InkWell(
                                                    onTap: () async {
                                                      final result =
                                                          await showDialog<int>(
                                                        context: context,
                                                        builder: (context) =>
                                                            QuantityPickerDialog(
                                                          currentQuantity:
                                                              cartridge
                                                                  .quantity,
                                                        ),
                                                      );
                                                      if (result != null) {
                                                        context
                                                            .read<
                                                                CartridgeBloc>()
                                                            .add(
                                                              UpdateCartridge(
                                                                cartridge
                                                                    .updateQuantity(
                                                                        result),
                                                              ),
                                                            );
                                                      }
                                                    },
                                                    child: Center(
                                                      child: Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .spaceBetween,
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .center,
                                                        children: [
                                                          Text(
                                                            cartridge.quantity
                                                                .toString(),
                                                            style:
                                                                const TextStyle(
                                                                    fontSize:
                                                                        16),
                                                          ),
                                                          const Icon(
                                                              Icons.close,
                                                              color:
                                                                  Colors.grey,
                                                              size: 18),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline),
                                    onPressed: () {
                                      final currentSlot = cartridge.slot;
                                      context
                                          .read<CartridgeBloc>()
                                          .add(DeleteCartridge(cartridge.id));

                                      // Show message about slot reindexing
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Cartridge deleted. Slot numbers reindexed.',
                                            style:
                                                TextStyle(color: Colors.white),
                                          ),
                                          backgroundColor: Colors.black,
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 80),
                    ),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Material(
          elevation: 8,
          child: Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  spreadRadius: 1,
                  offset: const Offset(0, -1),
                )
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showColorSelector(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Colors.black),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Add cartridge',
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CarouselScreen(),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.black,
                      side: BorderSide.none,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'View carousel',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSettingsPanel(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Settings',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.sync),
                title: const Text('Test API Connection'),
                onTap: () {
                  Navigator.pop(context);
                  _testApiConnection(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.palette),
                title: const Text('Manage Color Palettes'),
                onTap: () {
                  Navigator.pop(context);
                  _showColorPaletteManager(context);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _testApiConnection(BuildContext context) {
    final apiUrl = 'https://www.thecolorapi.com'; // Sadece temel URL

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('API Connection Test'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Testing connection to:'),
              Text(
                apiUrl,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              FutureBuilder<bool>(
                future: _checkApiConnection(apiUrl),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  } else if (snapshot.hasError) {
                    return Column(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 48,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Error: ${snapshot.error}',
                          style: const TextStyle(color: Colors.red),
                        ),
                      ],
                    );
                  } else {
                    final success = snapshot.data ?? false;
                    return Column(
                      children: [
                        Icon(
                          success ? Icons.check_circle : Icons.cancel,
                          color: success ? Colors.green : Colors.red,
                          size: 48,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          success
                              ? 'Connection successful!'
                              : 'Connection failed',
                          style: TextStyle(
                            color: success ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    );
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<bool> _checkApiConnection(String apiUrl) async {
    try {
      final client = http.Client();
      // Test için geçerli bir endpoint kullan, parametreleri doğru şekilde ekle
      final response = await client
          .get(Uri.parse('$apiUrl/scheme?hex=8a4b3a&mode=analogic&count=5'));
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      print('API connection test error: $e');
      return false;
    }
  }

  void _showColorPaletteManager(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return const ColorPaletteManagerDialog();
      },
    );
  }
}
