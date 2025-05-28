import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/inventory_item.dart';
import '../models/shop.dart';
import '../models/stock_entry.dart';
import '../models/transaction.dart' as trans;

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'inventory_management.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create shops table
    await db.execute('''
      CREATE TABLE shops(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        address TEXT NOT NULL,
        created_date TEXT NOT NULL
      )
    ''');

    // Create inventory_items table
    await db.execute('''
      CREATE TABLE inventory_items(
        id TEXT PRIMARY KEY,
        shop_id TEXT NOT NULL,
        name TEXT NOT NULL,
        price REAL NOT NULL,
        quantity INTEGER NOT NULL,
        created_date TEXT NOT NULL,
        last_updated TEXT NOT NULL,
        FOREIGN KEY (shop_id) REFERENCES shops (id) ON DELETE CASCADE
      )
    ''');

    // Create stock_entries table
    await db.execute('''
      CREATE TABLE stock_entries(
        id TEXT PRIMARY KEY,
        item_id TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        type TEXT NOT NULL,
        date_time TEXT NOT NULL,
        note TEXT,
        FOREIGN KEY (item_id) REFERENCES inventory_items (id) ON DELETE CASCADE
      )
    ''');

    // Create transactions table
    await db.execute('''
      CREATE TABLE transactions(
        id TEXT PRIMARY KEY,
        shop_id TEXT NOT NULL,
        item_id TEXT NOT NULL,
        item_name TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        price REAL NOT NULL,
        total_amount REAL NOT NULL,
        date_time TEXT NOT NULL,
        type TEXT NOT NULL,
        FOREIGN KEY (shop_id) REFERENCES shops (id) ON DELETE CASCADE
      )
    ''');
  }

  // Shop operations
  Future<List<Shop>> getAllShops() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('shops');

    List<Shop> shops = [];
    for (var map in maps) {
      final shop = Shop.fromJson(map);

      // Load inventory items for this shop
      shop.inventory = await getInventoryItems(shop.id);

      // Load transactions for this shop
      shop.transactions = (await getTransactions(shop.id)).cast<trans.Transaction>();

      shops.add(shop);
    }

    return shops;
  }

  Future<int> insertShop(Shop shop) async {
    final db = await database;
    return await db.insert('shops', {
      'id': shop.id,
      'name': shop.name,
      'address': shop.address,
      'created_date': shop.createdDate.toIso8601String(),
    });
  }

  Future<int> updateShop(Shop shop) async {
    final db = await database;
    return await db.update(
      'shops',
      {
        'name': shop.name,
        'address': shop.address,
        'created_date': shop.createdDate.toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [shop.id],
    );
  }

  Future<int> deleteShop(String shopId) async {
    final db = await database;
    return await db.delete('shops', where: 'id = ?', whereArgs: [shopId]);
  }

  // Inventory item operations
  Future<List<InventoryItem>> getInventoryItems(String shopId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'inventory_items',
      where: 'shop_id = ?',
      whereArgs: [shopId],
    );

    List<InventoryItem> items = [];
    for (var map in maps) {
      final item = InventoryItem(
        id: map['id'],
        name: map['name'],
        price: map['price'],
        quantity: map['quantity'],
        createdDate: DateTime.parse(map['created_date']),
        lastUpdated: DateTime.parse(map['last_updated']),
      );

      // Load stock entries for this item
      item.stockEntries = await getStockEntries(item.id);
      items.add(item);
    }

    return items;
  }

  Future<int> insertInventoryItem(String shopId, InventoryItem item) async {
    final db = await database;
    return await db.insert('inventory_items', {
      'id': item.id,
      'shop_id': shopId,
      'name': item.name,
      'price': item.price,
      'quantity': item.quantity,
      'created_date': item.createdDate.toIso8601String(),
      'last_updated': item.lastUpdated.toIso8601String(),
    });
  }

  Future<int> updateInventoryItem(InventoryItem item) async {
    final db = await database;
    return await db.update(
      'inventory_items',
      {
        'name': item.name,
        'price': item.price,
        'quantity': item.quantity,
        'last_updated': item.lastUpdated.toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<int> deleteInventoryItem(String itemId) async {
    final db = await database;
    return await db.delete('inventory_items', where: 'id = ?', whereArgs: [itemId]);
  }

  // Stock entry operations
  Future<List<StockEntry>> getStockEntries(String itemId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'stock_entries',
      where: 'item_id = ?',
      whereArgs: [itemId],
      orderBy: 'date_time DESC',
    );

    return List.generate(maps.length, (i) {
      return StockEntry(
        id: maps[i]['id'],
        quantity: maps[i]['quantity'],
        type: maps[i]['type'],
        dateTime: DateTime.parse(maps[i]['date_time']),
        note: maps[i]['note'],
      );
    });
  }

  Future<int> insertStockEntry(String itemId, StockEntry entry) async {
    final db = await database;
    return await db.insert('stock_entries', {
      'id': entry.id,
      'item_id': itemId,
      'quantity': entry.quantity,
      'type': entry.type,
      'date_time': entry.dateTime.toIso8601String(),
      'note': entry.note,
    });
  }

  // Transaction operations
  Future<List<trans.Transaction>> getTransactions(String shopId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'shop_id = ?',
      whereArgs: [shopId],
      orderBy: 'date_time DESC',
    );

    return List.generate(maps.length, (i) {
      return trans.Transaction(
        id: maps[i]['id'],
        itemId: maps[i]['item_id'],
        itemName: maps[i]['item_name'],
        quantity: maps[i]['quantity'],
        price: maps[i]['price'],
        totalAmount: maps[i]['total_amount'],
        dateTime: DateTime.parse(maps[i]['date_time']),
        type: maps[i]['type'],
      );
    });
  }

  Future<int> insertTransaction(String shopId, trans.Transaction transaction) async {
    final db = await database;
    return await db.insert('transactions', {
      'id': transaction.id,
      'shop_id': shopId,
      'item_id': transaction.itemId,
      'item_name': transaction.itemName,
      'quantity': transaction.quantity,
      'price': transaction.price,
      'total_amount': transaction.totalAmount,
      'date_time': transaction.dateTime.toIso8601String(),
      'type': transaction.type,
    });
  }

  Future<List<trans.Transaction>> getMonthlyTransactions(String shopId, DateTime month) async {
    final db = await database;
    final startDate = DateTime(month.year, month.month, 1);
    final endDate = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'shop_id = ? AND date_time >= ? AND date_time <= ?',
      whereArgs: [
        shopId,
        startDate.toIso8601String(),
        endDate.toIso8601String(),
      ],
      orderBy: 'date_time DESC',
    );

    return List.generate(maps.length, (i) {
      return trans.Transaction(
        id: maps[i]['id'],
        itemId: maps[i]['item_id'],
        itemName: maps[i]['item_name'],
        quantity: maps[i]['quantity'],
        price: maps[i]['price'],
        totalAmount: maps[i]['total_amount'],
        dateTime: DateTime.parse(maps[i]['date_time']),
        type: maps[i]['type'],
      );
    });
  }

  // Close database
  Future<void> close() async {
    final db = await database;
    db.close();
  }
}