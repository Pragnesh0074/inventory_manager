import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../models/inventory_item.dart';
import '../../models/shop.dart';
import '../../providers/shop_provider.dart';
import '../../theme/color.dart';
import '../../theme/style.dart';
import 'sale_summary_screen.dart';

class AdditionalCharge {
  final String name;
  final double amount;
  final String id;

  AdditionalCharge({required this.name, required this.amount})
    : id = DateTime.now().millisecondsSinceEpoch.toString();

  double get totalAmount => amount;
}

class SaleItem {
  final InventoryItem item;
  int quantity;
  double? temporaryPrice; // Temporary price override for this sale

  SaleItem({required this.item, this.quantity = 1, this.temporaryPrice});

  // Use temporary price if set, otherwise use original item price
  double get unitPrice => temporaryPrice ?? item.price;

  double get totalPrice => unitPrice * quantity;

  // Check if price has been modified
  bool get isPriceModified =>
      temporaryPrice != null && temporaryPrice != item.price;

  // Get the price difference (positive if increased, negative if decreased)
  double get priceDifference => (temporaryPrice ?? item.price) - item.price;
}

class MultiItemSaleScreen extends StatefulWidget {
  final Shop shop;

  const MultiItemSaleScreen({super.key, required this.shop});

  @override
  _MultiItemSaleScreenState createState() => _MultiItemSaleScreenState();
}

class _MultiItemSaleScreenState extends State<MultiItemSaleScreen> {
  List<SaleItem> selectedItems = [];
  List<AdditionalCharge> additionalCharges = [];
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
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.shopping_cart,
                      color: AppColors.textOnPrimary,
                      size: 24.sp,
                    ),
                    onPressed: () => _showSelectedItemsBottomSheet(),
                  ),
                  SizedBox(width: 12.w),
                  IconButton(
                    icon: Icon(
                      Icons.point_of_sale,
                      color: AppColors.textOnPrimary,
                      size: 24.sp,
                    ),
                    onPressed: () => _proceedToSale(),
                  ),
                ],
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

          return SingleChildScrollView(
            child: Column(
              children: [
                // Customer Info Card
                _buildCustomerInfoCard(),

                // Selected Items Summary (if any)
                if (selectedItems.isNotEmpty) _buildSelectedItemsSummary(),

                // Available Items List
                _buildInventoryList(currentShop),
              ],
            ),
          );
        },
      ),
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
    final itemsTotal = selectedItems.fold(
      0.0,
      (sum, item) => sum + item.totalPrice,
    );
    final totalAmount = itemsTotal + _totalAdditionalCharges;
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹${itemsTotal.toStringAsFixed(2)}',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textOnPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (_totalAdditionalCharges > 0) ...[
                    Text(
                      '+ ₹${_totalAdditionalCharges.toStringAsFixed(2)} charges',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textOnPrimary.withOpacity(0.8),
                      ),
                    ),
                  ],
                  Text(
                    '₹${totalAmount.toStringAsFixed(2)}',
                    style: AppTextStyles.headingMedium.copyWith(
                      color: AppColors.textOnPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (additionalCharges.isNotEmpty) ...[
            SizedBox(height: 12.h),
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: AppColors.textOnPrimary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Additional Charges:',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textOnPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  ...additionalCharges
                      .map(
                        (charge) => Padding(
                          padding: EdgeInsets.only(bottom: 2.h),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                charge.name,
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textOnPrimary.withOpacity(
                                    0.9,
                                  ),
                                ),
                              ),
                              Row(
                                children: [
                                  Text(
                                    '₹${charge.amount.toStringAsFixed(2)}',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.textOnPrimary
                                          .withOpacity(0.9),
                                    ),
                                  ),
                                  SizedBox(width: 8.w),
                                  GestureDetector(
                                    onTap:
                                        () =>
                                            _removeAdditionalCharge(charge.id),
                                    child: Icon(
                                      Icons.close,
                                      size: 16.sp,
                                      color: AppColors.textOnPrimary
                                          .withOpacity(0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ],
              ),
            ),
          ],
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.textOnPrimary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: TextButton.icon(
                    onPressed: _addAdditionalCharge,
                    icon: Icon(
                      Icons.add,
                      color: AppColors.textOnPrimary,
                      size: 18.sp,
                    ),
                    label: Text(
                      'Add Charge',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textOnPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
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
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
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
                Row(
                  children: [
                    Text(
                      '₹${selectedItem.unitPrice.toStringAsFixed(2)} each',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color:
                            selectedItem.isPriceModified
                                ? AppColors.warning
                                : AppColors.success,
                      ),
                    ),
                    if (selectedItem.isPriceModified) ...[
                      SizedBox(width: 4.w),
                      Icon(Icons.edit, size: 14.sp, color: AppColors.warning),
                    ],
                  ],
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
                  SizedBox(height: 4.h),
                  GestureDetector(
                    onTap: () => _editItemPrice(selectedItem),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6.r),
                        border: Border.all(
                          color: AppColors.primaryBlue.withOpacity(0.3),
                          width: 1.w,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.edit,
                            size: 12.sp,
                            color: AppColors.primaryBlue,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            'Edit Price',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.primaryBlue,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
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

  void _editItemPrice(SaleItem saleItem) {
    final TextEditingController priceController = TextEditingController(
      text: saleItem.unitPrice.toStringAsFixed(2),
    );

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Edit Price - ${saleItem.item.name}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Original Price: ₹${saleItem.item.price.toStringAsFixed(2)}',
                ),
                SizedBox(height: 16.h),
                TextField(
                  controller: priceController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'New Price',
                    prefixText: '₹',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  final newPrice = double.tryParse(priceController.text);
                  if (newPrice != null && newPrice > 0) {
                    setState(() {
                      saleItem.temporaryPrice = newPrice;
                    });
                    Navigator.pop(context);
                  }
                },
                child: Text('Save'),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    saleItem.temporaryPrice = null; // Reset to original price
                  });
                  Navigator.pop(context);
                },
                child: Text('Reset'),
              ),
            ],
          ),
    );
  }

  void _addAdditionalCharge() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController amountController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Add Additional Charge'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Charge Name',
                    hintText: 'e.g., Delivery, Packaging, etc.',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16.h),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Amount',
                    prefixText: '₹',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  final name = nameController.text.trim();
                  final amount = double.tryParse(amountController.text);
                  if (name.isNotEmpty && amount != null && amount > 0) {
                    setState(() {
                      additionalCharges.add(
                        AdditionalCharge(name: name, amount: amount),
                      );
                    });
                    Navigator.pop(context);
                  }
                },
                child: Text('Add'),
              ),
            ],
          ),
    );
  }

  void _removeAdditionalCharge(String chargeId) {
    setState(() {
      additionalCharges.removeWhere((charge) => charge.id == chargeId);
    });
  }

  double get _totalAdditionalCharges =>
      additionalCharges.fold(0.0, (sum, charge) => sum + charge.totalAmount);

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
              additionalCharges: List.from(additionalCharges),
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
