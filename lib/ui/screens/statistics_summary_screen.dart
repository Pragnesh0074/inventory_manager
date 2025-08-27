import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:inventory_manager/providers/shop_provider.dart';
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
          items:
              saleItems
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
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
          orElse:
              () => InventoryItem(
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
      appBar: AppBar(
        title: Text('Statistics Summary - ${widget.shopName}'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  Container(
                    color: AppColors.primaryBlue,
                    child: TabBar(
                      controller: _tabController,
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white70,
                      indicatorColor: Colors.white,
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
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCard(
            title: 'Total Items',
            value: totalItems.toString(),
            icon: Icons.inventory,
            color: Colors.blue,
          ),
          SizedBox(height: 16.h),
          _buildSummaryCard(
            title: 'Total Purchase Value',
            value: '₹${totalPurchaseValue.toStringAsFixed(2)}',
            icon: Icons.shopping_cart,
            color: Colors.orange,
          ),
          SizedBox(height: 16.h),
          _buildSummaryCard(
            title: 'Total Sale Value',
            value: '₹${totalSaleValue.toStringAsFixed(2)}',
            icon: Icons.point_of_sale,
            color: Colors.green,
          ),
          SizedBox(height: 16.h),
          _buildSummaryCard(
            title: 'Total Profit',
            value: '₹${totalProfit.toStringAsFixed(2)}',
            icon: Icons.trending_up,
            color: totalProfit >= 0 ? Colors.green : Colors.red,
          ),
          SizedBox(height: 24.h),
          Text('Top Performing Items', style: AppTextStyles.headingMedium),
          SizedBox(height: 16.h),
          _buildTopItemsList(),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(icon, color: color, size: 24.w),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
                ),
                SizedBox(height: 4.h),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopItemsList() {
    final topItems =
        _itemStats.values.toList()
          ..sort((a, b) => b.totalProfit.compareTo(a.totalProfit));

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: topItems.take(5).length,
      itemBuilder: (context, index) {
        final item = topItems[index];
        return Card(
          margin: EdgeInsets.only(bottom: 8.h),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor:
                  item.totalProfit >= 0 ? Colors.green : Colors.red,
              child: Icon(
                item.totalProfit >= 0 ? Icons.trending_up : Icons.trending_down,
                color: Colors.white,
                size: 20.w,
              ),
            ),
            title: Text(
              item.itemName,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('Profit: ₹${item.totalProfit.toStringAsFixed(2)}'),
            trailing: Text(
              '${item.profitMargin.toStringAsFixed(1)}%',
              style: TextStyle(
                color: item.profitMargin >= 0 ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildItemDetailsTab() {
    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: _itemStats.length,
      itemBuilder: (context, index) {
        final itemId = _itemStats.keys.elementAt(index);
        final stat = _itemStats[itemId]!;

        return Card(
          margin: EdgeInsets.only(bottom: 16.h),
          child: ExpansionTile(
            title: Text(
              stat.itemName,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('Current Stock: ${stat.currentQuantity}'),
            children: [
              Padding(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatRow(
                      'Average Purchase Price',
                      '₹${stat.averagePurchasePrice.toStringAsFixed(2)}',
                    ),
                    _buildStatRow(
                      'Total Purchase Quantity',
                      stat.totalPurchaseQuantity.toString(),
                    ),
                    _buildStatRow(
                      'Total Purchase Amount',
                      '₹${stat.totalPurchaseAmount.toStringAsFixed(2)}',
                    ),
                    _buildStatRow(
                      'Average Sale Price',
                      '₹${stat.averageSalePrice.toStringAsFixed(2)}',
                    ),
                    _buildStatRow(
                      'Total Sale Quantity',
                      stat.totalSaleQuantity.toString(),
                    ),
                    _buildStatRow(
                      'Total Sale Amount',
                      '₹${stat.totalSaleAmount.toStringAsFixed(2)}',
                    ),
                    _buildStatRow(
                      'Total Profit/Loss',
                      '₹${stat.totalProfit.toStringAsFixed(2)}',
                      stat.totalProfit >= 0 ? Colors.green : Colors.red,
                    ),
                    _buildStatRow(
                      'Profit Margin',
                      '${stat.profitMargin.toStringAsFixed(1)}%',
                      stat.profitMargin >= 0 ? Colors.green : Colors.red,
                    ),

                    SizedBox(height: 16.h),
                    Text('Recent Sales', style: AppTextStyles.headingMedium),
                    SizedBox(height: 8.h),
                    _buildSalesHistory(stat.saleHistory),

                    SizedBox(height: 16.h),
                    Text(
                      'Purchase History',
                      style: AppTextStyles.headingMedium,
                    ),
                    SizedBox(height: 8.h),
                    _buildPurchaseHistory(stat.purchaseHistory),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatRow(String label, String value, [Color? valueColor]) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14.sp)),
          Text(
            value,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSalesHistory(List<SaleRecord> sales) {
    if (sales.isEmpty) {
      return Text('No sales recorded', style: TextStyle(color: Colors.grey));
    }

    return Column(
      children:
          sales
              .take(5)
              .map(
                (sale) => Card(
                  child: ListTile(
                    title: Text('Bill: ${sale.billNumber}'),
                    subtitle: Text(
                      '${sale.quantity} × ₹${sale.price.toStringAsFixed(2)}',
                    ),
                    trailing: Text(
                      '₹${sale.total.toStringAsFixed(2)}',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              )
              .toList(),
    );
  }

  Widget _buildPurchaseHistory(List<Purchase> purchases) {
    if (purchases.isEmpty) {
      return Text(
        'No purchases recorded',
        style: TextStyle(color: Colors.grey),
      );
    }

    return Column(
      children:
          purchases
              .take(5)
              .map(
                (purchase) => Card(
                  child: ListTile(
                    title: Text(purchase.partyName),
                    subtitle: Text(
                      '${purchase.quantity} × ₹${purchase.unitPurchasePrice.toStringAsFixed(2)}',
                    ),
                    trailing: Text(
                      '₹${purchase.totalAmount.toStringAsFixed(2)}',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              )
              .toList(),
    );
  }

  Widget _buildChartsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Profit/Loss by Item', style: AppTextStyles.headingMedium),
          SizedBox(height: 16.h),
          SizedBox(height: 300.h, child: _buildProfitLossChart()),

          SizedBox(height: 32.h),
          Text(
            'Sales vs Purchase Comparison',
            style: AppTextStyles.headingMedium,
          ),
          SizedBox(height: 16.h),
          SizedBox(height: 300.h, child: _buildSalesVsPurchaseChart()),

          SizedBox(height: 32.h),
          Text('Monthly Sales Trend', style: AppTextStyles.headingMedium),
          SizedBox(height: 16.h),
          SizedBox(height: 300.h, child: _buildMonthlyTrendChart()),
        ],
      ),
    );
  }

  Widget _buildProfitLossChart() {
    final profitableItems =
        _itemStats.values.where((item) => item.totalProfit > 0).toList();
    final lossItems =
        _itemStats.values.where((item) => item.totalProfit < 0).toList();

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: _itemStats.values.fold<double>(
          0.0,
          (max, item) =>
              item.totalProfit.abs() > max ? item.totalProfit.abs() : max,
        ),
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() < _itemStats.length) {
                  final item = _itemStats.values.elementAt(value.toInt());
                  return Padding(
                    padding: EdgeInsets.only(top: 8.h),
                    child: Text(
                      item.itemName.length > 8
                          ? '${item.itemName.substring(0, 8)}...'
                          : item.itemName,
                      style: TextStyle(fontSize: 10.sp),
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
              reservedSize: 60.w,
              getTitlesWidget: (value, meta) {
                return Text(
                  '₹${value.toInt()}',
                  style: TextStyle(fontSize: 10.sp),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups:
            _itemStats.values.toList().asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return BarChartGroupData(
                x: index,
                barRods: [
                  BarChartRodData(
                    toY: item.totalProfit,
                    color: item.totalProfit >= 0 ? Colors.green : Colors.red,
                    width: 20.w,
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

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: items.fold<double>(
          0.0,
          (max, item) =>
              (item.totalSaleAmount > max ? item.totalSaleAmount : max) >
                      (item.totalPurchaseAmount > max
                          ? item.totalPurchaseAmount
                          : max)
                  ? (item.totalSaleAmount > max ? item.totalSaleAmount : max)
                  : (item.totalPurchaseAmount > max
                      ? item.totalPurchaseAmount
                      : max),
        ),
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() < items.length) {
                  final item = items[value.toInt()];
                  return Padding(
                    padding: EdgeInsets.only(top: 8.h),
                    child: Text(
                      item.itemName.length > 8
                          ? '${item.itemName.substring(0, 8)}...'
                          : item.itemName,
                      style: TextStyle(fontSize: 10.sp),
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
              reservedSize: 60.w,
              getTitlesWidget: (value, meta) {
                return Text(
                  '₹${value.toInt()}',
                  style: TextStyle(fontSize: 10.sp),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups:
            items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return BarChartGroupData(
                x: index,
                barRods: [
                  BarChartRodData(
                    toY: item.totalPurchaseAmount,
                    color: Colors.orange,
                    width: 15.w,
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                  BarChartRodData(
                    toY: item.totalSaleAmount,
                    color: Colors.green,
                    width: 15.w,
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

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: true),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
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
                      style: TextStyle(fontSize: 10.sp),
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
              reservedSize: 60.w,
              getTitlesWidget: (value, meta) {
                return Text(
                  '₹${value.toInt()}',
                  style: TextStyle(fontSize: 10.sp),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: true),
        lineBarsData: [
          LineChartBarData(
            spots:
                sortedMonths.asMap().entries.map((entry) {
                  final index = entry.key;
                  final month = entry.value;
                  return FlSpot(index.toDouble(), monthlySales[month]!);
                }).toList(),
            isCurved: true,
            color: AppColors.primaryBlue,
            barWidth: 3.w,
            dotData: FlDotData(show: true),
          ),
        ],
      ),
    );
  }
}

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
