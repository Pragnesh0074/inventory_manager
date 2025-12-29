import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../models/shop.dart';
import '../../models/purchase.dart';
import '../../providers/shop_provider.dart';
import '../../theme/color.dart';
import '../../theme/style.dart';

class PurchasesListScreen extends StatefulWidget {
  final Shop shop;
  const PurchasesListScreen({super.key, required this.shop});

  @override
  State<PurchasesListScreen> createState() => _PurchasesListScreenState();
}

class _PurchasesListScreenState extends State<PurchasesListScreen> {
  late Future<List<Purchase>> _futurePurchases;
  Set<String> _expandedSuppliers = {}; // Track which suppliers are expanded

  @override
  void initState() {
    super.initState();
    _futurePurchases = Provider.of<ShopProvider>(
      context,
      listen: false,
    ).getPurchases(widget.shop.id);
  }

  Future<void> _refresh() async {
    setState(() {
      _futurePurchases = Provider.of<ShopProvider>(
        context,
        listen: false,
      ).getPurchases(widget.shop.id);
    });
  }

  // Toggle supplier expansion
  void _toggleSupplierExpansion(String supplier) {
    setState(() {
      if (_expandedSuppliers.contains(supplier)) {
        _expandedSuppliers.remove(supplier);
      } else {
        _expandedSuppliers.add(supplier);
      }
    });
  }

  // Group purchases by supplier
  Map<String, List<Purchase>> _groupPurchasesBySupplier(
    List<Purchase> purchases,
  ) {
    Map<String, List<Purchase>> grouped = {};

    for (var purchase in purchases) {
      String supplierKey =
          purchase.partyName.isNotEmpty
              ? purchase.partyName
              : 'Unknown Supplier';
      if (!grouped.containsKey(supplierKey)) {
        grouped[supplierKey] = [];
      }
      grouped[supplierKey]!.add(purchase);
    }

    // Sort suppliers alphabetically
    var sortedKeys = grouped.keys.toList()..sort();
    Map<String, List<Purchase>> sortedGrouped = {};
    for (var key in sortedKeys) {
      sortedGrouped[key] = grouped[key]!;
    }

    return sortedGrouped;
  }

  // Calculate supplier totals
  Map<String, Map<String, dynamic>> _calculateSupplierTotals(
    Map<String, List<Purchase>> groupedPurchases,
  ) {
    Map<String, Map<String, dynamic>> totals = {};

    groupedPurchases.forEach((supplier, purchases) {
      double totalAmount = 0;
      double totalPaid = 0;
      double totalRemaining = 0;
      int totalItems = 0;

      for (var purchase in purchases) {
        totalAmount += purchase.totalPayment;
        totalPaid += purchase.paidAmount;
        totalRemaining += purchase.remainingAmount;
        totalItems += purchase.quantity;
      }

      totals[supplier] = {
        'totalAmount': totalAmount,
        'totalPaid': totalPaid,
        'totalRemaining': totalRemaining,
        'totalItems': totalItems,
        'purchaseCount': purchases.length,
      };
    });

    return totals;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDB462),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFDB462),
        elevation: 0,
        leading: Container(
          margin: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new,
              color: Colors.black,
              size: 18.sp,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Text(
          'PURCHASES',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
        
      ),
      body: FutureBuilder<List<Purchase>>(
        future: _futurePurchases,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6C5CE7)),
              ),
            );
          }

          final purchases = snapshot.data ?? [];

          if (purchases.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80.w,
                    height: 80.w,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.shopping_bag_outlined,
                      size: 40.sp,
                      color: Colors.grey[400],
                    ),
                  ),
                  SizedBox(height: 20.h),
                  Text(
                    'No purchases yet',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Purchase records will appear here',
                    style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final groupedPurchases = _groupPurchasesBySupplier(purchases);
          final supplierTotals = _calculateSupplierTotals(groupedPurchases);

          return Column(
            children: [
              // Summary Cards
              Padding(
                padding: EdgeInsets.all(16.w),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        title: 'Total Suppliers',
                        value: groupedPurchases.length.toString(),
                        icon: Icons.business_outlined,
                        color: const Color(0xFF6C5CE7),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: _buildSummaryCard(
                        title: 'Total Purchases',
                        value: purchases.length.toString(),
                        icon: Icons.shopping_bag_outlined,
                        color: const Color(0xFFE17055),
                      ),
                    ),
                  ],
                ),
              ),

              // Purchases List
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24.r),
                      topRight: Radius.circular(24.r),
                    ),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.all(16.w),
                        child: Row(
                          children: [
                            Text(
                              'Purchase History by Supplier',
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12.w,
                                vertical: 6.h,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5E6A8),
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: Text(
                                '${groupedPurchases.length} suppliers',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: RefreshIndicator(
                          onRefresh: _refresh,
                          color: const Color(0xFF6C5CE7),
                          child: ListView.separated(
                            padding: EdgeInsets.symmetric(horizontal: 16.w),
                            itemCount: groupedPurchases.length,
                            separatorBuilder: (_, __) => SizedBox(height: 16.h),
                            itemBuilder: (context, index) {
                              final supplier = groupedPurchases.keys.elementAt(
                                index,
                              );
                              final supplierPurchases =
                                  groupedPurchases[supplier]!;
                              final totals = supplierTotals[supplier]!;

                              return _buildSupplierGroup(
                                supplier: supplier,
                                purchases: supplierPurchases,
                                totals: totals,
                              );
                            },
                          ),
                        ),
                      ),
                      SizedBox(height: 16.h),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSupplierGroup({
    required String supplier,
    required List<Purchase> purchases,
    required Map<String, dynamic> totals,
  }) {
    final isExpanded = _expandedSuppliers.contains(supplier);
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: Colors.grey.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Supplier Header (Clickable to expand/collapse)
          InkWell(
            onTap: () => _toggleSupplierExpansion(supplier),
            child: Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: const Color(0xFFFDB462).withOpacity(0.1),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20.r),
                  topRight: Radius.circular(20.r),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48.w,
                    height: 48.w,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFDB462),
                      borderRadius: BorderRadius.circular(24.r),
                    ),
                    child: Icon(Icons.business, color: Colors.white, size: 24.sp),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          supplier,
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          '${purchases.length} purchase${purchases.length > 1 ? 's' : ''} • ${totals['totalItems']} items',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${totals['totalAmount'].toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        'Total Value',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(width: 12.w),
                  // Expand/Collapse arrow
                  Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Icon(
                      isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      color: const Color(0xFFFDB462),
                      size: 20.sp,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Supplier Summary
          Container(
            padding: EdgeInsets.all(16.w),
            child: Row(
              children: [
                Expanded(
                  child: _buildSupplierSummaryItem(
                    'Paid',
                    '₹${totals['totalPaid'].toStringAsFixed(0)}',
                    const Color(0xFF00B894),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _buildSupplierSummaryItem(
                    'Due',
                    '₹${totals['totalRemaining'].toStringAsFixed(0)}',
                    const Color(0xFFE17055),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _buildSupplierSummaryItem(
                    'Purchases',
                    '${purchases.length}',
                    const Color(0xFF6C5CE7),
                  ),
                ),
              ],
            ),
          ),

          // Purchase Items (Expandable)
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: isExpanded ? null : 0,
            child: isExpanded
                ? Column(
                    children: [
                      // Header for purchase items
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.w),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        margin: EdgeInsets.symmetric(horizontal: 16.w),
                        child: Row(
                          children: [
                            Icon(
                              Icons.list_alt,
                              size: 16.sp,
                              color: Colors.grey[600],
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              'Purchase Details',
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${purchases.length} items',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 8.h),
                      // Purchase items list
                      ...purchases.map((purchase) => _buildPurchaseItem(purchase)).toList(),
                      SizedBox(height: 16.h),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildSupplierSummaryItem(String label, String value, Color color) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              color: color.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPurchaseItem(Purchase purchase) {
    final remaining = purchase.remainingAmount;
    final isCleared = remaining <= 0.0001;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.grey.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Item header
          Row(
            children: [
              Container(
                width: 36.w,
                height: 36.w,
                decoration: BoxDecoration(
                  color: const Color(0xFF6C5CE7).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(
                  Icons.inventory_2_outlined,
                  color: const Color(0xFF6C5CE7),
                  size: 18.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      purchase.itemName,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      '${purchase.quantity} items × ₹${purchase.unitPurchasePrice.toStringAsFixed(2)}',
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
                  color:
                      isCleared
                          ? const Color(0xFF00B894).withOpacity(0.1)
                          : const Color(0xFFE17055).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  isCleared ? 'Paid' : 'Due',
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
                    color:
                        isCleared
                            ? const Color(0xFF00B894)
                            : const Color(0xFFE17055),
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 12.h),

          // Purchase details
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  'Total',
                  '₹${purchase.totalPayment.toStringAsFixed(2)}',
                ),
              ),
              Expanded(
                child: _buildInfoItem(
                  'Paid',
                  '₹${purchase.paidAmount.toStringAsFixed(2)}',
                ),
              ),
              Expanded(
                child: _buildInfoItem(
                  'Remaining',
                  '₹${remaining.toStringAsFixed(2)}',
                  textColor:
                      isCleared
                          ? const Color(0xFF00B894)
                          : const Color(0xFFE17055),
                ),
              ),
            ],
          ),

          if (!isCleared) ...[
            SizedBox(height: 12.h),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _showUpdatePaidDialog(purchase),
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFF6C5CE7).withOpacity(0.1),
                  foregroundColor: const Color(0xFF6C5CE7),
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 6.h,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
                icon: Icon(Icons.payments, size: 14.sp),
                label: Text(
                  'Update Payment',
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
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
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(icon, color: color, size: 20.sp),
          ),
          SizedBox(height: 12.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            title,
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, {Color? textColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11.sp,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: textColor ?? Colors.black87,
          ),
        ),
      ],
    );
  }

  void _showUpdatePaidDialog(Purchase p) {
    final controller = TextEditingController(
      text: p.paidAmount.toStringAsFixed(2),
    );
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.r),
            ),
            title: Text(
              'Update Paid Amount',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Item: ${p.itemName}',
                  style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
                ),
                SizedBox(height: 8.h),
                Text(
                  'Total Amount: ₹${p.totalPayment.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
                ),
                SizedBox(height: 16.h),
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Paid Amount',
                    hintText: 'Max: ₹${p.totalPayment.toStringAsFixed(2)}',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide(
                        color: Colors.grey.withOpacity(0.3),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide(color: const Color(0xFF6C5CE7)),
                    ),
                    labelStyle: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  final v = double.tryParse(controller.text) ?? p.paidAmount;
                  if (v > p.totalPayment) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Paid amount (₹${v.toStringAsFixed(2)}) cannot exceed total payment amount (₹${p.totalPayment.toStringAsFixed(2)})',
                        ),
                        backgroundColor: const Color(0xFFE17055),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                    );
                    return;
                  }
                  await Provider.of<ShopProvider>(
                    context,
                    listen: false,
                  ).updatePurchasePayment(purchaseId: p.id, paidAmount: v);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Payment updated successfully'),
                      backgroundColor: const Color(0xFF00B894),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                  );
                  _refresh();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C5CE7),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
                child: Text(
                  'Save',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
    );
  }
}
