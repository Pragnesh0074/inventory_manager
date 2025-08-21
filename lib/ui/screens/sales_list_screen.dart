import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../models/shop.dart';
import '../../models/sale_order.dart';
import '../../providers/shop_provider.dart';
import '../../theme/color.dart';
import '../../theme/style.dart';
import 'sale_detail_screen.dart';

class SalesListScreen extends StatelessWidget {
  final Shop shop;

  const SalesListScreen({super.key, required this.shop});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text('Sales - ${shop.name}', style: AppTextStyles.appBarTitle),
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
      body: Consumer<ShopProvider>(
        builder: (context, shopProvider, child) {
          final currentShop = shopProvider.shops.firstWhere(
            (s) => s.id == shop.id,
          );

          // Get sale orders instead of individual transactions
          final saleOrders = shopProvider.getSaleOrders(shop.id);

          if (saleOrders.isEmpty) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(24.w),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.receipt_long,
                      size: 64.sp,
                      color: AppColors.textSecondary.withOpacity(0.5),
                    ),
                    SizedBox(height: 12.h),
                    Text('No sales yet', style: AppTextStyles.emptyStateTitle),
                    SizedBox(height: 8.h),
                    Text(
                      'Sales will appear here once you complete a sale',
                      style: AppTextStyles.emptyStateSubtitle,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: EdgeInsets.all(16.w),
            itemCount: saleOrders.length,
            separatorBuilder: (context, index) => SizedBox(height: 12.h),
            itemBuilder: (context, index) {
              final saleOrder = saleOrders[index];
              return _buildSaleOrderCard(context, currentShop, saleOrder);
            },
          );
        },
      ),
    );
  }

  Widget _buildSaleOrderCard(
    BuildContext context,
    Shop shop,
    SaleOrder saleOrder,
  ) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => SaleDetailScreen(shop: shop, saleOrder: saleOrder),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowBlue,
              blurRadius: 12.r,
              spreadRadius: 1.r,
              offset: Offset(0, 4.h),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with bill number and total
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: AppColors.blueTinted,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(
                      Icons.receipt_long,
                      color: AppColors.primaryBlue,
                      size: 20.sp,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bill #${saleOrder.billNumber}',
                          style: AppTextStyles.bodyLarge.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          saleOrder.formattedDateTime,
                          style: AppTextStyles.cardCaption,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        saleOrder.formattedTotal,
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.success,
                        ),
                      ),
                      Text(
                        '${saleOrder.itemCount} items',
                        style: AppTextStyles.cardCaption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              SizedBox(height: 12.h),

              // Customer info
              if (saleOrder.customerName.isNotEmpty ||
                  saleOrder.customerPhone.isNotEmpty)
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: AppColors.blueTinted.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.person_outline,
                        size: 16.sp,
                        color: AppColors.primaryBlue,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (saleOrder.customerName.isNotEmpty)
                              Text(
                                saleOrder.customerName,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            if (saleOrder.customerPhone.isNotEmpty)
                              Text(
                                saleOrder.customerPhone,
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              SizedBox(height: 8.h),

              // Items summary
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  border: Border.all(
                    color: AppColors.shadowBlue.withOpacity(0.2),
                  ),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Items (${saleOrder.totalQuantity} total)',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    ...saleOrder.items
                        .take(3)
                        .map(
                          (item) => Padding(
                            padding: EdgeInsets.only(bottom: 4.h),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '• ${item.item.name}',
                                    style: AppTextStyles.bodySmall,
                                  ),
                                ),
                                Text(
                                  '${item.quantity} × ₹${item.unitPrice.toStringAsFixed(2)}',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    if (saleOrder.items.length > 3)
                      Text(
                        '... and ${saleOrder.items.length - 3} more items',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
