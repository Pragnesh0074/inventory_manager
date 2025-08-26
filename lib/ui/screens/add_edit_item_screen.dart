import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../models/inventory_item.dart';
import '../../models/shop.dart';
import '../../providers/shop_provider.dart';
import '../../theme/color.dart';
import '../../theme/style.dart';
import '../../models/purchase.dart';

class AddEditItemScreen extends StatefulWidget {
  final Shop shop;
  final InventoryItem? item;

  const AddEditItemScreen({super.key, required this.shop, this.item});

  @override
  _AddEditItemScreenState createState() => _AddEditItemScreenState();
}

class _AddEditItemScreenState extends State<AddEditItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController();
  final _partyNameController = TextEditingController();
  final _partyAddressController = TextEditingController();
  final _purchasePriceController = TextEditingController();
  final _totalPaymentController = TextEditingController();
  final _paidAmountController = TextEditingController();
  final _nameFocusNode = FocusNode();
  final _priceFocusNode = FocusNode();
  final _quantityFocusNode = FocusNode();
  final _partyNameFocusNode = FocusNode();
  final _partyAddressFocusNode = FocusNode();
  final _purchasePriceFocusNode = FocusNode();
  final _totalPaymentFocusNode = FocusNode();
  final _paidAmountFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    if (widget.item != null) {
      _nameController.text = widget.item!.name;
      _priceController.text = widget.item!.price.toString();
      _quantityController.text = widget.item!.quantity.toString();
    }
    // Update total payment display when qty or purchase price changes
    _quantityController.addListener(_onPriceOrQtyChanged);
    _purchasePriceController.addListener(_onPriceOrQtyChanged);
  }

  void _onPriceOrQtyChanged() {
    if (mounted) setState(() {});
  }

  double _calculateTotalPayment() {
    final qty = int.tryParse(_quantityController.text) ?? 0;
    final buyPrice = double.tryParse(_purchasePriceController.text) ?? 0.0;
    return qty * buyPrice;
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.item != null;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          isEditing ? 'Edit Item' : 'Add Item',
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
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Card
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(12.r),
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
                          size: 35.sp,
                          color: AppColors.textOnPrimary,
                        ),
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        isEditing ? 'Edit Item Details' : 'Add New Item',
                        style: AppTextStyles.headingMedium,
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        isEditing
                            ? 'Update your inventory item information'
                            : 'Fill in the details to add item to ${widget.shop.name}',
                        style: AppTextStyles.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20.h),

                // Item Information Card
                Container(
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
                      Text(
                        'Item Information',
                        style: AppTextStyles.headingMedium,
                      ),
                      SizedBox(height: 20.h),

                      // Item Name Field
                      _buildInputField(
                        controller: _nameController,
                        focusNode: _nameFocusNode,
                        label: 'Item Name',
                        hint: 'Enter item name',
                        icon: Icons.inventory_outlined,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter item name';
                          }
                          if (value.length < 2) {
                            return 'Item name must be at least 2 characters';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 20.h),

                      // Price and Quantity Row
                      Row(
                        children: [
                          // Price Field
                          Expanded(
                            child: _buildInputField(
                              controller: _priceController,
                              focusNode: _priceFocusNode,
                              label: 'Selling Price',
                              hint: '0.00',
                              icon: Icons.currency_rupee_rounded,
                              keyboardType: TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter price';
                                }
                                if (double.tryParse(value) == null ||
                                    double.parse(value) <= 0) {
                                  return 'Please enter valid price';
                                }
                                return null;
                              },
                            ),
                          ),
                          SizedBox(width: 16.w),
                          // Quantity Field
                          Expanded(
                            child: _buildInputField(
                              controller: _quantityController,
                              focusNode: _quantityFocusNode,
                              label: 'Quantity',
                              hint: '0',
                              icon: Icons.format_list_numbered_outlined,
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter quantity';
                                }
                                if (int.tryParse(value) == null ||
                                    int.parse(value) < 0) {
                                  return 'Please enter valid quantity';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20.h),

                // Purchase Details (optional on create; hidden on edit unless needed)
                Container(
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
                      Text(
                        'Purchase Details',
                        style: AppTextStyles.headingMedium,
                      ),
                      SizedBox(height: 20.h),
                      _buildInputField(
                        controller: _partyNameController,
                        focusNode: _partyNameFocusNode,
                        label: 'Party Name (Supplier)',
                        hint: 'Enter supplier name',
                        icon: Icons.person_outline,
                        validator: (value) {
                          // optional, allow empty
                          return null;
                        },
                      ),
                      SizedBox(height: 16.h),
                      _buildInputField(
                        controller: _partyAddressController,
                        focusNode: _partyAddressFocusNode,
                        label: 'Party Address',
                        hint: 'Enter supplier address',
                        icon: Icons.location_on_outlined,
                        validator: (value) {
                          return null;
                        },
                        maxLines: 2,
                      ),
                      SizedBox(height: 16.h),
                      Row(
                        children: [
                          Expanded(
                            child: _buildInputField(
                              controller: _purchasePriceController,
                              focusNode: _purchasePriceFocusNode,
                              label: 'Purchase Unit Price',
                              hint: '0.00',
                              icon: Icons.currency_rupee_rounded,
                              keyboardType: TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return null; // optional
                                }
                                if (double.tryParse(value) == null ||
                                    double.parse(value) < 0) {
                                  return 'Invalid price';
                                }
                                return null;
                              },
                            ),
                          ),
                          SizedBox(width: 16.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Total Payment (Invoice)',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                SizedBox(height: 36.h),
                                Row(
                                  children: [
                                    Container(
                                      margin: EdgeInsets.only(right: 8.w),
                                      padding: EdgeInsets.all(8.w),
                                      decoration: BoxDecoration(
                                        color: AppColors.blueTinted,
                                        borderRadius: BorderRadius.circular(
                                          8.r,
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.receipt_long,
                                        color: AppColors.primaryBlue,
                                        size: 18.sp,
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        '₹${_calculateTotalPayment().toStringAsFixed(2)}',
                                        style: AppTextStyles.headingMedium,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16.h),
                      _buildInputField(
                        controller: _paidAmountController,
                        focusNode: _paidAmountFocusNode,
                        label: 'Paid Amount',
                        hint: '0.00',
                        icon: Icons.payments_outlined,
                        keyboardType: TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) return null;
                          final v = double.tryParse(value);
                          if (v == null || v < 0) return 'Invalid amount';
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20.h),

                // Action Buttons
                Container(
                  width: double.infinity,
                  height: 56.h,
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
                  child: ElevatedButton(
                    onPressed: _saveItem,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isEditing ? Icons.update : Icons.add_box,
                          color: AppColors.textOnPrimary,
                          size: 24.sp,
                        ),
                        SizedBox(width: 12.w),
                        Text(
                          isEditing ? 'Update Item' : 'Add Item',
                          style: AppTextStyles.buttonLarge,
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16.h),

                // Cancel Button
                SizedBox(
                  width: double.infinity,
                  height: 56.h,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      backgroundColor: AppColors.surfaceLight,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          decoration: BoxDecoration(
            color: AppColors.backgroundLight,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color:
                  focusNode.hasFocus
                      ? AppColors.primaryBlue
                      : Colors.transparent,
              width: 2.w,
            ),
          ),
          child: TextFormField(
            onTapOutside: (_) => FocusScope.of(context).unfocus(),
            controller: controller,
            focusNode: focusNode,
            keyboardType: keyboardType,
            maxLines: maxLines,
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.textHint,
              ),
              prefixIcon: Container(
                margin: EdgeInsets.all(12.w),
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: AppColors.blueTinted,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(icon, color: AppColors.primaryBlue, size: 20.sp),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide.none,
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(color: AppColors.error, width: 1.w),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(color: AppColors.error, width: 2.w),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: 16.h,
              ),
              errorStyle: TextStyle(
                color: AppColors.error,
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
            validator: validator,
            onTap: () => setState(() {}),
            onEditingComplete: () => setState(() {}),
          ),
        ),
      ],
    );
  }

  void _saveItem() {
    if (_formKey.currentState!.validate()) {
      final shopProvider = Provider.of<ShopProvider>(context, listen: false);

      if (widget.item != null) {
        // Update existing item
        final updatedItem = InventoryItem(
          id: widget.item!.id,
          name: _nameController.text.trim(),
          price: double.parse(_priceController.text),
          quantity: int.parse(_quantityController.text),
          createdDate: widget.item!.createdDate,
          stockEntries: widget.item!.stockEntries,
        );
        shopProvider.updateInventoryItem(widget.shop.id, updatedItem);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Item updated successfully!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
        );
      } else {
        // Create new item
        final newItem = InventoryItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: _nameController.text.trim(),
          price: double.parse(_priceController.text),
          quantity: int.parse(_quantityController.text),
          createdDate: DateTime.now(),
        );
        shopProvider.addInventoryItem(widget.shop.id, newItem);

        // If purchase details provided, record purchase
        final qty = int.tryParse(_quantityController.text) ?? 0;
        final unitPurchasePrice = double.tryParse(
          _purchasePriceController.text,
        );
        final totalPayment =
            (unitPurchasePrice != null ? unitPurchasePrice * qty : 0.0);
        final paidAmount = double.tryParse(_paidAmountController.text) ?? 0.0;
        if (qty > 0 && unitPurchasePrice != null) {
          shopProvider.recordPurchase(
            shopId: widget.shop.id,
            item: newItem,
            quantity: qty,
            unitPurchasePrice: unitPurchasePrice,
            partyName: _partyNameController.text.trim(),
            partyAddress: _partyAddressController.text.trim(),
            totalPayment: totalPayment,
            paidAmount: paidAmount,
          );
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Item added successfully!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
        );
      }

      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _partyNameController.dispose();
    _partyAddressController.dispose();
    _purchasePriceController.dispose();
    _paidAmountController.dispose();
    _nameFocusNode.dispose();
    _priceFocusNode.dispose();
    _quantityFocusNode.dispose();
    _partyNameFocusNode.dispose();
    _partyAddressFocusNode.dispose();
    _purchasePriceFocusNode.dispose();
    _paidAmountFocusNode.dispose();
    super.dispose();
  }
}
