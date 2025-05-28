import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../models/inventory_item.dart';
import '../../models/shop.dart';
import '../../theme/color.dart';
import '../../theme/style.dart';
import 'add_edit_item_screen.dart';

class ItemDetailScreen extends StatelessWidget {
  final Shop shop;
  final InventoryItem item;

  const ItemDetailScreen({super.key, required this.shop, required this.item});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          item.name,
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
        actions: [
          IconButton(
            icon: Icon(
              Icons.edit,
              color: AppColors.textOnPrimary,
              size: 22.sp,
            ),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(
                builder: (context) => AddEditItemScreen(shop: shop, item: item)
              ));
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card with Item Icon
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20.r),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(20.r),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadowBlue,
                      blurRadius: 15.r,
                      spreadRadius: 2.r,
                      offset: Offset(0, 4.h),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.all(16.r),
                      decoration: BoxDecoration(
                        gradient: AppColors.lightGradient,
                        borderRadius: BorderRadius.circular(16.r),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.shadowBlueStrong,
                            blurRadius: 10.r,
                            offset: Offset(0, 4.h),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.inventory_2,
                        size: 40.sp,
                        color: AppColors.textOnPrimary,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      item.name,
                      style: AppTextStyles.headingLarge,
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8.h),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                      decoration: BoxDecoration(
                        color: AppColors.blueTinted,
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Text(
                        'From ${shop.name}',
                        style: AppTextStyles.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20.h),

              // Item Information Card
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(24.w),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(20.r),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadowBlue,
                      blurRadius: 15.r,
                      spreadRadius: 2.r,
                      offset: Offset(0, 4.h),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(8.w),
                          decoration: BoxDecoration(
                            color: AppColors.blueTinted,
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Icon(
                            Icons.info_outline,
                            color: AppColors.primaryBlue,
                            size: 20.sp,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Text(
                          'Item Information',
                          style: AppTextStyles.headingMedium,
                        ),
                      ],
                    ),
                    SizedBox(height: 20.h),

                    // Information Grid
                    _buildInfoGrid(),
                  ],
                ),
              ),
              SizedBox(height: 20.h),

              // Stock History Section
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(20.r),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadowBlue,
                      blurRadius: 15.r,
                      spreadRadius: 2.r,
                      offset: Offset(0, 4.h),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.all(24.w),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(8.w),
                            decoration: BoxDecoration(
                              color: AppColors.blueTinted,
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Icon(
                              Icons.history,
                              color: AppColors.primaryBlue,
                              size: 20.sp,
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Text(
                            'Stock History',
                            style: AppTextStyles.headingMedium,
                          ),
                          Spacer(),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                            decoration: BoxDecoration(
                              color: AppColors.blueTinted,
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: Text(
                              '${item.stockEntries.length} entries',
                              style: AppTextStyles.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Stock History List
                    item.stockEntries.isEmpty
                        ? _buildEmptyState()
                        : _buildStockHistoryList(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoGrid() {
    return Column(
      children: [
        IntrinsicHeight(
          child: Row(
            children: [
              Expanded(child: _buildInfoCard('Price', '₹${item.price.toStringAsFixed(2)}', Icons.currency_rupee_rounded, AppColors.success)),
              SizedBox(width: 12.w),
              Expanded(child: _buildInfoCard('Stock', item.quantity.toString(), Icons.inventory, AppColors.primaryBlue)),
            ],
          ),
        ),
        SizedBox(height: 12.h),
        IntrinsicHeight(
          child: Row(
            children: [
              Expanded(child: _buildInfoCard('Total Value', '₹${(item.price * item.quantity).toStringAsFixed(2)}', Icons.account_balance_wallet, AppColors.warning)),
              SizedBox(width: 12.w),
              Expanded(child: _buildInfoCard('Created', _formatDate(item.createdDate), Icons.calendar_today, AppColors.textSecondary)),
            ],
          ),
        ),
        if (item.lastUpdated != null) ...[
          SizedBox(height: 12.h),
          _buildInfoCard('Last Updated', _formatDate(item.lastUpdated!), Icons.update, AppColors.textSecondary, fullWidth: true),
        ],
      ],
    );
  }

  Widget _buildInfoCard(String label, String value, IconData icon, Color color, {bool fullWidth = false}) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1.w,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: color,
                size: 18.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                label,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            value,
            style: AppTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: EdgeInsets.all(40.w),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: AppColors.blueTinted,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.history_outlined,
              size: 40.sp,
              color: AppColors.primaryBlue,
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            'No Stock History',
            style: AppTextStyles.emptyStateTitle.copyWith(fontSize: 18.sp),
          ),
          SizedBox(height: 8.h),
          Text(
            'Stock movements will appear here when inventory changes are made',
            style: AppTextStyles.emptyStateSubtitle.copyWith(fontSize: 14.sp),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStockHistoryList() {
    return ListView.separated(
      physics: NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      padding: EdgeInsets.only(bottom: 16.h),
      itemCount: item.stockEntries.length,
      separatorBuilder: (context, index) => Container(
        margin: EdgeInsets.symmetric(horizontal: 24.w),
        height: 1.h,
        color: AppColors.surfaceLight,
      ),
      itemBuilder: (context, index) {
        final entry = item.stockEntries.reversed.toList()[index];
        final isAddition = entry.type == 'addition';

        return Container(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
          child: Row(
            children: [
              Container(
                width: 48.w,
                height: 48.h,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isAddition
                        ? [AppColors.success, AppColors.success.withOpacity(0.8)]
                        : [AppColors.error, AppColors.error.withOpacity(0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12.r),
                  boxShadow: [
                    BoxShadow(
                      color: (isAddition ? AppColors.success : AppColors.error).withOpacity(0.3),
                      blurRadius: 8.r,
                      offset: Offset(0, 2.h),
                    ),
                  ],
                ),
                child: Icon(
                  isAddition ? Icons.add : Icons.remove,
                  color: Colors.white,
                  size: 24.sp,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '${isAddition ? '+' : '-'}${entry.quantity}',
                          style: AppTextStyles.bodyLarge.copyWith(
                            fontWeight: FontWeight.w700,
                            color: isAddition ? AppColors.success : AppColors.error,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: isAddition
                                ? AppColors.success.withOpacity(0.1)
                                : AppColors.error.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Text(
                            isAddition ? 'Added' : 'Removed',
                            style: TextStyle(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w600,
                              color: isAddition ? AppColors.success : AppColors.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      entry.note ?? 'No note provided',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      _formatDateTime(entry.dateTime),
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.textHint,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month]} ${date.year}';
  }

  String _formatDateTime(DateTime date) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final hour = date.hour == 0 ? 12 : (date.hour > 12 ? date.hour - 12 : date.hour);
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '${date.day} ${months[date.month]} ${date.year} at $hour:${date.minute.toString().padLeft(2, '0')} $period';
  }
}