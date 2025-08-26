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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          '${widget.shop.name} - Purchases',
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
      body: FutureBuilder<List<Purchase>>(
        future: _futurePurchases,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          final purchases = snapshot.data ?? [];
          if (purchases.isEmpty) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(24.w),
                child: Text('No purchases yet', style: AppTextStyles.bodyLarge),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              padding: EdgeInsets.all(16.w),
              itemCount: purchases.length,
              separatorBuilder: (_, __) => SizedBox(height: 12.h),
              itemBuilder: (context, index) {
                final p = purchases[index];
                return _buildPurchaseCard(p);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildPurchaseCard(Purchase p) {
    final remaining = p.remainingAmount;
    final isCleared = remaining <= 0.0001;
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowBlue,
            blurRadius: 10.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(p.itemName, style: AppTextStyles.cardTitle),
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
          SizedBox(height: 8.h),
          Text('Supplier: ${p.partyName}', style: AppTextStyles.cardSubtitle),
          if (p.partyAddress.isNotEmpty)
            Text(p.partyAddress, style: AppTextStyles.cardCaption),
          SizedBox(height: 8.h),
          Row(
            children: [
              Expanded(child: _kv('Qty', p.quantity.toString())),
              Expanded(
                child: _kv(
                  'Unit Buy',
                  '₹${p.unitPurchasePrice.toStringAsFixed(2)}',
                ),
              ),
              Expanded(
                child: _kv('Total', '₹${p.totalAmount.toStringAsFixed(2)}'),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Expanded(
                child: _kv('Invoice', '₹${p.totalPayment.toStringAsFixed(2)}'),
              ),
              Expanded(
                child: _kv('Paid', '₹${p.paidAmount.toStringAsFixed(2)}'),
              ),
              Expanded(
                child: _kv('Remaining', '₹${remaining.toStringAsFixed(2)}'),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => _showUpdatePaidDialog(p),
              icon: Icon(Icons.payments, color: AppColors.primaryBlue),
              label: Text(
                'Update Payment',
                style: AppTextStyles.menuItemPrimary,
              ),
            ),
          ),
        ],
      ),
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

  void _showUpdatePaidDialog(Purchase p) {
    final controller = TextEditingController(
      text: p.paidAmount.toStringAsFixed(2),
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
                  final v = double.tryParse(controller.text) ?? p.paidAmount;
                  await Provider.of<ShopProvider>(
                    context,
                    listen: false,
                  ).updatePurchasePayment(purchaseId: p.id, paidAmount: v);
                  Navigator.pop(context);
                  _refresh();
                },
                child: Text('Save', style: AppTextStyles.dialogTitle),
              ),
            ],
          ),
    );
  }
}
