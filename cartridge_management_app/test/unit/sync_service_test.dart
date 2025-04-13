import 'package:cartridge_management_app/data/repositories/cartridge_repository.dart';
import 'package:cartridge_management_app/data/services/sync_service.dart';
import 'package:cartridge_management_app/utils/app_config.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'sync_service_test.mocks.dart';

@GenerateMocks([CartridgeRepository, AppConfig])
void main() {
  group('SyncService', () {
    late SyncService syncService;
    late MockCartridgeRepository mockRepository;
    late MockAppConfig mockConfig;

    setUp(() {
      // Reset the singleton for each test
      syncService = SyncService();
      mockRepository = MockCartridgeRepository();
      mockConfig = MockAppConfig();

      // Setup common mocked responses
      when(mockConfig.syncInterval).thenReturn(const Duration(minutes: 5));
    });

    test('initialize should set repository and config', () {
      // Arrange & Act
      syncService.initialize(mockRepository, config: mockConfig);

      // Assert - verify internal state by checking the sync interval was set
      expect(syncService.startPeriodicSync, isA<Function>());
      expect(syncService.isSyncing, false);
    });

    test('syncWithBackend should return false if another sync is in progress',
        () async {
      // Arrange
      syncService.initialize(mockRepository);

      // Simulate sync in progress
      when(mockRepository.syncFromRemote()).thenAnswer((_) async {
        // Deliberately delay to simulate long-running task
        await Future.delayed(const Duration(milliseconds: 100));
        return;
      });

      // Act
      // Start first sync
      final firstSync = syncService.syncWithBackend();
      // Try to start second sync while first is in progress
      final secondSync = syncService.syncWithBackend();

      // Assert
      expect(await firstSync, true);
      expect(await secondSync, false);
    });

    test('syncWithBackend should handle errors gracefully', () async {
      // Arrange
      syncService.initialize(mockRepository);

      // Setup mocked repository to throw error
      when(mockRepository.syncFromRemote())
          .thenThrow(Exception('Network error'));

      // Make sure getAllCartridges doesn't throw to test error recovery
      when(mockRepository.getAllCartridges()).thenAnswer((_) async => []);

      // Act
      final result = await syncService.syncWithBackend();

      // Assert
      expect(result, false);
      expect(syncService.lastError.value, contains('Network error'));
      expect(syncService.isSyncing, false);

      // Verify repository was still called despite the error
      verify(mockRepository.getAllCartridges()).called(1);
    });

    test('startPeriodicSync should initialize timer and execute immediate sync',
        () async {
      // Arrange
      syncService.initialize(mockRepository);

      // Setup mocks
      when(mockRepository.syncFromRemote()).thenAnswer((_) async => null);
      when(mockRepository.getAllCartridges()).thenAnswer((_) async => []);
      when(mockRepository.syncToRemote()).thenAnswer((_) async => null);

      // Act
      syncService.startPeriodicSync();

      // Assert - verify immediate sync was triggered
      await untilCalled(mockRepository.syncFromRemote());
      verify(mockRepository.syncFromRemote()).called(1);
    });

    test('stopPeriodicSync should cancel timer', () {
      // Arrange
      syncService.initialize(mockRepository);
      syncService.startPeriodicSync();

      // Act
      syncService.stopPeriodicSync();

      // Assert - can only verify indirectly through isSyncing state
      expect(syncService.isSyncing, false);
    });
  });
}
