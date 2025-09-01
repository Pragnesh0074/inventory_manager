import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:inventory_manager/models/inventory_item.dart';
import 'package:inventory_manager/models/purchase.dart';
import 'package:inventory_manager/models/sale_order.dart';
import 'package:inventory_manager/database/database_helper.dart';
import 'package:inventory_manager/theme/color.dart';
import 'package:inventory_manager/theme/style.dart';

class StatisticsSummaryScreen extends StatefulWidget {
  final String shopId;
  final String shopName;

  const StatisticsSummaryScreen({
    super.key,
    required this.shopId,
    required this.shopName,
  });

  @override
  State<StatisticsSummaryScreen> createState() =>
      _StatisticsSummaryScreenState();
}

class _StatisticsSummaryScreenState extends State<StatisticsSummaryScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  List<InventoryItem> _items = [];
  List<Purchase> _purchases = [];
  List<SaleOrder> _sales = [];
  Map<String, ItemStatistics> _itemStats = {};
  bool _isLoading = true;

  // Modern color scheme matching the uploaded images
  final Color primaryYellow = const Color(0xFFFDB462);
  final Color lightYellow = const Color(0xFFF8F9FA);
  final Color darkGray = const Color(0xFF2D3436);
  final Color lightGray = const Color(0xFFF8F9FA);
  final Color cardShadowColor = const Color(0x0F000000);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Load all data
      final items = await _databaseHelper.getInventoryItems(widget.shopId);
      final purchases = await _databaseHelper.getPurchases(widget.shopId);
      final sales = await _databaseHelper.getSaleOrders(widget.shopId);

      // Load sale items for each sale order
      for (var sale in sales) {
        final saleItems = await _databaseHelper.getSaleOrderItems(sale.id);
        // Convert to SaleItem objects and create a new sale order with items
        final saleWithItems = SaleOrder(
          id: sale.id,
          shopId: sale.shopId,
          items: saleItems
              .map(
                (item) => SaleItem(
              temporaryItemName: item['item_name'],
              temporaryItemPrice: item['price']?.toDouble(),
              quantity: item['quantity'] ?? 0,
              unitPrice: item['price']?.toDouble() ?? 0.0,
            ),
          )
              .toList(),
          additionalCharges: sale.additionalCharges,
          customerName: sale.customerName,
          customerPhone: sale.customerPhone,
          dateTime: sale.dateTime,
          subtotal: sale.subtotal,
          tax: sale.tax,
          total: sale.total,
          billNumber: sale.billNumber,
          paidAmount: sale.paidAmount,
        );
        _sales.add(saleWithItems);
      }

      setState(() {
        _items = items;
        _purchases = purchases;
        _itemStats = _calculateItemStatistics();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  Map<String, ItemStatistics> _calculateItemStatistics() {
    final Map<String, ItemStatistics> stats = {};

    // Initialize stats for all items
    for (var item in _items) {
      stats[item.id] = ItemStatistics(
        itemId: item.id,
        itemName: item.name,
        currentQuantity: item.quantity,
        averagePurchasePrice: 0.0,
        totalPurchaseQuantity: 0,
        totalPurchaseAmount: 0.0,
        totalSaleQuantity: 0,
        totalSaleAmount: 0.0,
        averageSalePrice: 0.0,
        totalProfit: 0.0,
        profitMargin: 0.0,
        purchaseHistory: [],
        saleHistory: [],
      );
    }

    // Calculate purchase statistics
    for (var purchase in _purchases) {
      if (stats.containsKey(purchase.itemId)) {
        final stat = stats[purchase.itemId]!;
        stat.totalPurchaseQuantity += purchase.quantity;
        stat.totalPurchaseAmount += purchase.totalAmount;
        stat.purchaseHistory.add(purchase);
      }
    }

    // Calculate sale statistics
    for (var sale in _sales) {
      for (var saleItem in sale.items) {
        // Find the item by name since sale items might not have item IDs
        final item = _items.firstWhere(
              (item) => item.name == saleItem.itemName,
          orElse: () => InventoryItem(
            id: '',
            name: saleItem.itemName,
            price: saleItem.unitPrice,
            quantity: 0,
            createdDate: DateTime.now(),
          ),
        );

        if (item.id.isNotEmpty && stats.containsKey(item.id)) {
          final stat = stats[item.id]!;
          stat.totalSaleQuantity += saleItem.quantity;
          stat.totalSaleAmount += saleItem.totalPrice;
          stat.saleHistory.add(
            SaleRecord(
              date: sale.dateTime,
              quantity: saleItem.quantity,
              price: saleItem.unitPrice,
              total: saleItem.totalPrice,
              billNumber: sale.billNumber,
            ),
          );
        }
      }
    }

    // Calculate averages and profits
    for (var stat in stats.values) {
      if (stat.totalPurchaseQuantity > 0) {
        stat.averagePurchasePrice =
            stat.totalPurchaseAmount / stat.totalPurchaseQuantity;
      }

      if (stat.totalSaleQuantity > 0) {
        stat.averageSalePrice = stat.totalSaleAmount / stat.totalSaleQuantity;
      }

      // Calculate profit (sale amount - purchase cost for sold items)
      final soldPurchaseCost =
          stat.averagePurchasePrice * stat.totalSaleQuantity;
      stat.totalProfit = stat.totalSaleAmount - soldPurchaseCost;

      if (stat.totalSaleAmount > 0) {
        stat.profitMargin = (stat.totalProfit / stat.totalSaleAmount) * 100;
      }
    }

    return stats;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightYellow,
      appBar: AppBar(
        title: Text(
          'Statistics Summary',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: darkGray,
          ),
        ),
        backgroundColor: primaryYellow,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: darkGray),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Container(
            margin: EdgeInsets.only(right: 16.w),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: IconButton(
              icon: Icon(Icons.refresh, color: darkGray, size: 20.w),
              onPressed: _loadData,
            ),
          ),
        ],
      ),
      body: _isLoading
          ? Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(darkGray),
        ),
      )
          : Column(
        children: [
          Container(
            color: primaryYellow,
            child: TabBar(
              controller: _tabController,
              labelColor: darkGray,
              unselectedLabelColor: darkGray.withOpacity(0.6),
              indicatorColor: darkGray,
              indicatorWeight: 3.0,
              labelStyle: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w400,
              ),
              tabs: const [
                Tab(text: 'Overview'),
                Tab(text: 'Item Details'),
                Tab(text: 'Charts'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildItemDetailsTab(),
                _buildChartsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    final totalItems = _items.length;
    final totalPurchaseValue = _purchases.fold<double>(
      0.0,
          (sum, purchase) => sum + purchase.totalAmount,
    );
    final totalSaleValue = _sales.fold<double>(
      0.0,
          (sum, sale) => sum + sale.total,
    );
    final totalProfit = _itemStats.values.fold<double>(
      0.0,
          (sum, stat) => sum + stat.totalProfit,
    );

    return SingleChildScrollView(
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top stats cards in a grid
          Row(
            children: [
              Expanded(
                child: _buildModernSummaryCard(
                  title: 'Total Items',
                  value: totalItems.toString(),
                  icon: Icons.inventory_2_outlined,
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF667EEA),
                      const Color(0xFF764BA2),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildModernSummaryCard(
                  title: 'Total Purchase',
                  value: '₹${_formatCurrency(totalPurchaseValue)}',
                  icon: Icons.shopping_cart_outlined,
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFFF9A8B),
                      const Color(0xFFFECADA),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: _buildModernSummaryCard(
                  title: 'Total Sales',
                  value: '₹${_formatCurrency(totalSaleValue)}',
                  icon: Icons.trending_up_outlined,
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF56CCF2),
                      const Color(0xFF2F80ED),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildModernSummaryCard(
                  title: 'Net Profit',
                  value: '₹${_formatCurrency(totalProfit)}',
                  icon: totalProfit >= 0
                      ? Icons.arrow_upward_outlined
                      : Icons.arrow_downward_outlined,
                  gradient: LinearGradient(
                    colors: totalProfit >= 0
                        ? [
                      const Color(0xFF56FFA4),
                      const Color(0xFF59BC86),
                    ]
                        : [
                      const Color(0xFFFF6B6B),
                      const Color(0xFFEE5A52),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 32.h),

          // Top performing items section
          Text(
            'Top Performing Items',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              color: darkGray,
            ),
          ),
          SizedBox(height: 16.h),
          _buildTopItemsList(),
        ],
      ),
    );
  }

  Widget _buildModernSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Gradient gradient,
  }) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: cardShadowColor,
            spreadRadius: 0,
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 20.w,
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            title,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopItemsList() {
    final topItems = _itemStats.values.toList()
      ..sort((a, b) => b.totalProfit.compareTo(a.totalProfit));

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: cardShadowColor,
            spreadRadius: 0,
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: topItems.take(5).map((item) {
          final isPositive = item.totalProfit >= 0;
          return Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: lightGray,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40.w,
                  height: 40.w,
                  decoration: BoxDecoration(
                    color: isPositive
                        ? const Color(0xFF56FFA4).withOpacity(0.1)
                        : const Color(0xFFFF6B6B).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(
                    isPositive ? Icons.trending_up : Icons.trending_down,
                    color: isPositive
                        ? const Color(0xFF56FFA4)
                        : const Color(0xFFFF6B6B),
                    size: 20.w,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.itemName,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: darkGray,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        'Profit: ₹${_formatCurrency(item.totalProfit)}',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: isPositive
                        ? const Color(0xFF56FFA4).withOpacity(0.1)
                        : const Color(0xFFFF6B6B).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    '${item.profitMargin.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: isPositive
                          ? const Color(0xFF56FFA4)
                          : const Color(0xFFFF6B6B),
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildItemDetailsTab() {
    return ListView.builder(
      padding: EdgeInsets.all(20.w),
      itemCount: _itemStats.length,
      itemBuilder: (context, index) {
        final itemId = _itemStats.keys.elementAt(index);
        final stat = _itemStats[itemId]!;

        return Container(
          margin: EdgeInsets.only(bottom: 16.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: cardShadowColor,
                spreadRadius: 0,
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ExpansionTile(
            shape: const Border(),
            collapsedShape: const Border(),
            tilePadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            childrenPadding: EdgeInsets.all(16.w),
            leading: Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                color: primaryYellow.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(
                Icons.inventory_2_outlined,
                color: darkGray,
                size: 20.w,
              ),
            ),
            title: Text(
              stat.itemName,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14.sp,
                color: darkGray,
              ),
            ),
            subtitle: Text(
              'Stock: ${stat.currentQuantity} pcs',
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.grey[600],
              ),
            ),
            children: [
              _buildDetailedStats(stat),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailedStats(ItemStatistics stat) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Stats grid
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: lightGray,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      'Avg Purchase',
                      '₹${stat.averagePurchasePrice.toStringAsFixed(2)}',
                      Icons.shopping_cart_outlined,
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      'Avg Sale',
                      '₹${stat.averageSalePrice.toStringAsFixed(2)}',
                      Icons.point_of_sale_outlined,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      'Total Purchase',
                      '${stat.totalPurchaseQuantity} pcs',
                      Icons.input_outlined,
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      'Total Sale',
                      '${stat.totalSaleQuantity} pcs',
                      Icons.output_outlined,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      'Total Profit',
                      '₹${_formatCurrency(stat.totalProfit)}',
                      stat.totalProfit >= 0
                          ? Icons.trending_up_outlined
                          : Icons.trending_down_outlined,
                      valueColor: stat.totalProfit >= 0
                          ? const Color(0xFF56FFA4)
                          : const Color(0xFFFF6B6B),
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      'Profit Margin',
                      '${stat.profitMargin.toStringAsFixed(1)}%',
                      Icons.percent_outlined,
                      valueColor: stat.profitMargin >= 0
                          ? const Color(0xFF56FFA4)
                          : const Color(0xFFFF6B6B),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        SizedBox(height: 20.h),

        // Recent sales and purchases
        Text(
          'Recent Activity',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: darkGray,
          ),
        ),
        SizedBox(height: 12.h),
        _buildActivityTabs(stat),
      ],
    );
  }

  Widget _buildStatItem(
      String label,
      String value,
      IconData icon, {
        Color? valueColor,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 16.w,
              color: Colors.grey[600],
            ),
            SizedBox(width: 4.w),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.sp,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        SizedBox(height: 4.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w700,
            color: valueColor ?? darkGray,
          ),
        ),
      ],
    );
  }

  Widget _buildActivityTabs(ItemStatistics stat) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: lightGray,
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: TabBar(
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                color: primaryYellow,
                borderRadius: BorderRadius.circular(8.r),
              ),
              labelColor: darkGray,
              unselectedLabelColor: Colors.grey[600],
              dividerColor: Colors.transparent,
              labelStyle: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
              ),
              tabs: const [
                Tab(text: 'Sales'),
                Tab(text: 'Purchases'),
              ],
            ),
          ),
          SizedBox(height: 12.h),
          SizedBox(
            height: 200.h,
            child: TabBarView(
              children: [
                _buildSalesHistory(stat.saleHistory),
                _buildPurchaseHistory(stat.purchaseHistory),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSalesHistory(List<SaleRecord> sales) {
    if (sales.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_outlined,
              size: 40.w,
              color: Colors.grey[400],
            ),
            SizedBox(height: 8.h),
            Text(
              'No sales recorded',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12.sp,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: sales.take(5).length,
      itemBuilder: (context, index) {
        final sale = sales[index];
        return Container(
          margin: EdgeInsets.only(bottom: 8.h),
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(color: lightGray),
          ),
          child: Row(
            children: [
              Container(
                width: 32.w,
                height: 32.w,
                decoration: BoxDecoration(
                  color: const Color(0xFF56FFA4).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  Icons.receipt_outlined,
                  size: 16.w,
                  color: const Color(0xFF56FFA4),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bill: ${sale.billNumber}',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: darkGray,
                      ),
                    ),
                    Text(
                      '${sale.quantity} × ₹${sale.price.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '₹${sale.total.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF56FFA4),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPurchaseHistory(List<Purchase> purchases) {
    if (purchases.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 40.w,
              color: Colors.grey[400],
            ),
            SizedBox(height: 8.h),
            Text(
              'No purchases recorded',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12.sp,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: purchases.take(5).length,
      itemBuilder: (context, index) {
        final purchase = purchases[index];
        return Container(
          margin: EdgeInsets.only(bottom: 8.h),
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(color: lightGray),
          ),
          child: Row(
            children: [
              Container(
                width: 32.w,
                height: 32.w,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF9A8B).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  Icons.shopping_cart_outlined,
                  size: 16.w,
                  color: const Color(0xFFFF9A8B),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      purchase.partyName,
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: darkGray,
                      ),
                    ),
                    Text(
                      '${purchase.quantity} × ₹${purchase.unitPurchasePrice.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '₹${purchase.totalAmount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFFF9A8B),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChartsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profit/Loss Chart
          _buildChartSection(
            title: 'Profit/Loss by Item',
            child: _buildProfitLossChart(),
            legendItems: [
              LegendItem(color: const Color(0xFF56FFA4), label: 'Profit'),
              LegendItem(color: const Color(0xFFFF6B6B), label: 'Loss'),
            ],
          ),

          SizedBox(height: 32.h),

          // Sales vs Purchase Chart
          _buildChartSection(
            title: 'Sales vs Purchase Comparison',
            child: _buildSalesVsPurchaseChart(),
            legendItems: [
              LegendItem(color: const Color(0xFFFF9A8B), label: 'Purchase Amount'),
              LegendItem(color: const Color(0xFF56CCF2), label: 'Sale Amount'),
            ],
          ),

          SizedBox(height: 32.h),

          // Monthly Trend Chart
          _buildChartSection(
            title: 'Monthly Sales Trend',
            child: _buildMonthlyTrendChart(),
            legendItems: [
              LegendItem(color: const Color(0xFF667EEA), label: 'Monthly Sales'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChartSection({
    required String title,
    required Widget child,
    required List<LegendItem> legendItems,
  }) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: cardShadowColor,
            spreadRadius: 0,
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: darkGray,
            ),
          ),
          SizedBox(height: 12.h),
          _buildModernChartLegend(legendItems),
          SizedBox(height: 20.h),
          SizedBox(height: 250.h, child: child),
        ],
      ),
    );
  }

  Widget _buildProfitLossChart() {
    final items = _itemStats.values.toList();
    if (items.isEmpty) return _buildEmptyChart();

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: items.fold<double>(
          0.0,
              (max, item) =>
          item.totalProfit.abs() > max ? item.totalProfit.abs() : max,
        ),
        minY: items.fold<double>(
          0.0,
              (min, item) => item.totalProfit < min ? item.totalProfit : min,
        ),
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            tooltipBgColor: darkGray.withOpacity(0.9),
            tooltipRoundedRadius: 8.r,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final item = items[group.x.toInt()];
              return BarTooltipItem(
                '${item.itemName}\n₹${item.totalProfit.toStringAsFixed(2)}',
                TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 12.sp,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() < items.length) {
                  final item = items[value.toInt()];
                  return Padding(
                    padding: EdgeInsets.only(top: 8.h),
                    child: Text(
                      item.itemName.length > 6
                          ? '${item.itemName.substring(0, 6)}...'
                          : item.itemName,
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 50.w,
              getTitlesWidget: (value, meta) {
                return Text(
                  '₹${_formatCurrency(value)}',
                  style: TextStyle(
                    fontSize: 9.sp,
                    color: Colors.grey[600],
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: null,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey[200]!,
              strokeWidth: 1,
            );
          },
        ),
        barGroups: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: item.totalProfit,
                color: item.totalProfit >= 0
                    ? const Color(0xFF56FFA4)
                    : const Color(0xFFFF6B6B),
                width: 16.w,
                borderRadius: BorderRadius.circular(4.r),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSalesVsPurchaseChart() {
    final items = _itemStats.values.toList();
    if (items.isEmpty) return _buildEmptyChart();

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: items.fold<double>(
          0.0,
              (max, item) => [item.totalSaleAmount, item.totalPurchaseAmount, max]
              .reduce((a, b) => a > b ? a : b),
        ),
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            tooltipBgColor: darkGray.withOpacity(0.9),
            tooltipRoundedRadius: 8.r,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final item = items[group.x.toInt()];
              final isPurchase = rodIndex == 0;
              return BarTooltipItem(
                '${item.itemName}\n${isPurchase ? 'Purchase' : 'Sale'}: ₹${isPurchase ? item.totalPurchaseAmount.toStringAsFixed(2) : item.totalSaleAmount.toStringAsFixed(2)}',
                TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 12.sp,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() < items.length) {
                  final item = items[value.toInt()];
                  return Padding(
                    padding: EdgeInsets.only(top: 8.h),
                    child: Text(
                      item.itemName.length > 6
                          ? '${item.itemName.substring(0, 6)}...'
                          : item.itemName,
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 50.w,
              getTitlesWidget: (value, meta) {
                return Text(
                  '₹${_formatCurrency(value)}',
                  style: TextStyle(
                    fontSize: 9.sp,
                    color: Colors.grey[600],
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey[200]!,
              strokeWidth: 1,
            );
          },
        ),
        barGroups: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: item.totalPurchaseAmount,
                color: const Color(0xFFFF9A8B),
                width: 12.w,
                borderRadius: BorderRadius.circular(4.r),
              ),
              BarChartRodData(
                toY: item.totalSaleAmount,
                color: const Color(0xFF56CCF2),
                width: 12.w,
                borderRadius: BorderRadius.circular(4.r),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMonthlyTrendChart() {
    // Group sales by month
    final Map<String, double> monthlySales = {};
    for (var sale in _sales) {
      final monthKey =
          '${sale.dateTime.year}-${sale.dateTime.month.toString().padLeft(2, '0')}';
      monthlySales[monthKey] = (monthlySales[monthKey] ?? 0.0) + sale.total;
    }

    final sortedMonths = monthlySales.keys.toList()..sort();

    if (sortedMonths.isEmpty) return _buildEmptyChart();

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey[200]!,
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() < sortedMonths.length) {
                  final month = sortedMonths[value.toInt()];
                  return Padding(
                    padding: EdgeInsets.only(top: 8.h),
                    child: Text(
                      month.substring(5), // Show only month
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 50.w,
              getTitlesWidget: (value, meta) {
                return Text(
                  '₹${_formatCurrency(value)}',
                  style: TextStyle(
                    fontSize: 9.sp,
                    color: Colors.grey[600],
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey[200]!),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: sortedMonths.asMap().entries.map((entry) {
              final index = entry.key;
              final month = entry.value;
              return FlSpot(index.toDouble(), monthlySales[month]!);
            }).toList(),
            isCurved: true,
            gradient: LinearGradient(
              colors: [
                const Color(0xFF667EEA),
                const Color(0xFF764BA2),
              ],
            ),
            barWidth: 3.w,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4.w,
                  color: Colors.white,
                  strokeWidth: 2.w,
                  strokeColor: const Color(0xFF667EEA),
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF667EEA).withOpacity(0.1),
                  Colors.transparent,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyChart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bar_chart_outlined,
            size: 48.w,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16.h),
          Text(
            'No data available',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernChartLegend(List<LegendItem> items) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: lightGray,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: items
            .map(
              (item) => Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.w),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12.w,
                  height: 12.w,
                  decoration: BoxDecoration(
                    color: item.color,
                    borderRadius: BorderRadius.circular(3.r),
                  ),
                ),
                SizedBox(width: 6.w),
                Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: darkGray,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        )
            .toList(),
      ),
    );
  }

  String _formatCurrency(double value) {
    if (value >= 100000) {
      return '${(value / 100000).toStringAsFixed(1)}L';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    } else {
      return value.toStringAsFixed(0);
    }
  }
}

// Keep existing classes unchanged
class ItemStatistics {
  final String itemId;
  final String itemName;
  final int currentQuantity;
  double averagePurchasePrice;
  int totalPurchaseQuantity;
  double totalPurchaseAmount;
  int totalSaleQuantity;
  double totalSaleAmount;
  double averageSalePrice;
  double totalProfit;
  double profitMargin;
  final List<Purchase> purchaseHistory;
  final List<SaleRecord> saleHistory;

  ItemStatistics({
    required this.itemId,
    required this.itemName,
    required this.currentQuantity,
    required this.averagePurchasePrice,
    required this.totalPurchaseQuantity,
    required this.totalPurchaseAmount,
    required this.totalSaleQuantity,
    required this.totalSaleAmount,
    required this.averageSalePrice,
    required this.totalProfit,
    required this.profitMargin,
    required this.purchaseHistory,
    required this.saleHistory,
  });
}

class SaleRecord {
  final DateTime date;
  final int quantity;
  final double price;
  final double total;
  final String billNumber;

  SaleRecord({
    required this.date,
    required this.quantity,
    required this.price,
    required this.total,
    required this.billNumber,
  });
}

class LegendItem {
  final Color color;
  final String label;

  LegendItem({required this.color, required this.label});
}