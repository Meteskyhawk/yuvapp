import 'dart:async';
import 'package:flutter/foundation.dart';
import '../repositories/cartridge_repository.dart';
import '../../utils/app_logger.dart';
import '../../utils/app_config.dart';

/// Service responsible for synchronizing local data with remote backend
class SyncService extends ChangeNotifier {
  CartridgeRepository? _repository;
  Timer? _syncTimer;
  bool _isSyncing = false;
  // Not final anymore, so it can be updated after initialization
  late Duration _syncInterval = const Duration(minutes: 15); // Default value
  AppConfig? _config;

  // Singleton pattern
  static final SyncService _instance = SyncService._internal();

  factory SyncService() => _instance;

  SyncService._internal();

  /// Initialize service with repository and optional config
  void initialize(CartridgeRepository repository, {AppConfig? config}) {
    _repository = repository;
    _config = config;

    // Update sync interval if config is provided
    if (_config != null) {
      _syncInterval = _config!.syncInterval;
    }

    AppLogger.debug('SyncService initialized with interval: $_syncInterval');
  }

  // Value notifiers for sync status monitoring
  final ValueNotifier<bool> syncStatus = ValueNotifier<bool>(false);
  final ValueNotifier<String?> lastError = ValueNotifier<String?>(null);

  /// Start periodic synchronization with backend
  void startPeriodicSync() {
    if (_repository == null) {
      throw Exception('SyncService not initialized');
    }

    // Cancel existing timer if any
    _syncTimer?.cancel();

    // Create new timer with configured interval
    _syncTimer = Timer.periodic(_syncInterval, (_) => syncWithBackend());

    // Start first sync immediately
    syncWithBackend();

    AppLogger.info('Periodic sync started with interval: $_syncInterval');
  }

  /// Stop periodic synchronization
  void stopPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
    AppLogger.debug('Periodic sync stopped');
  }

  /// Perform a single sync operation with the backend
  Future<bool> syncWithBackend() async {
    if (_repository == null) {
      throw Exception('SyncService not initialized');
    }

    // Don't start a new sync if one is already in progress
    if (_isSyncing) return false;

    _isSyncing = true;
    syncStatus.value = true;
    lastError.value = null;
    notifyListeners();

    AppLogger.info('Starting data synchronization');

    try {
      // First fetch data from remote
      await _repository!.syncFromRemote();
      AppLogger.debug('Successfully pulled remote data');

      // Then push local changes to remote
      final localCartridges = await _repository!.getAllCartridges();
      await _repository!.syncToRemote();
      AppLogger.debug(
          'Successfully pushed ${localCartridges.length} cartridges to remote');

      _isSyncing = false;
      syncStatus.value = false;
      notifyListeners();

      AppLogger.info('Synchronization completed successfully');
      return true;
    } catch (e, stackTrace) {
      AppLogger.error('Sync error', e, stackTrace);

      _isSyncing = false;
      syncStatus.value = false;
      lastError.value = e.toString();
      notifyListeners();

      // Even in case of error, try to preserve local data
      try {
        final _ = await _repository!.getAllCartridges();
      } catch (innerError, innerStackTrace) {
        AppLogger.error(
            'Error loading local cartridges', innerError, innerStackTrace);
      }

      return false;
    }
  }

  @override
  void dispose() {
    stopPeriodicSync();
    syncStatus.dispose();
    lastError.dispose();
    super.dispose();
  }

  /// Get current syncing state
  bool get isSyncing => _isSyncing;
}
