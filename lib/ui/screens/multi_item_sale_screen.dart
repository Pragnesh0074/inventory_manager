import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../models/inventory_item.dart';
import '../../models/shop.dart';
import '../../models/sale_order.dart' as order_models;
import '../../models/customer.dart';
import '../../providers/shop_provider.dart';
import '../../theme/color.dart';
import '../../theme/style.dart';

import 'sale_summary_screen.dart';

class SaleItem {
  final InventoryItem? item; // Can be null for temporary items
  final String? temporaryItemName; // Name for temporary items
  final double? temporaryItemPrice; // Price for temporary items
  int quantity;
  double? temporaryPrice; // Temporary price override for this sale
  String? description; // Optional description for this sale

  SaleItem({
    this.item,
    this.temporaryItemName,
    this.temporaryItemPrice,
    this.quantity = 1,
    this.temporaryPrice,
    this.description,
  }) : assert(
         (item != null) ||
             (temporaryItemName != null && temporaryItemPrice != null),
         'Either item or temporary item details must be provided',
       );

  // Check if this is a temporary item (not in inventory)
  bool get isTemporaryItem => item == null;

  // Get the item name
  String get itemName => item?.name ?? temporaryItemName!;

  // Get the base price (from inventory item or temporary item)
  double get basePrice => item?.price ?? temporaryItemPrice!;

  // Use temporary price if set, otherwise use original item price
  double get unitPrice => temporaryPrice ?? basePrice;

  double get totalPrice => unitPrice * quantity;

  // Check if price has been modified
  bool get isPriceModified =>
      temporaryPrice != null && temporaryPrice != basePrice;

  // Get the price difference (positive if increased, negative if decreased)
  double get priceDifference => (temporaryPrice ?? basePrice) - basePrice;
}

class MultiItemSaleScreen extends StatefulWidget {
  final Shop shop;

  const MultiItemSaleScreen({super.key, required this.shop});

  @override
  _MultiItemSaleScreenState createState() => _MultiItemSaleScreenState();
}

class _MultiItemSaleScreenState extends State<MultiItemSaleScreen> {
  List<SaleItem> selectedItems = [];
  List<order_models.AdditionalCharge> additionalCharges = [];
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _customerPhoneController =
      TextEditingController();

  List<Customer> customerSuggestions = [];
  bool showCustomerSuggestions = false;
  bool customerSaved = false;

  @override
  void initState() {
    super.initState();
    _loadCustomerSuggestions();
    _customerNameController.addListener(_onCustomerNameChanged);
  }

  Future<void> _loadCustomerSuggestions() async {
    try {
      final shopProvider = Provider.of<ShopProvider>(context, listen: false);
      final customers = await shopProvider.getCustomers(widget.shop.id);
      setState(() {
        customerSuggestions = customers;
      });
    } catch (e) {
      // Handle error silently
    }
  }

  void _onCustomerNameChanged() {
    final query = _customerNameController.text.toLowerCase();

    if (customerSaved) {
      setState(() {
        customerSaved = false;
      });
    }

    if (query.isEmpty) {
      setState(() {
        showCustomerSuggestions = false;
      });
      return;
    }

    final filtered =
        customerSuggestions
            .where(
              (customer) =>
                  customer.name.toLowerCase().contains(query) ||
                  customer.phone.contains(query),
            )
            .toList();

    setState(() {
      showCustomerSuggestions = filtered.isNotEmpty;
    });
  }

  Future<void> _saveCustomerIfNew() async {
    final customerName = _customerNameController.text.trim();
    final customerPhone = _customerPhoneController.text.trim();

    if (customerName.isNotEmpty && customerPhone.isNotEmpty) {
      try {
        final shopProvider = Provider.of<ShopProvider>(context, listen: false);

        // Check if customer already exists
        var existingCustomer = await shopProvider.getCustomerByPhone(
          widget.shop.id,
          customerPhone,
        );

        if (existingCustomer == null) {
          // Create new customer
          final newCustomer = Customer(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            shopId: widget.shop.id,
            name: customerName,
            phone: customerPhone,
            createdAt: DateTime.now(),
            lastUpdated: DateTime.now(),
          );

          await shopProvider.insertCustomer(widget.shop.id, newCustomer);

          // Refresh customer suggestions
          await _loadCustomerSuggestions();

          // Show success message
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('New customer "$customerName" saved!'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
          }
          setState(() {
            customerSaved = true;
          });
        } else {
          // Show message that customer already exists
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Customer "$customerName" already exists!'),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          String errorMessage = 'Error saving customer';
          if (e.toString().contains('created_at')) {
            errorMessage =
                'Database needs to be updated. Please restart the app and try again.';
          } else {
            errorMessage = 'Error saving customer: $e';
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
              action: SnackBarAction(
                label: 'Restart App',
                textColor: Colors.white,
                onPressed: () {
                  // This will close the app, user needs to manually restart
                  SystemNavigator.pop();
                },
              ),
            ),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please enter both customer name and phone number'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  void _selectCustomer(Customer customer) {
    setState(() {
      _customerNameController.text = customer.name;
      _customerPhoneController.text = customer.phone;
      showCustomerSuggestions = false;
      customerSaved = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: Text(
          'CREATE SALE',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: const Color(0xFFF5F6FA),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Container(
            padding: EdgeInsets.all(8.r),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.arrow_back_ios_new,
              color: Colors.black87,
              size: 18.r,
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (selectedItems.isNotEmpty)
            Container(
              margin: EdgeInsets.only(right: 16.w),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.shopping_cart,
                      color: Colors.orange,
                      size: 24,
                    ),
                    onPressed: () => _showSelectedItemsBottomSheet(),
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
                // Shop Info Header
                Container(
                  margin: EdgeInsets.all(16.r),
                  padding: EdgeInsets.all(20.r),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE5B8),
                    borderRadius: BorderRadius.circular(20.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withOpacity(0.2),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.store, color: Colors.black, size: 24.r),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.shop.name,
                              style: TextStyle(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            Text(
                              '${currentShop.inventory.length} items available',
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Customer Info Card
                _buildCustomerInfoCard(),

                // Selected Items Summary (if any)
                if (selectedItems.isNotEmpty) _buildSelectedItemsSummary(),

                // Quick Actions
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(12.r),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: TextButton.icon(
                            onPressed: _addTemporaryItem,
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 12.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                            ),
                            icon: const Icon(
                              Icons.add_shopping_cart,
                              color: Colors.white,
                              size: 18,
                            ),
                            label: Text(
                              'ADD CUSTOM ITEM',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 16.h),

                // Temporary Items List (if any)
                if (selectedItems
                    .where((item) => item.isTemporaryItem)
                    .isNotEmpty)
                  _buildTemporaryItemsList(),

                // Available Items List
                _buildInventoryList(currentShop),

                SizedBox(height: 100.h), // Bottom padding for FAB
              ],
            ),
          );
        },
      ),
      floatingActionButton:
          selectedItems.isNotEmpty
              ? Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF4A90E2),
                  borderRadius: BorderRadius.circular(20.r),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4A90E2).withOpacity(0.4),
                      blurRadius: 15,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: FloatingActionButton.extended(
                  onPressed: _proceedToSale,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  icon: const Icon(Icons.point_of_sale, color: Colors.white),
                  label: Text(
                    'PROCEED TO SALE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              )
              : null,
    );
  }

  Widget _buildCustomerInfoCard() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            spreadRadius: 1,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.r),
                decoration: BoxDecoration(
                  color: const Color(0xFF4A90E2).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  Icons.person_outline,
                  color: const Color(0xFF4A90E2),
                  size: 20.r,
                ),
              ),
              SizedBox(width: 12.w),
              Text(
                'Customer Information',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
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
                  icon: Icons.person_outline,
                  showSuggestions: true,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildCustomerField(
                  controller: _customerPhoneController,
                  label: 'Phone Number',
                  hint: 'Enter phone (optional)',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                ),
              ),
            ],
          ),
          if (showCustomerSuggestions) _buildCustomerSuggestions(),
          SizedBox(height: 16.h),
          if (!customerSaved)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _saveCustomerIfNew,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    icon: Icon(Icons.save, size: 18.r),
                    label: Text(
                      'Save Customer',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
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

  Widget _buildCustomerField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    bool showSuggestions = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          height: 48.h,
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: Colors.grey.withOpacity(0.2)),
          ),
          child: TextField(
            onTapOutside: (_) => FocusScope.of(context).unfocus,
            controller: controller,
            keyboardType: keyboardType,
            style: TextStyle(fontSize: 14.sp, color: Colors.black87),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(fontSize: 14.sp, color: Colors.grey[500]),
              prefixIcon: Icon(icon, color: Colors.grey[600], size: 18.r),
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

  Widget _buildCustomerSuggestions() {
    final query = _customerNameController.text.toLowerCase();
    final filtered =
        customerSuggestions
            .where(
              (customer) =>
                  customer.name.toLowerCase().contains(query) ||
                  customer.phone.contains(query),
            )
            .toList();

    return Container(
      margin: EdgeInsets.only(top: 8.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          final customer = filtered[index];
          return ListTile(
            leading: Icon(Icons.person, color: AppColors.primaryBlue),
            title: Text(
              customer.name,
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500),
            ),
            subtitle: Text(
              customer.phone,
              style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
            ),
            onTap: () => _selectCustomer(customer),
          );
        },
      ),
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
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: const Color(0xFF4A90E2),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4A90E2).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${selectedItems.length} Items Selected',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Total Quantity: $totalItems pcs',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (_totalAdditionalCharges > 0) ...[
                    Text(
                      '₹${itemsTotal.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.white.withOpacity(0.9),
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  ],
                  Text(
                    '₹${totalAmount.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),

          if (additionalCharges.isNotEmpty) ...[
            SizedBox(height: 12.h),
            Container(
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Additional Charges:',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  ...additionalCharges
                      .map(
                        (charge) => Padding(
                          padding: EdgeInsets.only(bottom: 4.h),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                charge.name,
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                              Row(
                                children: [
                                  Text(
                                    '₹${charge.amount.toStringAsFixed(0)}',
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      color: Colors.white.withOpacity(0.9),
                                    ),
                                  ),
                                  SizedBox(width: 8.w),
                                  GestureDetector(
                                    onTap:
                                        () =>
                                            _removeAdditionalCharge(charge.id),
                                    child: Container(
                                      padding: EdgeInsets.all(2.r),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(
                                          4.r,
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.close,
                                        size: 14.r,
                                        color: Colors.white,
                                      ),
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
          GestureDetector(
            onTap: _addAdditionalCharge,
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 8.h),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add, color: Colors.white, size: 16.r),
                  SizedBox(width: 8.w),
                  Text(
                    'Add Additional Charge',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemporaryItemsList() {
    final temporaryItems =
        selectedItems.where((item) => item.isTemporaryItem).toList();

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(6.r),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Icon(
                        Icons.add_circle_outline,
                        color: Colors.orange[600],
                        size: 18.r,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      'Custom Items',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Text(
                        '${temporaryItems.length}',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange[600],
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: temporaryItems.length,
                  separatorBuilder: (context, index) => SizedBox(height: 12.h),
                  itemBuilder: (context, index) {
                    final saleItem = temporaryItems[index];
                    return _buildTemporaryItemCard(saleItem);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemporaryItemCard(SaleItem saleItem) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.orange.withOpacity(0.3), width: 1.w),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  saleItem.itemName,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  '₹${saleItem.unitPrice.toStringAsFixed(0)} each',
                  style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
                ),
              ],
            ),
          ),

          Expanded(
            flex: 3,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildQuantityButton(
                      icon: Icons.remove,
                      onPressed:
                          () => _updateTemporaryItemQuantity(
                            saleItem,
                            saleItem.quantity - 1,
                          ),
                      color: Colors.red[400]!,
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 6.h,
                      ),
                      margin: EdgeInsets.symmetric(horizontal: 8.w),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(
                          color: Colors.orange.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        '${saleItem.quantity}',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[700],
                        ),
                      ),
                    ),
                    _buildQuantityButton(
                      icon: Icons.add,
                      onPressed:
                          () => _updateTemporaryItemQuantity(
                            saleItem,
                            saleItem.quantity + 1,
                          ),
                      color: Colors.green[400]!,
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                Text(
                  '₹${saleItem.totalPrice.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[600],
                  ),
                ),
                SizedBox(height: 8.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () => _editTemporaryItem(saleItem),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4A90E2).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.edit,
                              size: 12.r,
                              color: const Color(0xFF4A90E2),
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              'Edit',
                              style: TextStyle(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF4A90E2),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    GestureDetector(
                      onTap: () => _removeTemporaryItem(saleItem),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.delete,
                              size: 12.r,
                              color: Colors.red[400],
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              'Remove',
                              style: TextStyle(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.red[400],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
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
          Container(
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16.r),
                topRight: Radius.circular(16.r),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.r),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE5B8),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(
                    Icons.inventory_2_outlined,
                    color: const Color(0xFFFF9500),
                    size: 20.r,
                  ),
                ),
                SizedBox(width: 12.w),
                Text(
                  'Available Inventory',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4A90E2).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    '${shop.inventory.length} items',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF4A90E2),
                    ),
                  ),
                ),
              ],
            ),
          ),

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: shop.inventory.length,
            separatorBuilder: (context, index) => SizedBox(height: 1.h),
            itemBuilder: (context, index) {
              final item = shop.inventory[index];
              final selectedItem = selectedItems.firstWhere(
                (sItem) => sItem.item?.id == item.id,
                orElse: () => SaleItem(item: item, quantity: 0),
              );
              final isSelected = selectedItem.quantity > 0;

              return _buildInventoryItemCard(
                item,
                selectedItem,
                isSelected,
                index == shop.inventory.length - 1,
              );
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
    bool isLast,
  ) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            isLast
                ? BorderRadius.only(
                  bottomLeft: Radius.circular(16.r),
                  bottomRight: Radius.circular(16.r),
                )
                : BorderRadius.zero,
        border:
            isSelected
                ? Border.all(color: const Color(0xFF4A90E2), width: 2.w)
                : Border(
                  bottom: BorderSide(
                    color: Colors.grey.withOpacity(0.1),
                    width: 1.w,
                  ),
                ),
      ),
      child: Row(
        children: [
          // Item Icon
          Container(
            width: 48.w,
            height: 48.h,
            decoration: BoxDecoration(
              color:
                  isSelected
                      ? const Color(0xFF4A90E2).withOpacity(0.1)
                      : const Color(0xFFFFE5B8),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              isSelected ? Icons.check_circle : Icons.circle_outlined,
              color:
                  isSelected
                      ? const Color(0xFF4A90E2)
                      : const Color(0xFFFF9500),
              size: 24.r,
            ),
          ),

          SizedBox(width: 16.w),

          // Item Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 4.h),
                Row(
                  children: [
                    Text(
                      '₹${selectedItem.unitPrice.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF4A90E2),
                      ),
                    ),
                    if (selectedItem.isPriceModified) ...[
                      SizedBox(width: 4.w),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 4.w,
                          vertical: 2.h,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: Text(
                          'EDITED',
                          style: TextStyle(
                            fontSize: 8.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange[700],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  'Stock: ${item.quantity} pcs',
                  style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
                ),
              ],
            ),
          ),

          // Quantity Controls or Add Button
          if (isSelected) ...[
            Column(
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildQuantityButton(
                      icon: Icons.remove,
                      onPressed:
                          () =>
                              _updateQuantity(item, selectedItem.quantity - 1),
                      color: Colors.red[400]!,
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 6.h,
                      ),
                      margin: EdgeInsets.symmetric(horizontal: 8.w),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4A90E2).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(
                          color: const Color(0xFF4A90E2).withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        '${selectedItem.quantity}',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF4A90E2),
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
                      color: Colors.green[400]!,
                    ),
                  ],
                ),
                SizedBox(height: 6.h),
                Text(
                  '₹${selectedItem.totalPrice.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF4A90E2),
                  ),
                ),
                SizedBox(height: 4.h),
                GestureDetector(
                  onTap: () => _editItemPrice(selectedItem),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 2.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Text(
                      'Edit Details',
                      style: TextStyle(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            Container(
              decoration: BoxDecoration(
                color: item.quantity > 0 ? Colors.black87 : Colors.grey[300],
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: IconButton(
                onPressed:
                    item.quantity > 0 ? () => _updateQuantity(item, 1) : null,
                icon: Icon(
                  Icons.add,
                  color: item.quantity > 0 ? Colors.white : Colors.grey[500],
                  size: 20.r,
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
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 32.w,
        height: 32.h,
        decoration: BoxDecoration(
          color:
              onPressed != null
                  ? color.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color:
                onPressed != null
                    ? color.withOpacity(0.3)
                    : Colors.grey.withOpacity(0.3),
          ),
        ),
        child: Icon(
          icon,
          color: onPressed != null ? color : Colors.grey[400],
          size: 16.r,
        ),
      ),
    );
  }

  Widget _buildEmptyInventoryState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120.w,
            height: 120.h,
            decoration: BoxDecoration(
              color: const Color(0xFFFFE5B8),
              borderRadius: BorderRadius.circular(24.r),
            ),
            child: Icon(
              Icons.inventory_2_outlined,
              size: 48.r,
              color: const Color(0xFFFF9500),
            ),
          ),
          SizedBox(height: 24.h),
          Text(
            'No Items Available',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Add items to inventory to start selling',
            style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  void _updateQuantity(InventoryItem item, int newQuantity) {
    setState(() {
      final index = selectedItems.indexWhere((si) => si.item?.id == item.id);
      if (index != -1) {
        if (newQuantity <= 0) {
          selectedItems.removeAt(index);
        } else {
          final existingItem = selectedItems[index];
          selectedItems[index] = SaleItem(
            item: item,
            quantity: newQuantity,
            temporaryPrice: existingItem.temporaryPrice,
            description: existingItem.description,
          );
        }
      } else if (newQuantity > 0) {
        selectedItems.add(SaleItem(item: item, quantity: newQuantity));
      }
    });
  }

  void _updateTemporaryItemQuantity(SaleItem saleItem, int newQuantity) {
    setState(() {
      if (newQuantity <= 0) {
        selectedItems.remove(saleItem);
      } else {
        final index = selectedItems.indexOf(saleItem);
        if (index >= 0) {
          selectedItems[index] = SaleItem(
            temporaryItemName: saleItem.temporaryItemName,
            temporaryItemPrice: saleItem.temporaryItemPrice,
            quantity: newQuantity,
            temporaryPrice: saleItem.temporaryPrice,
          );
        }
      }
    });
  }

  void _removeTemporaryItem(SaleItem saleItem) {
    setState(() {
      selectedItems.remove(saleItem);
    });
  }

  void _editItemPrice(SaleItem saleItem) {
    final TextEditingController priceController = TextEditingController(
      text: saleItem.unitPrice.toStringAsFixed(2),
    );
    final TextEditingController descriptionController = TextEditingController(
      text: saleItem.description ?? '',
    );

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.r),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Edit Price & Description',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  saleItem.itemName,
                  style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Original Price: ₹${saleItem.basePrice.toStringAsFixed(0)}',
                  style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
                ),
                SizedBox(height: 16.h),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: Colors.grey.withOpacity(0.2)),
                  ),
                  child: TextField(
                    onTapOutside: (_) => FocusScope.of(context).unfocus,
                    controller: priceController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    decoration: InputDecoration(
                      labelText: 'New Price',
                      prefixText: '₹',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(16.r),
                    ),
                  ),
                ),
                SizedBox(height: 16.h),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: Colors.grey.withOpacity(0.2)),
                  ),
                  child: TextField(
                    onTapOutside: (_) => FocusScope.of(context).unfocus,
                    controller: descriptionController,
                    maxLines: 2,
                    style: TextStyle(fontSize: 14.sp, color: Colors.black87),
                    decoration: InputDecoration(
                      labelText: 'Description (Optional)',
                      hintText: 'Add item description for bill',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(16.r),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    saleItem.temporaryPrice = null;
                    saleItem.description = null;
                  });
                  Navigator.pop(context);
                },
                child: Text(
                  'Reset',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.orange[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF4A90E2),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: TextButton(
                  onPressed: () {
                    final newPrice = double.tryParse(priceController.text);
                    if (newPrice != null && newPrice > 0) {
                      setState(() {
                        saleItem.temporaryPrice = newPrice;
                        saleItem.description =
                            descriptionController.text.trim().isEmpty
                                ? null
                                : descriptionController.text.trim();
                      });
                      Navigator.pop(context);
                    }
                  },
                  child: Text(
                    'Save',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
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
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.r),
            ),
            title: Text(
              'Add Additional Charge',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: Colors.grey.withOpacity(0.2)),
                  ),
                  child: TextField(
                    onTapOutside: (_) => FocusScope.of(context).unfocus,
                    controller: nameController,
                    style: TextStyle(fontSize: 16.sp),
                    decoration: InputDecoration(
                      labelText: 'Charge Name',
                      hintText: 'e.g., Delivery, Packaging, etc.',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(16.r),
                    ),
                  ),
                ),
                SizedBox(height: 16.h),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: Colors.grey.withOpacity(0.2)),
                  ),
                  child: TextField(
                    onTapOutside: (_) => FocusScope.of(context).unfocus,
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    style: TextStyle(fontSize: 16.sp),
                    decoration: InputDecoration(
                      labelText: 'Amount',
                      prefixText: '₹',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(16.r),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF4A90E2),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: TextButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    final amount = double.tryParse(amountController.text);
                    if (name.isNotEmpty && amount != null && amount > 0) {
                      setState(() {
                        additionalCharges.add(
                          order_models.AdditionalCharge(
                            name: name,
                            amount: amount,
                          ),
                        );
                      });
                      Navigator.pop(context);
                    }
                  },
                  child: Text(
                    'Add',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
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

  void _addTemporaryItem() {
    _showTemporaryItemDialog();
  }

  void _editTemporaryItem(SaleItem saleItem) {
    _showTemporaryItemDialog(saleItem: saleItem);
  }

  void _showTemporaryItemDialog({SaleItem? saleItem}) {
    final TextEditingController nameController = TextEditingController(
      text: saleItem?.temporaryItemName ?? '',
    );
    final TextEditingController priceController = TextEditingController(
      text: saleItem?.temporaryItemPrice?.toString() ?? '',
    );
    final TextEditingController quantityController = TextEditingController(
      text: saleItem?.quantity.toString() ?? '1',
    );
    final TextEditingController descriptionController = TextEditingController(
      text: saleItem?.description ?? '',
    );

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.r),
            ),
            title: Text(
              saleItem != null ? 'Edit Custom Item' : 'Add Custom Item',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: Colors.grey.withOpacity(0.2)),
                    ),
                    child: TextField(
                      onTapOutside: (_) => FocusScope.of(context).unfocus,
                      controller: nameController,
                      style: TextStyle(fontSize: 16.sp),
                      decoration: InputDecoration(
                        labelText: 'Item Name',
                        hintText: 'Enter item name',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(16.r),
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8F9FA),
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                              color: Colors.grey.withOpacity(0.2),
                            ),
                          ),
                          child: TextField(
                            onTapOutside: (_) => FocusScope.of(context).unfocus,
                            controller: priceController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            style: TextStyle(fontSize: 16.sp),
                            decoration: InputDecoration(
                              labelText: 'Price',
                              prefixText: '₹',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.all(16.r),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8F9FA),
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                              color: Colors.grey.withOpacity(0.2),
                            ),
                          ),
                          child: TextField(
                            onTapOutside: (_) => FocusScope.of(context).unfocus,
                            controller: quantityController,
                            keyboardType: TextInputType.number,
                            style: TextStyle(fontSize: 16.sp),
                            decoration: InputDecoration(
                              labelText: 'Quantity',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.all(16.r),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: Colors.grey.withOpacity(0.2)),
                    ),
                    child: TextField(
                      onTapOutside: (_) => FocusScope.of(context).unfocus,
                      controller: descriptionController,
                      maxLines: 2,
                      style: TextStyle(fontSize: 14.sp),
                      decoration: InputDecoration(
                        labelText: 'Description (Optional)',
                        hintText: 'Add item description for bill',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(16.r),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
                ),
              ),
              if (saleItem != null) ...[
                TextButton(
                  onPressed: () {
                    setState(() {
                      selectedItems.remove(saleItem);
                    });
                    Navigator.pop(context);
                  },
                  child: Text(
                    'Delete',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.red[400],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF4A90E2),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: TextButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    final price = double.tryParse(priceController.text);
                    final quantity = int.tryParse(quantityController.text) ?? 1;
                    final description = descriptionController.text.trim();

                    if (name.isNotEmpty &&
                        price != null &&
                        price > 0 &&
                        quantity > 0) {
                      setState(() {
                        if (saleItem != null) {
                          final index = selectedItems.indexOf(saleItem);
                          selectedItems[index] = SaleItem(
                            temporaryItemName: name,
                            temporaryItemPrice: price,
                            quantity: quantity,
                            description:
                                description.isEmpty ? null : description,
                          );
                        } else {
                          selectedItems.add(
                            SaleItem(
                              temporaryItemName: name,
                              temporaryItemPrice: price,
                              quantity: quantity,
                              description:
                                  description.isEmpty ? null : description,
                            ),
                          );
                        }
                      });
                      Navigator.pop(context);
                    }
                  },
                  child: Text(
                    saleItem != null ? 'Update' : 'Add',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
    );
  }

  void _showSelectedItemsBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder:
          (context) => Container(
            padding: EdgeInsets.all(24.r),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8.r),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4A90E2).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(
                        Icons.shopping_cart,
                        color: const Color(0xFF4A90E2),
                        size: 20.r,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Text(
                      'Selected Items',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20.h),
                ...selectedItems
                    .map(
                      (sItem) => Container(
                        margin: EdgeInsets.only(bottom: 12.h),
                        padding: EdgeInsets.all(12.r),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F9FA),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    sItem.itemName,
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  Text(
                                    '₹${sItem.unitPrice.toStringAsFixed(0)} × ${sItem.quantity}',
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '₹${sItem.totalPrice.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF4A90E2),
                              ),
                            ),
                          ],
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

    final customerName = _customerNameController.text.trim();
    final customerPhone = _customerPhoneController.text.trim();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => SaleSummaryScreen(
              shop: widget.shop,
              saleItems: List.from(selectedItems),
              additionalCharges: List.from(additionalCharges),
              customerName: customerName,
              customerPhone: customerPhone,
            ),
      ),
    );
  }

  @override
  void dispose() {
    _customerNameController.removeListener(_onCustomerNameChanged);
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    super.dispose();
  }
}
