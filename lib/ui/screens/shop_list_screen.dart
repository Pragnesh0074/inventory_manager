import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../models/shop.dart';
import '../../providers/shop_provider.dart';
import '../../theme/color.dart';
import '../../theme/style.dart';
import 'add_edit_shop_screen.dart';
import 'inventory_screen.dart';
import 'statistics_summary_screen.dart';

class ShopListScreen extends StatelessWidget {
  const ShopListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text('Inventory Management', style: AppTextStyles.appBarTitle),
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
        toolbarHeight: 56.h,
      ),
      body: Consumer<ShopProvider>(
        builder: (context, shopProvider, child) {
          if (shopProvider.shops.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(24.r),
                    decoration: BoxDecoration(
                      color: AppColors.blueTinted,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.shadowBlue,
                          blurRadius: 20.r,
                          spreadRadius: 5.r,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.store_outlined,
                      size: 64.r,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                  SizedBox(height: 24.h),
                  Text(
                    'No shops available',
                    style: AppTextStyles.emptyStateTitle,
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Create your first shop to get started',
                    style: AppTextStyles.emptyStateSubtitle,
                  ),
                  SizedBox(height: 32.h),
                  Container(
                    decoration: BoxDecoration(
                      gradient: AppColors.accentGradient,
                      borderRadius: BorderRadius.circular(30.r),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.shadowBlueStrong,
                          blurRadius: 15.r,
                          offset: Offset(0, 5.h),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () => _navigateToAddShop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: EdgeInsets.symmetric(
                          horizontal: 28.w,
                          vertical: 14.h,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30.r),
                        ),
                      ),
                      icon: Icon(
                        Icons.add,
                        color: AppColors.textOnPrimary,
                        size: 20.r,
                      ),
                      label: Text(
                        'Add Your First Shop',
                        style: AppTextStyles.buttonLarge,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return Padding(
            padding: EdgeInsets.all(16.r),
            child: ListView.builder(
              itemCount: shopProvider.shops.length,
              itemBuilder: (context, index) {
                final shop = shopProvider.shops[index];
                return GestureDetector(
                  onTap: () {
                    shopProvider.setCurrentShop(shop);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => InventoryScreen(shop: shop),
                      ),
                    );
                  },
                  child: Container(
                    margin: EdgeInsets.only(bottom: 16.h),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(16.r),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.shadowBlue,
                          blurRadius: 15.r,
                          spreadRadius: 2.r,
                          offset: Offset(0, 4.h),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: Padding(
                        padding: EdgeInsets.all(16.r),
                        child: Row(
                          children: [
                            Container(
                              width: 56.w,
                              height: 56.h,
                              decoration: BoxDecoration(
                                gradient: AppColors.lightGradient,
                                borderRadius: BorderRadius.circular(16.r),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.shadowBlueStrong,
                                    blurRadius: 8.r,
                                    offset: Offset(0, 2.h),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.store,
                                color: AppColors.textOnPrimary,
                                size: 28.r,
                              ),
                            ),
                            SizedBox(width: 16.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    shop.name,
                                    style: AppTextStyles.cardTitle,
                                  ),
                                  SizedBox(height: 4.h),
                                  Text(
                                    shop.address,
                                    style: AppTextStyles.cardSubtitle,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 8.h),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8.w,
                                      vertical: 4.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.blueAccent,
                                      borderRadius: BorderRadius.circular(8.r),
                                    ),
                                    child: Text(
                                      '${shop.inventory.length} items',
                                      style: AppTextStyles.cardCaption,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 16.w),
                            Container(
                              decoration: BoxDecoration(
                                color: AppColors.surfaceLight,
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              child: PopupMenuButton(
                                color: AppColors.backgroundLight,
                                icon: const Icon(
                                  Icons.more_vert,
                                  color: AppColors.textSecondary,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                                elevation: 8,
                                shadowColor: AppColors.shadowBlueMedium,
                                itemBuilder:
                                    (context) => [
                                      PopupMenuItem(
                                        value: 'statistics',
                                        child: Container(
                                          padding: EdgeInsets.symmetric(
                                            vertical: 4.h,
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.analytics_outlined,
                                                size: 20,
                                                color: AppColors.primaryBlue,
                                              ),
                                              SizedBox(width: 12),
                                              Text(
                                                'Statistics',
                                                style:
                                                    AppTextStyles
                                                        .menuItemPrimary,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      PopupMenuItem(
                                        value: 'edit',
                                        child: Container(
                                          padding: EdgeInsets.symmetric(
                                            vertical: 4.h,
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.edit_outlined,
                                                size: 20,
                                                color: AppColors.primaryBlue,
                                              ),
                                              SizedBox(width: 12),
                                              Text(
                                                'Edit',
                                                style:
                                                    AppTextStyles
                                                        .menuItemPrimary,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      PopupMenuItem(
                                        value: 'delete',
                                        child: Container(
                                          padding: EdgeInsets.symmetric(
                                            vertical: 4.h,
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.delete_outline,
                                                size: 20,
                                                color: AppColors.error,
                                              ),
                                              SizedBox(width: 12),
                                              Text(
                                                'Delete',
                                                style:
                                                    AppTextStyles
                                                        .menuItemDanger,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                onSelected: (value) {
                                  if (value == 'statistics') {
                                    _navigateToStatistics(context, shop);
                                  } else if (value == 'edit') {
                                    _navigateToEditShop(context, shop);
                                  } else if (value == 'delete') {
                                    _showDeleteDialog(context, shop);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowBlueFAB,
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () => _navigateToAddShop(context),
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(
            Icons.add,
            color: AppColors.textOnPrimary,
            size: 28,
          ),
        ),
      ),
    );
  }

  void _navigateToAddShop(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddEditShopScreen()),
    );
  }

  void _navigateToStatistics(BuildContext context, Shop shop) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) =>
                StatisticsSummaryScreen(shopId: shop.id, shopName: shop.name),
      ),
    );
  }

  void _navigateToEditShop(BuildContext context, Shop shop) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddEditShopScreen(shop: shop)),
    );
  }

  void _showDeleteDialog(BuildContext context, Shop shop) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.r),
            ),
            title: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.r),
                  decoration: BoxDecoration(
                    color: AppColors.errorLight,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: const Icon(
                    Icons.warning_outlined,
                    color: AppColors.error,
                    size: 24,
                  ),
                ),
                SizedBox(width: 12.w),
                Text('Delete Shop', style: AppTextStyles.dialogTitle),
              ],
            ),
            content: Text(
              'Are you sure you want to delete "${shop.name}"? This action cannot be undone.',
              style: AppTextStyles.dialogContent,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: 20.w,
                    vertical: 12.h,
                  ),
                ),
                child: Text('Cancel', style: AppTextStyles.dialogButton),
              ),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: TextButton(
                  onPressed: () {
                    Provider.of<ShopProvider>(
                      context,
                      listen: false,
                    ).deleteShop(shop.id);
                    Navigator.pop(context);
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    padding: EdgeInsets.symmetric(
                      horizontal: 20.w,
                      vertical: 12.h,
                    ),
                  ),
                  child: Text(
                    'Delete',
                    style: AppTextStyles.dialogButtonPrimary,
                  ),
                ),
              ),
            ],
          ),
    );
  }
}
