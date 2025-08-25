import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:inventory_manager/ui/screens/multi_item_sale_screen.dart';
import 'package:inventory_manager/ui/screens/sale_summary_screen.dart';
import 'package:provider/provider.dart';
import '../../models/inventory_item.dart';
import '../../models/shop.dart';
import '../../providers/shop_provider.dart';
import '../../theme/color.dart';
import '../../theme/style.dart';
import 'add_edit_item_screen.dart';
import 'item_detail_screen.dart';
import 'monthly_summary_screen.dart';
import 'sales_list_screen.dart';

class InventoryScreen extends StatelessWidget {
  final Shop shop;

  const InventoryScreen({super.key, required this.shop});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          '${shop.name} - Inventory',
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
          Padding(
            padding: EdgeInsets.only(right: 10.w),
            child: IconButton(
              icon: Icon(
                Icons.receipt_long,
                color: AppColors.textOnPrimary,
                size: 24.sp,
              ),
              onPressed:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SalesListScreen(shop: shop),
                    ),
                  ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(right: 10.w),
            child: IconButton(
              icon: Icon(
                Icons.point_of_sale,
                color: AppColors.textOnPrimary,
                size: 24.sp,
              ),
              onPressed:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MultiItemSaleScreen(shop: shop),
                    ),
                  ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(right: 10.w),
            child: IconButton(
              icon: Icon(
                Icons.analytics,
                color: AppColors.textOnPrimary,
                size: 24.sp,
              ),
              onPressed:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MonthlySummaryScreen(shop: shop),
                    ),
                  ),
            ),
          ),
        ],
      ),
      body: Consumer<ShopProvider>(
        builder: (context, shopProvider, child) {
          final currentShop = shopProvider.shops.firstWhere(
            (s) => s.id == shop.id,
          );

          if (currentShop.inventory.isEmpty) {
            return _buildEmptyState(context, currentShop);
          }

          return Column(
            children: [
              _buildSummarySection(currentShop),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: ListView.separated(
                    itemCount: currentShop.inventory.length,
                    separatorBuilder:
                        (context, index) => SizedBox(height: 12.h),
                    itemBuilder: (context, index) {
                      final item = currentShop.inventory[index];
                      return _buildInventoryCard(context, currentShop, item);
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: AppColors.accentGradient,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowBlueFAB,
              blurRadius: 15.r,
              offset: Offset(0, 6.h),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () => _navigateToAddItem(context, shop),
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Icon(Icons.add, color: AppColors.textOnPrimary, size: 28.sp),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, Shop shop) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Container(
          padding: EdgeInsets.all(32.w),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(24.r),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowBlue,
                blurRadius: 20.r,
                spreadRadius: 2.r,
                offset: Offset(0, 8.h),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(24.r),
                decoration: BoxDecoration(
                  gradient: AppColors.lightGradient,
                  borderRadius: BorderRadius.circular(20.r),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadowBlueStrong,
                      blurRadius: 15.r,
                      offset: Offset(0, 6.h),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.inventory_2_outlined,
                  size: 60.sp,
                  color: AppColors.textOnPrimary,
                ),
              ),
              SizedBox(height: 24.h),
              Text('No Items Yet', style: AppTextStyles.emptyStateTitle),
              SizedBox(height: 12.h),
              Text(
                'Start building your inventory by adding your first item',
                style: AppTextStyles.emptyStateSubtitle,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 32.h),
              Container(
                width: double.infinity,
                height: 50.h,
                decoration: BoxDecoration(
                  gradient: AppColors.accentGradient,
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadowBlueFAB,
                      blurRadius: 15.r,
                      offset: Offset(0, 6.h),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: () => _navigateToAddItem(context, shop),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                  ),
                  icon: Icon(
                    Icons.add,
                    color: AppColors.textOnPrimary,
                    size: 20.sp,
                  ),
                  label: Text(
                    'Add First Item',
                    style: AppTextStyles.buttonLarge,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummarySection(Shop shop) {
    final totalItems = shop.inventory.length;
    final lowStockItems =
        shop.inventory.where((item) => item.quantity < 10).length;
    final totalValue = shop.inventory.fold(
      0.0,
      (sum, item) => sum + (item.price * item.quantity),
    );

    return Container(
      margin: EdgeInsets.all(16.w),
      padding: EdgeInsets.all(20.w),
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
          Text('Inventory Overview', style: AppTextStyles.headingMedium),
          SizedBox(height: 16.h),
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    'Total Items',
                    totalItems.toString(),
                    Icons.inventory_2_outlined,
                    AppColors.primaryBlue,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _buildSummaryCard(
                    'Low Stock',
                    lowStockItems.toString(),
                    Icons.warning_amber_outlined,
                    AppColors.warning,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _buildSummaryCard(
                    'Total Value',
                    '₹${totalValue.toStringAsFixed(2)}',
                    Icons.currency_rupee_rounded,
                    AppColors.success,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: color.withOpacity(0.2), width: 1.w),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(icon, color: color, size: 20.sp),
          ),
          SizedBox(height: 12.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8.h),
          Text(
            title,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryCard(
    BuildContext context,
    Shop shop,
    InventoryItem item,
  ) {
    final isLowStock = item.quantity < 10;

    return InkWell(
      onTap:
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ItemDetailScreen(shop: shop, item: item),
            ),
          ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Row(
            children: [
              Container(
                width: 60.w,
                height: 60.w,
                decoration: BoxDecoration(
                  gradient:
                      isLowStock
                          ? LinearGradient(
                            colors: [
                              AppColors.error,
                              AppColors.error.withOpacity(0.7),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                          : AppColors.lightGradient,
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: [
                    BoxShadow(
                      color:
                          isLowStock
                              ? AppColors.error.withOpacity(0.3)
                              : AppColors.shadowBlueStrong,
                      blurRadius: 10.r,
                      offset: Offset(0, 4.h),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    item.quantity.toString(),
                    style: TextStyle(
                      color: AppColors.textOnPrimary,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: AppTextStyles.cardTitle.copyWith(fontSize: 16.sp),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'Price: ₹${item.price.toStringAsFixed(2)}',
                      style: AppTextStyles.cardSubtitle,
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'Updated: ${_formatDate(item.lastUpdated)}',
                      style: AppTextStyles.cardCaption,
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildActionButton(
                        icon: Icons.point_of_sale,
                        color: AppColors.primaryBlue,
                        onPressed:
                            () => _showQuickSaleDialog(context, shop, item),
                      ),
                      SizedBox(width: 8.w),
                      _buildActionButton(
                        icon: Icons.remove_shopping_cart,
                        color: AppColors.error,
                        onPressed: () => _showSellDialog(context, shop, item),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildActionButton(
                        icon: Icons.add_shopping_cart,
                        color: AppColors.success,
                        onPressed:
                            () => _showAddStockDialog(context, shop, item),
                      ),
                      SizedBox(width: 8.w),
                      _buildMenuButton(context, shop, item),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showQuickSaleDialog(
    BuildContext context,
    Shop shop,
    InventoryItem item,
  ) {
    final quantityController = TextEditingController();
    final customerNameController = TextEditingController();
    final customerPhoneController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: AppColors.backgroundLight,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.r),
            ),
            title: Text(
              'Quick Sale - ${item.name}',
              style: AppTextStyles.dialogTitle,
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: AppColors.blueTinted,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.inventory,
                          color: AppColors.primaryBlue,
                          size: 20.sp,
                        ),
                        SizedBox(width: 12.w),
                        Column(
                          children: [
                            Text(
                              'Available: ${item.quantity}',
                              style: AppTextStyles.dialogContent,
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              'Price: ₹${item.price.toStringAsFixed(2)}',
                              style: AppTextStyles.dialogContent,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),
                  TextField(
                    controller: quantityController,
                    keyboardType: TextInputType.number,
                    style: AppTextStyles.bodyLarge,
                    decoration: InputDecoration(
                      labelText: 'Quantity to sell',
                      labelStyle: AppTextStyles.bodyMedium,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide(color: AppColors.primaryBlue),
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  TextField(
                    controller: customerNameController,
                    style: AppTextStyles.bodyLarge,
                    decoration: InputDecoration(
                      labelText: 'Customer Name (Optional)',
                      labelStyle: AppTextStyles.bodyMedium,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide(color: AppColors.primaryBlue),
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  TextField(
                    controller: customerPhoneController,
                    keyboardType: TextInputType.phone,
                    style: AppTextStyles.bodyLarge,
                    decoration: InputDecoration(
                      labelText: 'Customer Phone (Optional)',
                      labelStyle: AppTextStyles.bodyMedium,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide(color: AppColors.primaryBlue),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel', style: AppTextStyles.dialogButton),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: AppColors.accentGradient,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: TextButton(
                  onPressed: () {
                    final quantity = int.tryParse(quantityController.text) ?? 0;
                    if (quantity > 0 && quantity <= item.quantity) {
                      Navigator.pop(context);
                      final saleItems = [
                        SaleItem(item: item, quantity: quantity),
                      ];
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => SaleSummaryScreen(
                                shop: shop,
                                saleItems: saleItems,
                                additionalCharges:
                                    [], // No additional charges for quick sale
                                customerName:
                                    customerNameController.text.trim(),
                                customerPhone:
                                    customerPhoneController.text.trim(),
                              ),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Invalid quantity'),
                          backgroundColor: AppColors.error,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                      );
                    }
                  },
                  child: Text(
                    'Proceed to Bill',
                    style: AppTextStyles.dialogButtonPrimary,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: 40.w,
      height: 40.h,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color.withOpacity(0.2), width: 1.w),
      ),
      child: IconButton(
        icon: Icon(icon, color: color, size: 18.sp),
        onPressed: onPressed,
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildMenuButton(BuildContext context, Shop shop, InventoryItem item) {
    return Container(
      width: 40.w,
      height: 40.h,
      decoration: BoxDecoration(
        color: AppColors.blueTinted,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: PopupMenuButton(
        color: AppColors.backgroundLight,
        padding: EdgeInsets.zero,
        icon: Icon(Icons.more_vert, color: AppColors.primaryBlue, size: 18.sp),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        itemBuilder:
            (context) => [
              PopupMenuItem(
                value: 'view',
                child: Row(
                  children: [
                    Icon(
                      Icons.visibility,
                      size: 20.sp,
                      color: AppColors.primaryBlue,
                    ),
                    SizedBox(width: 12.w),
                    Text('View Details', style: AppTextStyles.menuItemPrimary),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(
                      Icons.edit,
                      size: 20.sp,
                      color: AppColors.textSecondary,
                    ),
                    SizedBox(width: 12.w),
                    Text('Edit', style: AppTextStyles.menuItem),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 20.sp, color: AppColors.error),
                    SizedBox(width: 12.w),
                    Text('Delete', style: AppTextStyles.menuItemDanger),
                  ],
                ),
              ),
            ],
        onSelected: (value) {
          if (value == 'view') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ItemDetailScreen(shop: shop, item: item),
              ),
            );
          } else if (value == 'edit') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddEditItemScreen(shop: shop, item: item),
              ),
            );
          } else if (value == 'delete') {
            _showDeleteDialog(context, shop, item);
          }
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _navigateToAddItem(BuildContext context, Shop shop) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddEditItemScreen(shop: shop)),
    );
  }

  void _showSellDialog(BuildContext context, Shop shop, InventoryItem item) {
    final quantityController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: AppColors.backgroundLight,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.r),
            ),
            title: Text(
              'Remove Stock - ${item.name}',
              style: AppTextStyles.dialogTitle,
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: AppColors.blueTinted,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.inventory,
                        color: AppColors.primaryBlue,
                        size: 20.sp,
                      ),
                      SizedBox(width: 12.w),
                      Text(
                        'Available: ${item.quantity}',
                        style: AppTextStyles.dialogContent,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16.h),
                TextField(
                  controller: quantityController,
                  keyboardType: TextInputType.number,
                  style: AppTextStyles.bodyLarge,
                  decoration: InputDecoration(
                    labelText: 'Quantity to sell',
                    labelStyle: AppTextStyles.bodyMedium,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide(color: AppColors.primaryBlue),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel', style: AppTextStyles.dialogButton),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: AppColors.accentGradient,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: TextButton(
                  onPressed: () {
                    final quantity = int.tryParse(quantityController.text) ?? 0;
                    if (quantity > 0 && quantity <= item.quantity) {
                      Provider.of<ShopProvider>(
                        context,
                        listen: false,
                      ).sellItem(shop.id, item.id, quantity);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Sold $quantity ${item.name}(s)'),
                          backgroundColor: AppColors.success,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Invalid quantity'),
                          backgroundColor: AppColors.error,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                      );
                    }
                  },
                  child: Text('Sell', style: AppTextStyles.dialogButtonPrimary),
                ),
              ),
            ],
          ),
    );
  }

  void _showAddStockDialog(
    BuildContext context,
    Shop shop,
    InventoryItem item,
  ) {
    final quantityController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: AppColors.backgroundLight,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.r),
            ),
            title: Text(
              'Add Stock - ${item.name}',
              style: AppTextStyles.dialogTitle,
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: AppColors.blueTinted,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.inventory,
                        color: AppColors.primaryBlue,
                        size: 20.sp,
                      ),
                      SizedBox(width: 12.w),
                      Text(
                        'Current Stock: ${item.quantity}',
                        style: AppTextStyles.dialogContent,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16.h),
                TextField(
                  controller: quantityController,
                  keyboardType: TextInputType.number,
                  style: AppTextStyles.bodyLarge,
                  decoration: InputDecoration(
                    labelText: 'Quantity to add',
                    labelStyle: AppTextStyles.bodyMedium,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide(color: AppColors.primaryBlue),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel', style: AppTextStyles.dialogButton),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: AppColors.accentGradient,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: TextButton(
                  onPressed: () {
                    final quantity = int.tryParse(quantityController.text) ?? 0;
                    if (quantity > 0) {
                      Provider.of<ShopProvider>(
                        context,
                        listen: false,
                      ).addStock(shop.id, item.id, quantity);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Added $quantity ${item.name}(s) to stock',
                          ),
                          backgroundColor: AppColors.success,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                      );
                    }
                  },
                  child: Text('Add', style: AppTextStyles.dialogButtonPrimary),
                ),
              ),
            ],
          ),
    );
  }

  void _showDeleteDialog(BuildContext context, Shop shop, InventoryItem item) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: AppColors.backgroundLight,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.r),
            ),
            title: Text('Delete Item', style: AppTextStyles.dialogTitle),
            content: Text(
              'Are you sure you want to delete "${item.name}"?',
              style: AppTextStyles.dialogContent,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel', style: AppTextStyles.dialogButton),
              ),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: TextButton(
                  onPressed: () {
                    Provider.of<ShopProvider>(
                      context,
                      listen: false,
                    ).deleteInventoryItem(shop.id, item.id);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Item deleted successfully'),
                        backgroundColor: AppColors.error,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                    );
                  },
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
