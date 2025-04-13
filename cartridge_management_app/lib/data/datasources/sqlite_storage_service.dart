import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/cartridge_model.dart';
import 'storage_service.dart';

/// SQLite implementation of [StorageService]
class SQLiteStorageService implements StorageService {
  static const _dbName = 'cartridge.db';
  static const _tableName = 'cartridges';

  static Database? _database;

  /// Ensures database is initialized once.
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_tableName (
            id TEXT PRIMARY KEY,
            color_code TEXT,
            quantity INTEGER,
            slot INTEGER
          )
        ''');
      },
    );
  }

  @override
  Future<void> insertCartridge(CartridgeModel cartridge) async {
    final db = await database;
    await db.insert(_tableName, cartridge.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<List<CartridgeModel>> getAllCartridges() async {
    final db = await database;
    final maps = await db.query(_tableName, orderBy: 'slot ASC');
    return maps.map((e) => CartridgeModel.fromMap(e)).toList();
  }

  @override
  Future<void> updateCartridge(CartridgeModel cartridge) async {
    final db = await database;
    await db.update(
      _tableName,
      cartridge.toMap(),
      where: 'id = ?',
      whereArgs: [cartridge.id],
    );
  }

  @override
  Future<void> deleteCartridge(String id) async {
    final db = await database;
    await db.delete(_tableName, where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<void> clearAll() async {
    final db = await database;
    await db.delete(_tableName);
  }

  @override
  Future<bool> isSlotOccupied(int slot) async {
    final db = await database;
    final result = await db.query(_tableName,
        where: 'slot = ?', whereArgs: [slot], limit: 1);
    return result.isNotEmpty;
  }

  @override
  Future<void> resetToDefault() async {
    final db = await database;
    final cartridges = await getAllCartridges();
    if (cartridges.isEmpty) return;

    // Sort cartridges by color code to maintain consistent default order
    final sortedCartridges = List<CartridgeModel>.from(cartridges)
      ..sort((a, b) => a.colorCode.compareTo(b.colorCode));

    await db.transaction((txn) async {
      // Update all cartridges with new slot numbers
      for (int i = 0; i < sortedCartridges.length; i++) {
        final cartridge = sortedCartridges[i];
        await txn.update(
          _tableName,
          {'slot': i + 1},
          where: 'id = ?',
          whereArgs: [cartridge.id],
        );
      }
    });
  }

  @override
  Future<void> updateSlotOrder(List<CartridgeModel> cartridges) async {
    final db = await database;
    await db.transaction((txn) async {
      for (var cartridge in cartridges) {
        await txn.update(
          _tableName,
          {'slot': cartridge.slot},
          where: 'id = ?',
          whereArgs: [cartridge.id],
        );
      }
    });
  }
}
