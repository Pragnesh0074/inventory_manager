import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/inventory_item.dart';
import '../models/shop.dart';
import '../models/stock_entry.dart';
import '../models/transaction.dart' as trans;
import '../models/purchase.dart';
import '../models/sale_order.dart' as order_models;
import '../models/customer.dart';
import '../models/supplier.dart';

/// Firestore-backed service that mirrors the [DatabaseHelper] API.
/// All documents are scoped under the current user's UID:
///   users/{uid}/shops/{shopId}/...
class FirebaseService {
  
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  FirebaseFirestore get _db => FirebaseFirestore.instance;
  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';
  bool get _isLoggedIn => FirebaseAuth.instance.currentUser != null;

  // ---------- COLLECTION PATHS ----------
  CollectionReference get _shops =>
      _db.collection('users').doc(_uid).collection('shops');

  CollectionReference _inventoryItems(String shopId) =>
      _shops.doc(shopId).collection('inventory_items');

  CollectionReference _stockEntries(String shopId, String itemId) =>
      _inventoryItems(shopId).doc(itemId).collection('stock_entries');

  CollectionReference _transactions(String shopId) =>
      _shops.doc(shopId).collection('transactions');

  CollectionReference _purchases(String shopId) =>
      _shops.doc(shopId).collection('purchases');

  CollectionReference _saleOrders(String shopId) =>
      _shops.doc(shopId).collection('sale_orders');

  CollectionReference _customers(String shopId) =>
      _shops.doc(shopId).collection('customers');

  CollectionReference _suppliers(String shopId) =>
      _shops.doc(shopId).collection('suppliers');

  // ---------- SHOP OPERATIONS ----------

  Future<List<Shop>> getAllShops() async {
    if (!_isLoggedIn) return [];
    final snapshot = await _shops.get();
    final List<Shop> shops = [];

    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final shop = Shop.fromJson({...data, 'id': doc.id});

      final results = await Future.wait([
        getInventoryItems(shop.id),
        getTransactions(shop.id),
        getSaleOrders(shop.id),
      ]);

      shop.inventory = results[0] as List<InventoryItem>;
      shop.transactions = (results[1] as List<trans.Transaction>);
      shop.saleOrders = results[2] as List<order_models.SaleOrder>;

      shops.add(shop);
    }
    return shops;
  }

  Future<void> insertShop(Shop shop) async {
    await _shops.doc(shop.id).set({
      'id': shop.id,
      'name': shop.name,
      'address': shop.address,
      'created_date': shop.createdDate.toIso8601String(),
      'gst_percentage': shop.gstPercentage,
    });
  }

  Future<void> updateShop(Shop shop) async {
    await _shops.doc(shop.id).update({
      'name': shop.name,
      'address': shop.address,
      'created_date': shop.createdDate.toIso8601String(),
      'gst_percentage': shop.gstPercentage,
    });
  }

  Future<void> deleteShop(String shopId) async {
    // Firestore doesn't auto-delete subcollections, but this is fine for now.
    await _shops.doc(shopId).delete();
  }

  // ---------- INVENTORY ITEM OPERATIONS ----------

  Future<List<InventoryItem>> getInventoryItems(String shopId) async {
    if (!_isLoggedIn) return [];
    final snapshot = await _inventoryItems(shopId).get();
    final List<InventoryItem> items = [];

    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final item = InventoryItem(
        id: doc.id,
        name: data['name'] ?? 'Unknown',
        price: (data['price'] as num?)?.toDouble() ?? 0.0,
        quantity: (data['quantity'] as num?)?.toInt() ?? 0,
        createdDate: data['created_date'] != null
            ? DateTime.parse(data['created_date'])
            : DateTime.now(),
        lastUpdated: data['last_updated'] != null
            ? DateTime.parse(data['last_updated'])
            : DateTime.now(),
      );
      item.stockEntries = await getStockEntries(shopId, item.id);
      items.add(item);
    }
    return items;
  }

  Future<void> insertInventoryItem(String shopId, InventoryItem item) async {
    await _inventoryItems(shopId).doc(item.id).set({
      'id': item.id,
      'shop_id': shopId,
      'name': item.name,
      'price': item.price,
      'quantity': item.quantity,
      'created_date': item.createdDate.toIso8601String(),
      'last_updated': item.lastUpdated.toIso8601String(),
    });
  }

  Future<void> updateInventoryItem(String shopId, InventoryItem item) async {
    await _inventoryItems(shopId).doc(item.id).update({
      'name': item.name,
      'price': item.price,
      'quantity': item.quantity,
      'last_updated': item.lastUpdated.toIso8601String(),
    });
  }

  Future<void> deleteInventoryItem(String shopId, String itemId) async {
    await _inventoryItems(shopId).doc(itemId).delete();
  }

  // ---------- STOCK ENTRY OPERATIONS ----------

  Future<List<StockEntry>> getStockEntries(String shopId, String itemId) async {
    final snapshot =
        await _stockEntries(
          shopId,
          itemId,
        ).orderBy('date_time', descending: true).get();
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return StockEntry(
        id: doc.id,
        quantity: (data['quantity'] as num).toInt(),
        type: data['type'],
        dateTime: DateTime.parse(data['date_time']),
        note: data['note'],
      );
    }).toList();
  }

  Future<void> insertStockEntry(
    String shopId,
    String itemId,
    StockEntry entry,
  ) async {
    await _stockEntries(shopId, itemId).doc(entry.id).set({
      'id': entry.id,
      'item_id': itemId,
      'quantity': entry.quantity,
      'type': entry.type,
      'date_time': entry.dateTime.toIso8601String(),
      'note': entry.note,
    });
  }

  // ---------- TRANSACTION OPERATIONS ----------

  Future<List<trans.Transaction>> getTransactions(String shopId) async {
    final snapshot =
        await _transactions(
          shopId,
        ).orderBy('date_time', descending: true).get();
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return trans.Transaction(
        id: doc.id,
        itemId: data['item_id'],
        itemName: data['item_name'],
        quantity: (data['quantity'] as num).toInt(),
        price: (data['price'] as num).toDouble(),
        totalAmount: (data['total_amount'] as num).toDouble(),
        dateTime: DateTime.parse(data['date_time']),
        type: data['type'],
        orderId: data['order_id'],
      );
    }).toList();
  }

  Future<void> insertTransaction(
    String shopId,
    trans.Transaction transaction,
  ) async {
    await _transactions(shopId).doc(transaction.id).set({
      'id': transaction.id,
      'shop_id': shopId,
      'item_id': transaction.itemId,
      'item_name': transaction.itemName,
      'quantity': transaction.quantity,
      'price': transaction.price,
      'total_amount': transaction.totalAmount,
      'date_time': transaction.dateTime.toIso8601String(),
      'type': transaction.type,
      'order_id': transaction.orderId,
    });
  }

  Future<List<trans.Transaction>> getMonthlyTransactions(
    String shopId,
    DateTime month,
  ) async {
    final startDate = DateTime(month.year, month.month, 1);
    final endDate = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

    final snapshot =
        await _transactions(shopId)
            .where(
              'date_time',
              isGreaterThanOrEqualTo: startDate.toIso8601String(),
            )
            .where('date_time', isLessThanOrEqualTo: endDate.toIso8601String())
            .orderBy('date_time', descending: true)
            .get();

    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return trans.Transaction(
        id: doc.id,
        itemId: data['item_id'],
        itemName: data['item_name'],
        quantity: (data['quantity'] as num).toInt(),
        price: (data['price'] as num).toDouble(),
        totalAmount: (data['total_amount'] as num).toDouble(),
        dateTime: DateTime.parse(data['date_time']),
        type: data['type'],
        orderId: data['order_id'],
      );
    }).toList();
  }

  // ---------- PURCHASE OPERATIONS ----------

  Future<void> insertPurchase(Purchase purchase) async {
    await _purchases(purchase.shopId).doc(purchase.id).set(purchase.toMap());
  }

  Future<List<Purchase>> getPurchases(String shopId) async {
    final snapshot =
        await _purchases(shopId).orderBy('date_time', descending: true).get();
    return snapshot.docs
        .map((doc) => Purchase.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
  }

  Future<void> updatePurchasePayment({
    required String shopId,
    required String purchaseId,
    required double paidAmount,
  }) async {
    await _purchases(
      shopId,
    ).doc(purchaseId).update({'paid_amount': paidAmount});
  }

  // ---------- SALE ORDER OPERATIONS ----------

  Future<void> insertSaleOrder(order_models.SaleOrder saleOrder) async {
    await _saleOrders(
      saleOrder.shopId,
    ).doc(saleOrder.id).set(saleOrder.toMap());
  }

  Future<List<order_models.SaleOrder>> getSaleOrders(String shopId) async {
    final snapshot =
        await _saleOrders(shopId).orderBy('date_time', descending: true).get();

    final List<order_models.SaleOrder> orders = [];
    for (final doc in snapshot.docs) {
      final m = doc.data() as Map<String, dynamic>;
      final order = order_models.SaleOrder(
        id: doc.id,
        shopId: shopId,
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
      );

      // Load items from transactions
      final txSnapshot =
          await _transactions(shopId)
              .where('order_id', isEqualTo: order.id)
              .where('type', isEqualTo: 'sale')
              .orderBy('date_time')
              .get();

      final items =
          txSnapshot.docs.map((txDoc) {
            final im = txDoc.data() as Map<String, dynamic>;
            return order_models.SaleItem(
              temporaryItemName: im['item_name'] as String,
              temporaryItemPrice: (im['price'] as num?)?.toDouble(),
              quantity: (im['quantity'] as num?)?.toInt() ?? 0,
              unitPrice: (im['price'] as num?)?.toDouble() ?? 0.0,
            );
          }).toList();

      orders.add(order.copyWith(items: items));
    }
    return orders;
  }

  Future<void> updateSaleOrderPayment({
    required String shopId,
    required String orderId,
    required double paidAmount,
  }) async {
    await _saleOrders(shopId).doc(orderId).update({'paid_amount': paidAmount});
  }

  Future<List<Map<String, dynamic>>> getSaleOrderItems(
    String shopId,
    String orderId,
  ) async {
    final snapshot =
        await _transactions(shopId)
            .where('order_id', isEqualTo: orderId)
            .where('type', isEqualTo: 'sale')
            .orderBy('date_time')
            .get();

    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return {
        'item_name': data['item_name'],
        'quantity': data['quantity'],
        'price': data['price'],
        'total_amount': data['total_amount'],
      };
    }).toList();
  }

  // ---------- CUSTOMER OPERATIONS ----------

  Future<void> insertCustomer(String shopId, Customer customer) async {
    await _customers(shopId).doc(customer.id).set(customer.toMap());
  }

  Future<List<Customer>> getCustomers(String shopId) async {
    final snapshot = await _customers(shopId).orderBy('name').get();
    return snapshot.docs
        .map((doc) => Customer.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
  }

  Future<Customer?> getCustomerByName(String shopId, String name) async {
    final snapshot =
        await _customers(shopId).where('name', isEqualTo: name).limit(1).get();
    if (snapshot.docs.isNotEmpty) {
      return Customer.fromMap(
        snapshot.docs.first.data() as Map<String, dynamic>,
      );
    }
    return null;
  }

  Future<Customer?> getCustomerByPhone(String shopId, String phone) async {
    final snapshot =
        await _customers(
          shopId,
        ).where('phone', isEqualTo: phone).limit(1).get();
    if (snapshot.docs.isNotEmpty) {
      return Customer.fromMap(
        snapshot.docs.first.data() as Map<String, dynamic>,
      );
    }
    return null;
  }

  Future<void> updateCustomer(String shopId, Customer customer) async {
    await _customers(shopId).doc(customer.id).update(customer.toMap());
  }

  Future<void> deleteCustomer(String shopId, String customerId) async {
    await _customers(shopId).doc(customerId).delete();
  }

  // ---------- SUPPLIER OPERATIONS ----------

  Future<void> insertSupplier(String shopId, Supplier supplier) async {
    await _suppliers(shopId).doc(supplier.id).set(supplier.toMap());
  }

  Future<List<Supplier>> getSuppliers(String shopId) async {
    final snapshot = await _suppliers(shopId).orderBy('name').get();
    return snapshot.docs
        .map((doc) => Supplier.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
  }

  Future<Supplier?> getSupplierByName(String shopId, String name) async {
    final snapshot =
        await _suppliers(shopId).where('name', isEqualTo: name).limit(1).get();
    if (snapshot.docs.isNotEmpty) {
      return Supplier.fromMap(
        snapshot.docs.first.data() as Map<String, dynamic>,
      );
    }
    return null;
  }

  Future<void> updateSupplier(String shopId, Supplier supplier) async {
    await _suppliers(shopId).doc(supplier.id).update(supplier.toMap());
  }

  Future<void> deleteSupplier(String shopId, String supplierId) async {
    await _suppliers(shopId).doc(supplierId).delete();
  }
}
