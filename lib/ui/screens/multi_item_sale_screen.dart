import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../models/inventory_item.dart';
import '../../models/shop.dart';
import '../../providers/shop_provider.dart';
import '../../theme/color.dart';
import '../../theme/style.dart';
import 'sale_summary_screen.dart';

class SaleItem {
  final InventoryItem item;
  int quantity;

  SaleItem({required this.item, this.quantity = 1});

  double get totalPrice => item.price * quantity;
}

class MultiItemSaleScreen extends StatefulWidget {
  final Shop shop;

  const MultiItemSaleScreen({super.key, required this.shop});

  @override
  _MultiItemSaleScreenState createState() => _MultiItemSaleScreenState();
}

class _MultiItemSaleScreenState extends State<MultiItemSaleScreen> {
  List<SaleItem> selectedItems = [];
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _customerPhoneController =
      TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          'Create Sale - ${widget.shop.name}',
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
          if (selectedItems.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(right: 16.w),
              child: IconButton(
                icon: Icon(
                  Icons.shopping_cart,
                  color: AppColors.textOnPrimary,
                  size: 24.sp,
                ),
                onPressed: () => _showSelectedItemsBottomSheet(),
              ),
            ),
        ],
      ),
      body: Consumer<ShopProvider>(
        builder: (context, shopProvider, child) {
          final currentShop = shopProvider.shops.firstWhere(
            (s) => s.id == widget.shop.id,
          );

          if (currentShop.inventory.isEmpty) {
            return _buildEmptyInventoryState();
          }

          return Column(
            children: [
              // Customer Info Card
              _buildCustomerInfoCard(),

              // Selected Items Summary (if any)
              if (selectedItems.isNotEmpty) _buildSelectedItemsSummary(),

              // Available Items List
              Expanded(child: _buildInventoryList(currentShop)),
            ],
          );
        },
      ),
      floatingActionButton:
          selectedItems.isNotEmpty
              ? Container(
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
                child: FloatingActionButton.extended(
                  onPressed: _proceedToSale,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  icon: Icon(
                    Icons.point_of_sale,
                    color: AppColors.textOnPrimary,
                  ),
                  label: Text(
                    'Proceed to Sale',
                    style: AppTextStyles.buttonLarge.copyWith(fontSize: 14.sp),
                  ),
                ),
              )
              : null,
    );
  }

  Widget _buildCustomerInfoCard() {
    return Container(
      margin: EdgeInsets.all(16.w),
      padding: EdgeInsets.all(20.w),
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
                  Icons.person_outline,
                  color: AppColors.primaryBlue,
                  size: 20.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Text('Customer Information', style: AppTextStyles.headingMedium),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: _buildCustomerField(
                  controller: _customerNameController,
                  label: 'Customer Name',
                  hint: 'Enter name (optional)',
                  icon: Icons.person,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildCustomerField(
                  controller: _customerPhoneController,
                  label: 'Phone Number',
                  hint: 'Enter phone (optional)',
                  icon: Icons.phone,
                  keyboardType: TextInputType.phone,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        SizedBox(height: 6.h),
        Container(
          height: 44.h,
          decoration: BoxDecoration(
            color: AppColors.backgroundLight,
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(color: AppColors.surfaceLight),
          ),
          child: TextField(
            onTapOutside: (_) => FocusScope.of(context).unfocus(),
            controller: controller,
            keyboardType: keyboardType,
            style: AppTextStyles.bodyMedium,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textHint,
              ),
              prefixIcon: Icon(
                icon,
                color: AppColors.textSecondary,
                size: 18.sp,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12.w,
                vertical: 12.h,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedItemsSummary() {
    final totalAmount = selectedItems.fold(
      0.0,
      (sum, item) => sum + item.totalPrice,
    );
    final totalItems = selectedItems.fold(
      0,
      (sum, item) => sum + item.quantity,
    );

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: AppColors.lightGradient,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowBlueStrong,
            blurRadius: 10.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${selectedItems.length} Items Selected',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textOnPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Total Qty: $totalItems',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textOnPrimary.withOpacity(0.8),
                ),
              ),
            ],
          ),
          Text(
            '₹${totalAmount.toStringAsFixed(2)}',
            style: AppTextStyles.headingMedium.copyWith(
              color: AppColors.textOnPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryList(Shop shop) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(vertical: 12.h),
            child: Text('Available Items', style: AppTextStyles.headingMedium),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: shop.inventory.length,
              separatorBuilder: (context, index) => SizedBox(height: 8.h),
              itemBuilder: (context, index) {
                final item = shop.inventory[index];
                final selectedItem = selectedItems.firstWhere(
                  (sItem) => sItem.item.id == item.id,
                  orElse: () => SaleItem(item: item, quantity: 0),
                );
                final isSelected = selectedItem.quantity > 0;

                return _buildInventoryItemCard(item, selectedItem, isSelected);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryItemCard(
    InventoryItem item,
    SaleItem selectedItem,
    bool isSelected,
  ) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12.r),
        border:
            isSelected
                ? Border.all(color: AppColors.primaryBlue, width: 2.w)
                : null,
        boxShadow: [
          BoxShadow(
            color:
                isSelected
                    ? AppColors.primaryBlue.withOpacity(0.1)
                    : AppColors.shadowBlue,
            blurRadius: isSelected ? 8.r : 6.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Row(
        children: [
          // Item Info
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                    color:
                        isSelected
                            ? AppColors.primaryBlue
                            : AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  '₹${item.price.toStringAsFixed(2)} each',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.success,
                  ),
                ),
                Text(
                  'Stock: ${item.quantity}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Quantity Controls
          if (isSelected) ...[
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildQuantityButton(
                        icon: Icons.remove,
                        onPressed:
                            () => _updateQuantity(
                              item,
                              selectedItem.quantity - 1,
                            ),
                        color: AppColors.error,
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 8.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.blueTinted,
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          '${selectedItem.quantity}',
                          style: AppTextStyles.bodyLarge.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                      ),
                      _buildQuantityButton(
                        icon: Icons.add,
                        onPressed:
                            selectedItem.quantity < item.quantity
                                ? () => _updateQuantity(
                                  item,
                                  selectedItem.quantity + 1,
                                )
                                : null,
                        color: AppColors.success,
                      ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    '₹${selectedItem.totalPrice.toStringAsFixed(2)}',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            // Add Button
            Container(
              decoration: BoxDecoration(
                gradient: AppColors.lightGradient,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: IconButton(
                onPressed:
                    item.quantity > 0 ? () => _updateQuantity(item, 1) : null,
                icon: Icon(
                  Icons.add_shopping_cart,
                  color: AppColors.textOnPrimary,
                  size: 20.sp,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuantityButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required Color color,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6.r),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(6.r),
        child: Container(
          padding: EdgeInsets.all(6.w),
          child: Icon(
            icon,
            color: onPressed != null ? color : color.withOpacity(0.5),
            size: 16.sp,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyInventoryState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 80.sp,
            color: AppColors.textSecondary.withOpacity(0.5),
          ),
          SizedBox(height: 16.h),
          Text('No Items Available', style: AppTextStyles.emptyStateTitle),
          SizedBox(height: 8.h),
          Text(
            'Add items to inventory to start selling',
            style: AppTextStyles.emptyStateSubtitle,
          ),
        ],
      ),
    );
  }

  void _updateQuantity(InventoryItem item, int newQuantity) {
    setState(() {
      if (newQuantity <= 0) {
        selectedItems.removeWhere((sItem) => sItem.item.id == item.id);
      } else if (newQuantity <= item.quantity) {
        final existingIndex = selectedItems.indexWhere(
          (sItem) => sItem.item.id == item.id,
        );
        if (existingIndex >= 0) {
          selectedItems[existingIndex].quantity = newQuantity;
        } else {
          selectedItems.add(SaleItem(item: item, quantity: newQuantity));
        }
      }
    });
  }

  void _showSelectedItemsBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.backgroundLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder:
          (context) => Container(
            padding: EdgeInsets.all(20.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Selected Items', style: AppTextStyles.headingMedium),
                SizedBox(height: 16.h),
                ...selectedItems
                    .map(
                      (sItem) => ListTile(
                        title: Text(sItem.item.name),
                        subtitle: Text(
                          '₹${sItem.item.price} × ${sItem.quantity}',
                        ),
                        trailing: Text(
                          '₹${sItem.totalPrice.toStringAsFixed(2)}',
                        ),
                      ),
                    )
                    .toList(),
              ],
            ),
          ),
    );
  }

  void _proceedToSale() {
    if (selectedItems.isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => SaleSummaryScreen(
              shop: widget.shop,
              saleItems: List.from(selectedItems),
              customerName: _customerNameController.text.trim(),
              customerPhone: _customerPhoneController.text.trim(),
            ),
      ),
    );
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    super.dispose();
  }
}
