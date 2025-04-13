import 'package:cartridge_management_app/logic/blocs/cartridge/cartridge_event.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'logic/blocs/cartridge/cartridge_bloc.dart';
import 'data/datasources/storage_service.dart';
import 'data/datasources/sqlite_storage_service.dart';
import 'data/repositories/cartridge_repository.dart';
import 'data/services/sync_service.dart';
import 'data/datasources/remote_data_source.dart';
import 'data/models/color_constants.dart';
import 'config/router.dart';
import 'utils/app_config.dart';
import 'utils/app_logger.dart';

/// Custom BlocObserver to monitor and log bloc events, transitions, and errors
class AppBlocObserver extends BlocObserver {
  @override
  void onCreate(BlocBase bloc) {
    super.onCreate(bloc);
    AppLogger.debug('BlocObserver: onCreate: ${bloc.runtimeType}');
  }

  @override
  void onEvent(Bloc bloc, Object? event) {
    super.onEvent(bloc, event);
    AppLogger.debug('BlocObserver: ${bloc.runtimeType} $event');
  }

  @override
  void onChange(BlocBase bloc, Change change) {
    super.onChange(bloc, change);
    AppLogger.debug('BlocObserver: ${bloc.runtimeType} $change');
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    AppLogger.error('BlocObserver: ${bloc.runtimeType}', error, stackTrace);
    super.onError(bloc, error, stackTrace);
  }
}

void main() async {
  // Ensure Flutter is initialized before calling native code
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize logger
  AppLogger.init();
  AppLogger.info('Application startup initiated');

  // Setup bloc observer in debug mode for better debugging
  if (kDebugMode) {
    Bloc.observer = AppBlocObserver();
    AppLogger.debug('BlocObserver registered');
  }

  // Load application configuration
  final appConfig = AppConfig();
  await appConfig.init();

  // Load saved colors
  try {
    await CartridgeColors.loadSavedColors();
    AppLogger.info('Successfully loaded saved colors');
  } catch (e, stackTrace) {
    AppLogger.error('Error loading colors in main', e, stackTrace);
    // Application continues execution even if color loading fails
  }

  // Initialize sync service
  final syncService = SyncService();

  runApp(
    MultiProvider(
      providers: [
        // Provide app configuration
        Provider<AppConfig>.value(value: appConfig),

        // Storage service provider
        Provider<StorageService>(
          create: (_) => SQLiteStorageService(),
        ),

        // Remote data source provider with API URL from config
        Provider<RemoteDataSource>(
          create: (context) => HttpRemoteDataSource(
            apiUrl: context.read<AppConfig>().apiBaseUrl,
          ),
        ),

        // Repository provider combining storage and remote data
        Provider<CartridgeRepository>(
          create: (context) {
            final repository = CartridgeRepository(
              storageService: context.read<StorageService>(),
              remoteDataSource: context.read<RemoteDataSource>(),
            );

            // Initialize sync service with repository and config
            syncService.initialize(
              repository,
              config: context.read<AppConfig>(),
            );

            return repository;
          },
        ),

        // Provide sync service as a ChangeNotifier
        ChangeNotifierProvider<SyncService>.value(value: syncService),

        // BLoC provider for cartridge management
        BlocProvider<CartridgeBloc>(
          create: (context) => CartridgeBloc(
            repository: context.read<CartridgeRepository>(),
          )..add(LoadCartridges()),
        ),
      ],
      child: const MyApp(),
    ),
  );

  AppLogger.info('Application successfully started');
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Cartridge Management App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      routerConfig: AppRouter.router,
    );
  }
}
