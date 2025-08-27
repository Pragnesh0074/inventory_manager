import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../models/shop.dart';
import '../../models/sale_order.dart';
import '../../providers/shop_provider.dart';
import '../../theme/color.dart';
import '../../theme/style.dart';

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
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          '${widget.shop.name} - Sales Payments',
          style: AppTextStyles.appBarTitle,
        ),
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(16.r),
              bottomRight: Radius.circular(16.r),
            ),
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: AppColors.textOnPrimary,
            size: 20.sp,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<List<SaleOrder>>(
        future: _futureOrders,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          final orders = snapshot.data ?? [];
          if (orders.isEmpty) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(24.w),
                child: Text('No sales yet', style: AppTextStyles.bodyLarge),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              padding: EdgeInsets.all(16.w),
              itemCount: orders.length,
              separatorBuilder: (_, __) => SizedBox(height: 12.h),
              itemBuilder: (context, index) {
                final o = orders[index];
                return _buildOrderCard(o);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildOrderCard(SaleOrder o) {
    final remaining = o.remainingAmount;
    final isCleared = remaining <= 0.0001;
    return ExpansionTile(
      tilePadding: EdgeInsets.symmetric(horizontal: 12.w),
      collapsedBackgroundColor: AppColors.cardBackground,
      backgroundColor: AppColors.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      collapsedShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(o.customerName, style: AppTextStyles.cardTitle),
                SizedBox(height: 4.h),
                Text(
                  'Bill #${o.billNumber} • ${o.formattedDate}',
                  style: AppTextStyles.cardCaption,
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            decoration: BoxDecoration(
              color:
                  isCleared
                      ? AppColors.success.withOpacity(0.1)
                      : AppColors.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Text(
              isCleared ? 'Paid' : 'Due',
              style: TextStyle(
                color: isCleared ? AppColors.success : AppColors.warning,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _kv('Total', '₹${o.total.toStringAsFixed(2)}'),
                  ),
                  Expanded(
                    child: _kv('Paid', '₹${o.paidAmount.toStringAsFixed(2)}'),
                  ),
                  Expanded(
                    child: _kv('Remaining', '₹${remaining.toStringAsFixed(2)}'),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: Provider.of<ShopProvider>(
                  context,
                  listen: false,
                ).getSaleOrderItems(o.id),
                builder: (context, snap) {
                  final items = snap.data ?? [];
                  if (items.isEmpty) {
                    return Text(
                      'No item details',
                      style: AppTextStyles.cardCaption,
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Items', style: AppTextStyles.bodyMedium),
                      SizedBox(height: 8.h),
                      ...items.map(
                        (m) => Padding(
                          padding: EdgeInsets.symmetric(vertical: 4.h),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  m['item_name'] as String,
                                  style: AppTextStyles.bodyMedium,
                                ),
                              ),
                              Text(
                                '×${m['quantity']}',
                                style: AppTextStyles.cardCaption,
                              ),
                              SizedBox(width: 8.w),
                              Text(
                                '₹${(m['total_amount'] as num).toStringAsFixed(2)}',
                                style: AppTextStyles.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              SizedBox(height: 12.h),
              if (!isCleared) // Only show Update Payment button when there's remaining amount
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => _showUpdatePaymentDialog(o),
                    icon: Icon(Icons.payments, color: AppColors.primaryBlue),
                    label: Text(
                      'Update Payment',
                      style: AppTextStyles.menuItemPrimary,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _kv(String k, String v) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(k, style: AppTextStyles.cardCaption),
        SizedBox(height: 4.h),
        Text(v, style: AppTextStyles.cardSubtitle),
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
            backgroundColor: AppColors.backgroundLight,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.r),
            ),
            title: Text('Update Paid Amount', style: AppTextStyles.dialogTitle),
            content: TextField(
              controller: controller,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Paid Amount',
                hintText: 'Max: ₹${o.total.toStringAsFixed(2)}',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel', style: AppTextStyles.dialogButton),
              ),
              TextButton(
                onPressed: () async {
                  final v = double.tryParse(controller.text) ?? o.paidAmount;
                  if (v > o.total) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Paid amount (₹${v.toStringAsFixed(2)}) cannot exceed total amount (₹${o.total.toStringAsFixed(2)})',
                        ),
                        backgroundColor: Colors.red,
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
                      backgroundColor: Colors.green,
                    ),
                  );
                  _refresh();
                },
                child: Text('Save', style: AppTextStyles.dialogTitle),
              ),
            ],
          ),
    );
  }
}
