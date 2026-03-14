import 'package:flutter/foundation.dart';
import '../models/shop.dart';
import '../models/inventory_item.dart';
import '../models/stock_entry.dart';
import '../models/transaction.dart';
import '../models/sale_order.dart';
import '../models/purchase.dart';
import '../models/customer.dart';
import '../models/supplier.dart';
import '../services/firebase_service.dart';

class ShopProvider with ChangeNotifier {
  List<Shop> _shops = [];
  Shop? _currentShop;
  final FirebaseService _db = FirebaseService();
  bool _isLoading = false;
  int _idCounter = 0;

  List<Shop> get shops => _shops;
  Shop? get currentShop => _currentShop;
  bool get isLoading => _isLoading;

  // Generate unique ID with timestamp and counter
  String _generateUniqueId() {
    _idCounter++;
    return '${DateTime.now().millisecondsSinceEpoch}_$_idCounter';
  }

  // Initialize and load data from Firestore
  Future<void> initializeData() async {
    _isLoading = true;
    notifyListeners();

    try {
      _shops = await _db.getAllShops();
    } catch (e) {
      debugPrint('Error loading shops: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  void setCurrentShop(Shop shop) {
    _currentShop = shop;
    notifyListeners();
  }

  // ─── SHOP CRUD ─────────────────────────────────────────────────────────────

  Future<void> addShop(Shop shop) async {
    try {
      await _db.insertShop(shop);
      _shops.add(shop);
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding shop: $e');
      rethrow;
    }
  }

  Future<void> updateShop(Shop updatedShop) async {
    try {
      await _db.updateShop(updatedShop);
      final index = _shops.indexWhere((s) => s.id == updatedShop.id);
      if (index != -1) {
        _shops[index] = updatedShop;
        if (_currentShop?.id == updatedShop.id) _currentShop = updatedShop;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating shop: $e');
      rethrow;
    }
  }

  Future<void> deleteShop(String shopId) async {
    try {
      await _db.deleteShop(shopId);
      _shops.removeWhere((s) => s.id == shopId);
      if (_currentShop?.id == shopId) _currentShop = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting shop: $e');
      rethrow;
    }
  }

  // ─── INVENTORY ITEMS ───────────────────────────────────────────────────────

  Future<void> addInventoryItem(String shopId, InventoryItem item) async {
    try {
      final shop = _shops.firstWhere((s) => s.id == shopId);
      final existingIndex = shop.inventory
          .indexWhere((i) => i.name.toLowerCase() == item.name.toLowerCase());

      if (existingIndex != -1) {
        final existingItem = shop.inventory[existingIndex];
        existingItem.quantity += item.quantity;
        existingItem.lastUpdated = DateTime.now();

        final stockEntry = StockEntry(
          id: _generateUniqueId(),
          quantity: item.quantity,
          type: 'addition',
          dateTime: DateTime.now(),
          note: 'Stock addition',
        );
        existingItem.stockEntries.add(stockEntry);

        await _db.updateInventoryItem(shopId, existingItem);
        await _db.insertStockEntry(shopId, existingItem.id, stockEntry);
      } else {
        final stockEntry = StockEntry(
          id: _generateUniqueId(),
          quantity: item.quantity,
          type: 'addition',
          dateTime: DateTime.now(),
          note: 'Initial stock',
        );
        item.stockEntries.add(stockEntry);
        shop.inventory.add(item);

        await _db.insertInventoryItem(shopId, item);
        await _db.insertStockEntry(shopId, item.id, stockEntry);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding inventory item: $e');
      rethrow;
    }
  }

  Future<void> updateInventoryItem(String shopId, InventoryItem updatedItem) async {
    try {
      await _db.updateInventoryItem(shopId, updatedItem);
      final shop = _shops.firstWhere((s) => s.id == shopId);
      final index = shop.inventory.indexWhere((i) => i.id == updatedItem.id);
      if (index != -1) {
        shop.inventory[index] = updatedItem;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating inventory item: $e');
      rethrow;
    }
  }

  Future<void> deleteInventoryItem(String shopId, String itemId) async {
    try {
      await _db.deleteInventoryItem(shopId, itemId);
      final shop = _shops.firstWhere((s) => s.id == shopId);
      shop.inventory.removeWhere((i) => i.id == itemId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting inventory item: $e');
      rethrow;
    }
  }

  // ─── SELL / STOCK ──────────────────────────────────────────────────────────

  Future<void> sellItem(String shopId, String itemId, int quantity) async {
    try {
      final shop = _shops.firstWhere((s) => s.id == shopId);
      final item = shop.inventory.firstWhere((i) => i.id == itemId);

      if (item.quantity >= quantity) {
        item.quantity -= quantity;
        item.lastUpdated = DateTime.now();

        final stockEntry = StockEntry(
          id: _generateUniqueId(),
          quantity: quantity,
          type: 'sale',
          dateTime: DateTime.now(),
          note: 'Item sold',
        );
        item.stockEntries.add(stockEntry);

        final transaction = Transaction(
          id: _generateUniqueId(),
          itemId: itemId,
          itemName: item.name,
          quantity: quantity,
          price: item.price,
          totalAmount: item.price * quantity,
          dateTime: DateTime.now(),
          type: 'sale',
        );
        shop.transactions.add(transaction);

        await _db.updateInventoryItem(shopId, item);
        await _db.insertStockEntry(shopId, item.id, stockEntry);
        await _db.insertTransaction(shopId, transaction);

        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error selling item: $e');
      rethrow;
    }
  }

  Future<void> addStock(String shopId, String itemId, int quantity) async {
    try {
      final shop = _shops.firstWhere((s) => s.id == shopId);
      final item = shop.inventory.firstWhere((i) => i.id == itemId);

      item.quantity += quantity;
      item.lastUpdated = DateTime.now();

      final stockEntry = StockEntry(
        id: _generateUniqueId(),
        quantity: quantity,
        type: 'addition',
        dateTime: DateTime.now(),
        note: 'Stock addition',
      );
      item.stockEntries.add(stockEntry);

      await _db.updateInventoryItem(shopId, item);
      await _db.insertStockEntry(shopId, item.id, stockEntry);

      notifyListeners();
    } catch (e) {
      debugPrint('Error adding stock: $e');
      rethrow;
    }
  }

  // ─── PURCHASES ─────────────────────────────────────────────────────────────

  Future<void> recordPurchase({
    required String shopId,
    required InventoryItem item,
    required int quantity,
    required double unitPurchasePrice,
    required String partyName,
    required String partyAddress,
    required double totalPayment,
    required double paidAmount,
    String? note,
  }) async {
    try {
      final shop = _shops.firstWhere((s) => s.id == shopId);
      final existingItemIndex =
          shop.inventory.indexWhere((i) => i.id == item.id);
      if (existingItemIndex == -1) throw Exception('Item not found in shop inventory');

      final stockEntry = StockEntry(
        id: _generateUniqueId(),
        quantity: quantity,
        type: 'addition',
        dateTime: DateTime.now(),
        note: 'Purchase stock',
      );

      shop.inventory[existingItemIndex].quantity += quantity;
      shop.inventory[existingItemIndex].lastUpdated = DateTime.now();
      shop.inventory[existingItemIndex].stockEntries.add(stockEntry);

      await _db.updateInventoryItem(shopId, shop.inventory[existingItemIndex]);
      await _db.insertStockEntry(shopId, item.id, stockEntry);

      final purchase = Purchase(
        id: _generateUniqueId(),
        shopId: shopId,
        itemId: item.id,
        itemName: item.name,
        quantity: quantity,
        unitPurchasePrice: unitPurchasePrice,
        totalAmount: unitPurchasePrice * quantity,
        partyName: partyName,
        partyAddress: partyAddress,
        totalPayment: totalPayment,
        paidAmount: paidAmount,
        dateTime: DateTime.now(),
        note: note,
      );
      await _db.insertPurchase(purchase);

      notifyListeners();
    } catch (e) {
      debugPrint('Error recording purchase: $e');
      rethrow;
    }
  }

  Future<List<Purchase>> getPurchases(String shopId) async {
    try {
      return await _db.getPurchases(shopId);
    } catch (e) {
      debugPrint('Error getting purchases: $e');
      return [];
    }
  }

  Future<void> updatePurchasePayment({
    required String shopId,
    required String purchaseId,
    required double paidAmount,
  }) async {
    try {
      await _db.updatePurchasePayment(
          shopId: shopId, purchaseId: purchaseId, paidAmount: paidAmount);
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating purchase payment: $e');
      rethrow;
    }
  }

  // ─── SALE ORDERS ───────────────────────────────────────────────────────────

  Future<void> createSaleOrder(String shopId, SaleOrder saleOrder) async {
    try {
      final shop = _shops.firstWhere((s) => s.id == shopId);

      for (final saleItem in saleOrder.items) {
        if (saleItem.isTemporaryItem) {
          final transaction = Transaction(
            id: _generateUniqueId(),
            itemId: 'temp_${DateTime.now().millisecondsSinceEpoch}',
            itemName: saleItem.itemName,
            quantity: saleItem.quantity,
            price: saleItem.unitPrice,
            totalAmount: saleItem.totalPrice,
            dateTime: saleOrder.dateTime,
            type: 'sale',
            orderId: saleOrder.id,
          );
          shop.transactions.add(transaction);
          await _db.insertTransaction(shopId, transaction);
        } else {
          final item =
              shop.inventory.firstWhere((i) => i.id == saleItem.item!.id);
          if (item.quantity >= saleItem.quantity) {
            item.quantity -= saleItem.quantity;
            item.lastUpdated = DateTime.now();

            final stockEntry = StockEntry(
              id: _generateUniqueId(),
              quantity: saleItem.quantity,
              type: 'sale',
              dateTime: DateTime.now(),
              note: 'Item sold in order ${saleOrder.billNumber}',
            );
            item.stockEntries.add(stockEntry);

            final transaction = Transaction(
              id: _generateUniqueId(),
              itemId: saleItem.item!.id,
              itemName: saleItem.itemName,
              quantity: saleItem.quantity,
              price: saleItem.unitPrice,
              totalAmount: saleItem.totalPrice,
              dateTime: saleOrder.dateTime,
              type: 'sale',
              orderId: saleOrder.id,
            );
            shop.transactions.add(transaction);

            await _db.updateInventoryItem(shopId, item);
            await _db.insertStockEntry(shopId, item.id, stockEntry);
            await _db.insertTransaction(shopId, transaction);
          } else {
            throw Exception('Insufficient stock for ${item.name}');
          }
        }
      }

      shop.saleOrders.add(saleOrder);
      await _db.insertSaleOrder(saleOrder);
      notifyListeners();
    } catch (e) {
      debugPrint('Error creating sale order: $e');
      rethrow;
    }
  }

  Future<void> updateSaleOrderPayment({
    required String shopId,
    required String orderId,
    required double paidAmount,
  }) async {
    try {
      await _db.updateSaleOrderPayment(
          shopId: shopId, orderId: orderId, paidAmount: paidAmount);

      for (final shop in _shops) {
        final orderIndex =
            shop.saleOrders.indexWhere((o) => o.id == orderId);
        if (orderIndex != -1) {
          shop.saleOrders[orderIndex] =
              shop.saleOrders[orderIndex].copyWith(paidAmount: paidAmount);
          break;
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating sale order payment: $e');
      rethrow;
    }
  }

  List<SaleOrder> getSaleOrders(String shopId) {
    try {
      return _shops.firstWhere((s) => s.id == shopId).saleOrders;
    } catch (e) {
      return [];
    }
  }

  List<SaleOrder> getMonthlySaleOrders(String shopId, DateTime month) {
    try {
      return _shops
          .firstWhere((s) => s.id == shopId)
          .saleOrders
          .where((o) =>
              o.dateTime.year == month.year &&
              o.dateTime.month == month.month)
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<SaleOrder>> getSaleOrdersFromDb(String shopId) async {
    try {
      return await _db.getSaleOrders(shopId);
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getSaleOrderItems(
      String shopId, String orderId) async {
    try {
      return await _db.getSaleOrderItems(shopId, orderId);
    } catch (e) {
      return [];
    }
  }

  Future<List<Transaction>> getMonthlyTransactions(
      String shopId, DateTime month) async {
    try {
      return await _db.getMonthlyTransactions(shopId, month);
    } catch (e) {
      return [];
    }
  }

  // ─── CUSTOMERS ─────────────────────────────────────────────────────────────

  Future<void> insertCustomer(String shopId, Customer customer) async {
    await _db.insertCustomer(shopId, customer);
  }

  Future<List<Customer>> getCustomers(String shopId) async {
    try {
      return await _db.getCustomers(shopId);
    } catch (e) {
      return [];
    }
  }

  Future<Customer?> getCustomerByPhone(String shopId, String phone) async {
    try {
      return await _db.getCustomerByPhone(shopId, phone);
    } catch (e) {
      return null;
    }
  }

  Future<void> deleteCustomer(String shopId, String customerId) async {
    await _db.deleteCustomer(shopId, customerId);
  }

  // ─── SUPPLIERS ─────────────────────────────────────────────────────────────

  Future<void> insertSupplier(String shopId, Supplier supplier) async {
    await _db.insertSupplier(shopId, supplier);
  }

  Future<List<Supplier>> getSuppliers(String shopId) async {
    try {
      return await _db.getSuppliers(shopId);
    } catch (e) {
      return [];
    }
  }

  Future<Supplier?> getSupplierByName(String shopId, String name) async {
    try {
      return await _db.getSupplierByName(shopId, name);
    } catch (e) {
      return null;
    }
  }

  Future<void> deleteSupplier(String shopId, String supplierId) async {
    await _db.deleteSupplier(shopId, supplierId);
  }

  // ─── STATISTICS (direct Firestore for stats screen) ────────────────────────

  Future<List<InventoryItem>> getInventoryItems(String shopId) async {
    try {
      return await _db.getInventoryItems(shopId);
    } catch (e) {
      return [];
    }
  }
}
