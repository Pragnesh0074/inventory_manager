import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../models/shop.dart';
import '../../models/sale_order.dart';
import '../../providers/shop_provider.dart';

class SalesPaymentsListScreen extends StatefulWidget {
  final Shop shop;
  const SalesPaymentsListScreen({super.key, required this.shop});

  @override
  State<SalesPaymentsListScreen> createState() =>
      _SalesPaymentsListScreenState();
}

class _SalesPaymentsListScreenState extends State<SalesPaymentsListScreen> {
  late Future<List<SaleOrder>> _futureOrders;

  @override
  void initState() {
    super.initState();
    _futureOrders = Provider.of<ShopProvider>(
      context,
      listen: false,
    ).getSaleOrdersFromDb(widget.shop.id);
  }

  Future<void> _refresh() async {
    setState(() {
      _futureOrders = Provider.of<ShopProvider>(
        context,
        listen: false,
      ).getSaleOrdersFromDb(widget.shop.id);
    });
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
          'SALES PAYMENTS',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(24.r)),
        ),
      ),
      body: FutureBuilder<List<SaleOrder>>(
        future: _futureOrders,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6C5CE7)),
              ),
            );
          }

          final orders = snapshot.data ?? [];

          if (orders.isEmpty) {
            return Container(
              color: Colors.white,
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(40.w),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Decorative circles in background
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          // Outer circle
                          Container(
                            width: 200.w,
                            height: 200.w,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.grey.withOpacity(0.1),
                            ),
                          ),
                          // Middle circle
                          Container(
                            width: 150.w,
                            height: 150.w,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.grey.withOpacity(0.15),
                            ),
                          ),
                          // Icon container
                          Container(
                            width: 100.w,
                            height: 100.w,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white,
                                  Colors.white.withOpacity(0.9),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 30,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.payments_outlined,
                              size: 50.sp,
                              color: const Color(0xFFFDB462),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 40.h),
                      Text(
                        'No Payment Records',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(height: 12.h),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 32.w),
                        child: Text(
                          'Payment records will appear here once you complete sales',
                          style: TextStyle(
                            fontSize: 16.sp,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w400,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      SizedBox(height: 32.h),
                      // Decorative element
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildFeatureItem(
                            Icons.account_balance_wallet,
                            'Track',
                          ),
                          SizedBox(width: 24.w),
                          _buildFeatureItem(Icons.history, 'History'),
                          SizedBox(width: 24.w),
                          _buildFeatureItem(Icons.insights, 'Insights'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          return Column(
            children: [
              // Summary Cards
              Padding(
                padding: EdgeInsets.all(16.w),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        title: 'Total Orders',
                        value: orders.length.toString(),
                        icon: Icons.receipt_long,
                        color: const Color(0xFF6C5CE7),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: _buildSummaryCard(
                        title: 'Pending Amount',
                        value: '₹${_calculatePendingAmount(orders)}',
                        icon: Icons.schedule,
                        color: const Color(0xFFE17055),
                      ),
                    ),
                  ],
                ),
              ),

              // Sales Payments List
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
                              'Payment Records',
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
                                '${orders.length} orders',
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
                            itemCount: orders.length,
                            separatorBuilder: (_, __) => SizedBox(height: 12.h),
                            itemBuilder: (context, index) {
                              final o = orders[index];
                              return _buildOrderCard(o);
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

  String _calculatePendingAmount(List<SaleOrder> orders) {
    double total = 0;
    for (var order in orders) {
      total += order.remainingAmount;
    }
    return total.toStringAsFixed(0);
  }

  Widget _buildOrderCard(SaleOrder o) {
    final remaining = o.remainingAmount;
    final isCleared = remaining <= 0.0001;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.grey.withOpacity(0.2), width: 1),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.all(16.w),
          childrenPadding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.w),
          backgroundColor: Colors.white,
          collapsedBackgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          collapsedShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          leading: Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              color: const Color(0xFF6C5CE7).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              Icons.receipt_outlined,
              color: const Color(0xFF6C5CE7),
              size: 20.sp,
            ),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                o.customerName.isNotEmpty ? o.customerName : 'Walk-in Customer',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                'Bill #${o.billNumber} • ${o.formattedDate}',
                style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
              ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color:
                      isCleared
                          ? const Color(0xFF00B894).withOpacity(0.1)
                          : const Color(0xFFE17055).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  isCleared ? 'Paid' : 'Due',
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color:
                        isCleared
                            ? const Color(0xFF00B894)
                            : const Color(0xFFE17055),
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Icon(
                Icons.keyboard_arrow_down,
                color: Colors.grey[600],
                size: 20.sp,
              ),
            ],
          ),
          children: [
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoItem(
                          'Total',
                          '₹${o.total.toStringAsFixed(2)}',
                        ),
                      ),
                      Expanded(
                        child: _buildInfoItem(
                          'Paid',
                          '₹${o.paidAmount.toStringAsFixed(2)}',
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
                ],
              ),
            ),

            SizedBox(height: 16.h),

            // Items section
            FutureBuilder<List<Map<String, dynamic>>>(
              future: Provider.of<ShopProvider>(
                context,
                listen: false,
              ).getSaleOrderItems(o.id),
              builder: (context, snap) {
                final items = snap.data ?? [];
                if (items.isEmpty) {
                  return Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      'No item details available',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.list_alt,
                          size: 16.sp,
                          color: Colors.grey[600],
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          'Items (${items.length})',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Column(
                        children:
                            items.asMap().entries.map((entry) {
                              final index = entry.key;
                              final m = entry.value;
                              return Container(
                                padding: EdgeInsets.all(12.w),
                                decoration: BoxDecoration(
                                  border:
                                      index < items.length - 1
                                          ? Border(
                                            bottom: BorderSide(
                                              color: Colors.grey.withOpacity(
                                                0.2,
                                              ),
                                            ),
                                          )
                                          : null,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        m['item_name'] as String,
                                        style: TextStyle(
                                          fontSize: 13.sp,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 6.w,
                                        vertical: 2.h,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFF6C5CE7,
                                        ).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(
                                          4.r,
                                        ),
                                      ),
                                      child: Text(
                                        '×${m['quantity']}',
                                        style: TextStyle(
                                          fontSize: 10.sp,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF6C5CE7),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 12.w),
                                    Text(
                                      '₹${(m['total_amount'] as num).toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontSize: 13.sp,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF00B894),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                      ),
                    ),
                  ],
                );
              },
            ),

            if (!isCleared) ...[
              SizedBox(height: 16.h),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => _showUpdatePaymentDialog(o),
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFF6C5CE7).withOpacity(0.1),
                    foregroundColor: const Color(0xFF6C5CE7),
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 8.h,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                  icon: Icon(Icons.payments, size: 16.sp),
                  label: Text(
                    'Update Payment',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
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

  void _showUpdatePaymentDialog(SaleOrder o) {
    final controller = TextEditingController(
      text: o.paidAmount.toStringAsFixed(2),
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
              'Update Payment',
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
                  'Customer: ${o.customerName.isNotEmpty ? o.customerName : 'Walk-in Customer'}',
                  style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Bill #${o.billNumber}',
                  style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
                ),
                SizedBox(height: 8.h),
                Text(
                  'Total Amount: ₹${o.total.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
                ),
                SizedBox(height: 16.h),
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Paid Amount',
                    hintText: 'Max: ₹${o.total.toStringAsFixed(2)}',
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
                  final v = double.tryParse(controller.text) ?? o.paidAmount;
                  if (v > o.total) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Paid amount (₹${v.toStringAsFixed(2)}) cannot exceed total amount (₹${o.total.toStringAsFixed(2)})',
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
                  ).updateSaleOrderPayment(orderId: o.id, paidAmount: v);
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

  Widget _buildFeatureItem(IconData icon, String label) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: const Color(0xFFFDB462).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Icon(icon, size: 20.sp, color: const Color(0xFFFDB462)),
        ),
        SizedBox(height: 8.h),
        Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
