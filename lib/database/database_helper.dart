import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/inventory_item.dart';
import '../models/shop.dart';
import '../models/stock_entry.dart';
import '../models/transaction.dart' as trans;
import '../models/purchase.dart';
import '../models/sale_order.dart' as order_models;

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
      version: 3,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
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
        order_id TEXT,
        FOREIGN KEY (shop_id) REFERENCES shops (id) ON DELETE CASCADE
      )
    ''');

    // Create purchases table
    await db.execute('''
      CREATE TABLE purchases(
        id TEXT PRIMARY KEY,
        shop_id TEXT NOT NULL,
        item_id TEXT NOT NULL,
        item_name TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        unit_purchase_price REAL NOT NULL,
        total_amount REAL NOT NULL,
        party_name TEXT NOT NULL,
        party_address TEXT,
        total_payment REAL NOT NULL,
        paid_amount REAL NOT NULL,
        date_time TEXT NOT NULL,
        note TEXT,
        FOREIGN KEY (shop_id) REFERENCES shops (id) ON DELETE CASCADE,
        FOREIGN KEY (item_id) REFERENCES inventory_items (id) ON DELETE CASCADE
      )
    ''');

    // Create sale_orders table
    await db.execute('''
      CREATE TABLE sale_orders(
        id TEXT PRIMARY KEY,
        shop_id TEXT NOT NULL,
        customer_name TEXT NOT NULL,
        customer_phone TEXT,
        date_time TEXT NOT NULL,
        subtotal REAL NOT NULL,
        tax REAL NOT NULL,
        total REAL NOT NULL,
        bill_number TEXT NOT NULL,
        paid_amount REAL NOT NULL,
        FOREIGN KEY (shop_id) REFERENCES shops (id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS purchases(
          id TEXT PRIMARY KEY,
          shop_id TEXT NOT NULL,
          item_id TEXT NOT NULL,
          item_name TEXT NOT NULL,
          quantity INTEGER NOT NULL,
          unit_purchase_price REAL NOT NULL,
          total_amount REAL NOT NULL,
          party_name TEXT NOT NULL,
          party_address TEXT,
          total_payment REAL NOT NULL,
          paid_amount REAL NOT NULL,
          date_time TEXT NOT NULL,
          note TEXT,
          FOREIGN KEY (shop_id) REFERENCES shops (id) ON DELETE CASCADE,
          FOREIGN KEY (item_id) REFERENCES inventory_items (id) ON DELETE CASCADE
        )
      ''');
    }
    if (oldVersion < 3) {
      // Add order_id column if missing
      await db.execute('ALTER TABLE transactions ADD COLUMN order_id TEXT');
      // Create sale_orders table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS sale_orders(
          id TEXT PRIMARY KEY,
          shop_id TEXT NOT NULL,
          customer_name TEXT NOT NULL,
          customer_phone TEXT,
          date_time TEXT NOT NULL,
          subtotal REAL NOT NULL,
          tax REAL NOT NULL,
          total REAL NOT NULL,
          bill_number TEXT NOT NULL,
          paid_amount REAL NOT NULL,
          FOREIGN KEY (shop_id) REFERENCES shops (id) ON DELETE CASCADE
        )
      ''');
    }
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
      shop.transactions =
          (await getTransactions(shop.id)).cast<trans.Transaction>();

      // We do not load purchases here to keep memory usage light

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
    return await db.delete(
      'inventory_items',
      where: 'id = ?',
      whereArgs: [itemId],
    );
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

  Future<int> insertTransaction(
    String shopId,
    trans.Transaction transaction,
  ) async {
    final db = await database;
    final data = {
      'id': transaction.id,
      'shop_id': shopId,
      'item_id': transaction.itemId,
      'item_name': transaction.itemName,
      'quantity': transaction.quantity,
      'price': transaction.price,
      'total_amount': transaction.totalAmount,
      'date_time': transaction.dateTime.toIso8601String(),
      'type': transaction.type,
    };
    // Try insert with order_id when available; if the column doesn't exist, retry without it
    if (transaction.orderId != null) {
      try {
        final withOrder = Map<String, Object?>.from(data)
          ..['order_id'] = transaction.orderId;
        return await db.insert('transactions', withOrder);
      } catch (e) {
        // Fallback: retry without order_id (older DB without migration)
        return await db.insert('transactions', data);
      }
    }
    return await db.insert('transactions', data);
  }

  Future<List<trans.Transaction>> getMonthlyTransactions(
    String shopId,
    DateTime month,
  ) async {
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

  // Purchase operations
  Future<int> insertPurchase(Purchase purchase) async {
    final db = await database;
    return await db.insert('purchases', purchase.toMap());
  }

  Future<List<Purchase>> getPurchases(String shopId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'purchases',
      where: 'shop_id = ?',
      whereArgs: [shopId],
      orderBy: 'date_time DESC',
    );
    return maps.map((m) => Purchase.fromMap(m)).toList();
  }

  Future<List<Purchase>> getPurchasesByItem(String itemId) async {
    final db = await database;
    final maps = await db.query(
      'purchases',
      where: 'item_id = ?',
      whereArgs: [itemId],
      orderBy: 'date_time DESC',
    );
    return maps.map((m) => Purchase.fromMap(m)).toList();
  }

  Future<int> updatePurchasePayment({
    required String purchaseId,
    required double paidAmount,
  }) async {
    final db = await database;
    return await db.update(
      'purchases',
      {'paid_amount': paidAmount},
      where: 'id = ?',
      whereArgs: [purchaseId],
    );
  }

  Future<int> updateSaleOrderPayment({
    required String orderId,
    required double paidAmount,
  }) async {
    final db = await database;
    return await db.update(
      'sale_orders',
      {'paid_amount': paidAmount},
      where: 'id = ?',
      whereArgs: [orderId],
    );
  }

  // Sale order operations
  Future<int> insertSaleOrder(order_models.SaleOrder saleOrder) async {
    final db = await database;
    return await db.insert('sale_orders', saleOrder.toMap());
  }

  Future<List<order_models.SaleOrder>> getSaleOrders(String shopId) async {
    final db = await database;
    final maps = await db.query(
      'sale_orders',
      where: 'shop_id = ?',
      whereArgs: [shopId],
      orderBy: 'date_time DESC',
    );
    return maps
        .map(
          (m) => order_models.SaleOrder(
            id: m['id'] as String,
            shopId: m['shop_id'] as String,
            items: const [],
            additionalCharges: const [],
            customerName: m['customer_name'] as String,
            customerPhone: (m['customer_phone'] ?? '') as String,
            dateTime: DateTime.parse(m['date_time'] as String),
            subtotal: (m['subtotal'] as num).toDouble(),
            tax: (m['tax'] as num).toDouble(),
            total: (m['total'] as num).toDouble(),
            billNumber: m['bill_number'] as String,
            paidAmount: (m['paid_amount'] as num).toDouble(),
          ),
        )
        .toList();
  }

  Future<List<Map<String, dynamic>>> getSaleOrderItems(String orderId) async {
    final db = await database;
    return await db.query(
      'transactions',
      columns: ['item_name', 'quantity', 'price', 'total_amount'],
      where: 'order_id = ? AND type = ?',
      whereArgs: [orderId, 'sale'],
      orderBy: 'date_time ASC',
    );
  }
}
