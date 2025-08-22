import 'package:flutter/foundation.dart';
import '../models/shop.dart';
import '../models/inventory_item.dart';
import '../models/stock_entry.dart';
import '../models/transaction.dart';
import '../models/sale.dart';
import '../models/sale_item.dart';
import '../models/additional_cost.dart';
import '../database/database_helper.dart';

class ShopProvider with ChangeNotifier {

  List<Shop> _shops = [];
  Shop? _currentShop;
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  bool _isLoading = false;

  List<Shop> get shops => _shops;
  Shop? get currentShop => _currentShop;
  bool get isLoading => _isLoading;

  // Initialize and load data from database
  Future<void> initializeData() async {
    _isLoading = true;
    notifyListeners();

    try {
      _shops = await _databaseHelper.getAllShops();
    } catch (e) {
      print('Error loading shops: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  void setCurrentShop(Shop shop) {
    _currentShop = shop;
    notifyListeners();
  }

  Future<void> addShop(Shop shop) async {
    try {
      await _databaseHelper.insertShop(shop);
      _shops.add(shop);
      notifyListeners();
    } catch (e) {
      print('Error adding shop: $e');
      throw e;
    }
  }

  Future<void> updateShop(Shop updatedShop) async {
    try {
      await _databaseHelper.updateShop(updatedShop);
      final index = _shops.indexWhere((shop) => shop.id == updatedShop.id);
      if (index != -1) {
        _shops[index] = updatedShop;
        if (_currentShop?.id == updatedShop.id) {
          _currentShop = updatedShop;
        }
        notifyListeners();
      }
    } catch (e) {
      print('Error updating shop: $e');
      throw e;
    }
  }

  Future<void> deleteShop(String shopId) async {
    try {
      await _databaseHelper.deleteShop(shopId);
      _shops.removeWhere((shop) => shop.id == shopId);
      if (_currentShop?.id == shopId) {
        _currentShop = null;
      }
      notifyListeners();
    } catch (e) {
      print('Error deleting shop: $e');
      throw e;
    }
  }

  Future<void> addInventoryItem(String shopId, InventoryItem item) async {
    try {
      final shop = _shops.firstWhere((s) => s.id == shopId);

      // Check if item already exists
      final existingIndex = shop.inventory.indexWhere((i) => i.name.toLowerCase() == item.name.toLowerCase());

      if (existingIndex != -1) {
        // Add to existing item
        final existingItem = shop.inventory[existingIndex];
        existingItem.quantity += item.quantity;
        existingItem.lastUpdated = DateTime.now();

        final stockEntry = StockEntry(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          quantity: item.quantity,
          type: 'addition',
          dateTime: DateTime.now(),
          note: 'Stock addition',
        );

        existingItem.stockEntries.add(stockEntry);

        await _databaseHelper.updateInventoryItem(existingItem);
        await _databaseHelper.insertStockEntry(existingItem.id, stockEntry);
      } else {
        // Add new item
        final stockEntry = StockEntry(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          quantity: item.quantity,
          type: 'addition',
          dateTime: DateTime.now(),
          note: 'Initial stock',
        );

        item.stockEntries.add(stockEntry);
        shop.inventory.add(item);

        await _databaseHelper.insertInventoryItem(shopId, item);
        await _databaseHelper.insertStockEntry(item.id, stockEntry);
      }

      notifyListeners();
    } catch (e) {
      print('Error adding inventory item: $e');
      throw e;
    }
  }

  Future<void> updateInventoryItem(String shopId, InventoryItem updatedItem) async {
    try {
      await _databaseHelper.updateInventoryItem(updatedItem);
      final shop = _shops.firstWhere((s) => s.id == shopId);
      final index = shop.inventory.indexWhere((item) => item.id == updatedItem.id);
      if (index != -1) {
        shop.inventory[index] = updatedItem;
        notifyListeners();
      }
    } catch (e) {
      print('Error updating inventory item: $e');
      throw e;
    }
  }

  Future<void> deleteInventoryItem(String shopId, String itemId) async {
    try {
      await _databaseHelper.deleteInventoryItem(itemId);
      final shop = _shops.firstWhere((s) => s.id == shopId);
      shop.inventory.removeWhere((item) => item.id == itemId);
      notifyListeners();
    } catch (e) {
      print('Error deleting inventory item: $e');
      throw e;
    }
  }

  Future<void> sellItem(String shopId, String itemId, int quantity) async {
    try {
      final shop = _shops.firstWhere((s) => s.id == shopId);
      final item = shop.inventory.firstWhere((i) => i.id == itemId);

      if (item.quantity >= quantity) {
        item.quantity -= quantity;
        item.lastUpdated = DateTime.now();

        // Add stock entry
        final stockEntry = StockEntry(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          quantity: quantity,
          type: 'sale',
          dateTime: DateTime.now(),
          note: 'Item sold',
        );

        item.stockEntries.add(stockEntry);

        // Add transaction
        final transaction = Transaction(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          itemId: itemId,
          itemName: item.name,
          quantity: quantity,
          price: item.price,
          totalAmount: item.price * quantity,
          dateTime: DateTime.now(),
          type: 'sale',
        );

        shop.transactions.add(transaction);

        // Update database
        await _databaseHelper.updateInventoryItem(item);
        await _databaseHelper.insertStockEntry(item.id, stockEntry);
        await _databaseHelper.insertTransaction(shopId, transaction);

        notifyListeners();
      }
    } catch (e) {
      print('Error selling item: $e');
      throw e;
    }
  }

  Future<void> addStock(String shopId, String itemId, int quantity) async {
    try {
      final shop = _shops.firstWhere((s) => s.id == shopId);
      final item = shop.inventory.firstWhere((i) => i.id == itemId);

      item.quantity += quantity;
      item.lastUpdated = DateTime.now();

      // Add stock entry
      final stockEntry = StockEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        quantity: quantity,
        type: 'addition',
        dateTime: DateTime.now(),
        note: 'Stock addition',
      );

      item.stockEntries.add(stockEntry);

      // Update database
      await _databaseHelper.updateInventoryItem(item);
      await _databaseHelper.insertStockEntry(item.id, stockEntry);

      notifyListeners();
    } catch (e) {
      print('Error adding stock: $e');
      throw e;
    }
  }

  Future<List<Transaction>> getMonthlyTransactions(String shopId, DateTime month) async {
    try {
      return await _databaseHelper.getMonthlyTransactions(shopId, month);
    } catch (e) {
      print('Error getting monthly transactions: $e');
      return [];
    }
  }

  // New method to handle multi-item sales with temporary prices and additional costs
  Future<void> completeSale(Sale sale) async {
    try {
      final shop = _shops.firstWhere((s) => s.id == sale.shopId);
      
      // Process each sale item
      for (final saleItem in sale.items) {
        final inventoryItem = shop.inventory.firstWhere((item) => item.id == saleItem.itemId);
        
        // Check if we have enough stock
        if (inventoryItem.quantity < saleItem.quantity) {
          throw Exception('Insufficient stock for ${saleItem.itemName}. Available: ${inventoryItem.quantity}, Required: ${saleItem.quantity}');
        }
        
        // Reduce inventory
        inventoryItem.quantity -= saleItem.quantity;
        inventoryItem.lastUpdated = DateTime.now();
        
        // Add stock entry for the sale
        final stockEntry = StockEntry(
          id: '${sale.id}_${saleItem.itemId}_${DateTime.now().millisecondsSinceEpoch}',
          quantity: saleItem.quantity,
          type: 'sale',
          dateTime: sale.dateTime,
          note: 'Multi-item sale${saleItem.isPriceModified ? ' (Price: ₹${saleItem.salePrice})' : ''}',
        );
        
        inventoryItem.stockEntries.add(stockEntry);
        
        // Create individual transaction for compatibility with existing system
        final transaction = Transaction(
          id: '${sale.id}_${saleItem.itemId}',
          itemId: saleItem.itemId,
          itemName: saleItem.itemName,
          quantity: saleItem.quantity,
          price: saleItem.salePrice, // Use the temporary sale price
          totalAmount: saleItem.totalAmount,
          dateTime: sale.dateTime,
          type: 'sale',
        );
        
        shop.transactions.add(transaction);
        
        // Update database for this item
        await _databaseHelper.updateInventoryItem(inventoryItem);
        await _databaseHelper.insertStockEntry(inventoryItem.id, stockEntry);
        await _databaseHelper.insertTransaction(sale.shopId, transaction);
      }
      
      // If there are additional costs, create a separate transaction for them
      if (sale.additionalCosts.isNotEmpty) {
        for (final additionalCost in sale.additionalCosts) {
          final additionalTransaction = Transaction(
            id: '${sale.id}_additional_${additionalCost.id}',
            itemId: 'additional_cost',
            itemName: additionalCost.name,
            quantity: 1,
            price: additionalCost.amount,
            totalAmount: additionalCost.amount,
            dateTime: sale.dateTime,
            type: 'additional_cost',
          );
          
          shop.transactions.add(additionalTransaction);
          await _databaseHelper.insertTransaction(sale.shopId, additionalTransaction);
        }
      }
      
      // Store the complete sale record
      await _databaseHelper.insertSale(sale);
      
      notifyListeners();
    } catch (e) {
      print('Error completing sale: $e');
      throw e;
    }
  }

  // Get all sales for a shop
  Future<List<Sale>> getSales(String shopId) async {
    try {
      return await _databaseHelper.getSales(shopId);
    } catch (e) {
      print('Error getting sales: $e');
      return [];
    }
  }

  // Get a specific sale by ID
  Future<Sale?> getSale(String saleId) async {
    try {
      return await _databaseHelper.getSale(saleId);
    } catch (e) {
      print('Error getting sale: $e');
      return null;
    }
  }

  // Get sales for a specific month
  Future<List<Sale>> getMonthlySales(String shopId, DateTime month) async {
    try {
      return await _databaseHelper.getMonthlySales(shopId, month);
    } catch (e) {
      print('Error getting monthly sales: $e');
      return [];
    }
  }
}