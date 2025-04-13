import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/cartridge_model.dart';

class SQLiteDatabase {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'cartridge_management.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE cartridges(
            id TEXT PRIMARY KEY,
            color_code TEXT NOT NULL,
            quantity INTEGER NOT NULL,
            slot INTEGER NOT NULL UNIQUE,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL
          )
        ''');
      },
    );
  }

  Future<List<CartridgeModel>> getAllCartridges() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'cartridges',
      orderBy: 'slot ASC',
    );

    return List.generate(maps.length, (i) => CartridgeModel.fromMap(maps[i]));
  }

  Future<void> insertCartridge(CartridgeModel cartridge) async {
    final db = await database;
    await db.insert(
      'cartridges',
      {
        ...cartridge.toMap(),
        'created_at': DateTime.now().millisecondsSinceEpoch,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateCartridge(CartridgeModel cartridge) async {
    final db = await database;
    await db.update(
      'cartridges',
      {
        ...cartridge.toMap(),
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [cartridge.id],
    );
  }

  Future<void> deleteCartridge(String id) async {
    final db = await database;
    await db.delete(
      'cartridges',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> clearAll() async {
    final db = await database;
    await db.delete('cartridges');
  }

  Future<bool> isSlotOccupied(int slot) async {
    final db = await database;
    final result = await db.query(
      'cartridges',
      where: 'slot = ?',
      whereArgs: [slot],
    );
    return result.isNotEmpty;
  }

  Future<void> resetToDefault() async {
    final db = await database;
    await db.delete('cartridges');
    // Burada varsayılan kartuşları ekleyebilirsiniz
  }

  Future<void> updateSlotOrder(List<CartridgeModel> cartridges) async {
    final db = await database;
    await db.transaction((txn) async {
      for (var cartridge in cartridges) {
        await txn.update(
          'cartridges',
          {'slot': cartridge.slot},
          where: 'id = ?',
          whereArgs: [cartridge.id],
        );
      }
    });
  }

  Future<T> transaction<T>(Future<T> Function(Transaction txn) action) async {
    final db = await database;
    return db.transaction(action);
  }
}
