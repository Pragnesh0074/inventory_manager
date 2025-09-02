import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../models/inventory_item.dart';
import '../../models/shop.dart';
import '../../providers/shop_provider.dart';
import '../../theme/color.dart';
import '../../theme/style.dart';
import '../../models/purchase.dart';
import '../../models/supplier.dart';
import '../../database/database_helper.dart';

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
  final _paidAmountController = TextEditingController();
  final _nameFocusNode = FocusNode();
  final _priceFocusNode = FocusNode();
  final _quantityFocusNode = FocusNode();
  final _partyNameFocusNode = FocusNode();
  final _partyAddressFocusNode = FocusNode();
  final _purchasePriceFocusNode = FocusNode();
  final _paidAmountFocusNode = FocusNode();

  late bool isEditing;

  List<Supplier> supplierSuggestions = [];
  bool showSupplierSuggestions = false;

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

    // Load supplier suggestions and add listener for party name
    _loadSupplierSuggestions();
    _partyNameController.addListener(_onPartyNameChanged);

    isEditing = widget.item != null;
  }

  Future<void> _loadSupplierSuggestions() async {
    try {
      final dbHelper = DatabaseHelper();
      final suppliers = await dbHelper.getSuppliers(widget.shop.id);
      setState(() {
        supplierSuggestions = suppliers;
      });
    } catch (e) {
      // Handle error silently
    }
  }

  void _onPartyNameChanged() {
    final query = _partyNameController.text.toLowerCase();
    if (query.isEmpty) {
      setState(() {
        showSupplierSuggestions = false;
      });
      return;
    }

    final filtered =
        supplierSuggestions
            .where((supplier) => supplier.name.toLowerCase().contains(query))
            .toList();

    setState(() {
      showSupplierSuggestions = filtered.isNotEmpty;
    });
  }

  void _selectSupplier(Supplier supplier) {
    setState(() {
      _partyNameController.text = supplier.name;
      if (supplier.address != null && supplier.address!.isNotEmpty) {
        _partyAddressController.text = supplier.address!;
      }
      showSupplierSuggestions = false;
    });
  }

  Widget _buildSupplierSuggestions() {
    final query = _partyNameController.text.toLowerCase();
    final filtered =
        supplierSuggestions
            .where((supplier) => supplier.name.toLowerCase().contains(query))
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
          final supplier = filtered[index];
          return ListTile(
            leading: Icon(Icons.business, color: AppColors.primaryBlue),
            title: Text(
              supplier.name,
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500),
            ),
            subtitle:
                supplier.address != null && supplier.address!.isNotEmpty
                    ? Text(
                      supplier.address!,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey[600],
                      ),
                    )
                    : null,
            onTap: () => _selectSupplier(supplier),
          );
        },
      ),
    );
  }

  Future<void> _saveSupplier(String name, String address) async {
    try {
      final dbHelper = DatabaseHelper();

      // Check if supplier already exists
      var existingSupplier = await dbHelper.getSupplierByName(
        widget.shop.id,
        name,
      );

      if (existingSupplier == null) {
        // Create new supplier
        final newSupplier = Supplier(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          shopId: widget.shop.id,
          name: name,
          address: address.isNotEmpty ? address : null,
          createdAt: DateTime.now(),
          lastUpdated: DateTime.now(),
        );

        await dbHelper.insertSupplier(newSupplier);

        // Refresh supplier suggestions
        await _loadSupplierSuggestions();
      }
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _saveSupplierIfNew() async {
    final partyName = _partyNameController.text.trim();
    final partyAddress = _partyAddressController.text.trim();

    if (partyName.isNotEmpty) {
      try {
        final dbHelper = DatabaseHelper();

        // Check if supplier already exists
        var existingSupplier = await dbHelper.getSupplierByName(
          widget.shop.id,
          partyName,
        );

        if (existingSupplier == null) {
          // Create new supplier
          final newSupplier = Supplier(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            shopId: widget.shop.id,
            name: partyName,
            address: partyAddress.isNotEmpty ? partyAddress : null,
            createdAt: DateTime.now(),
            lastUpdated: DateTime.now(),
          );

          await dbHelper.insertSupplier(newSupplier);

          // Refresh supplier suggestions
          await _loadSupplierSuggestions();

          // Show success message
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('New supplier "$partyName" saved!'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Supplier "$partyName" already exists!'),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          String errorMessage = 'Error saving supplier';
          if (e.toString().contains('created_at')) {
            errorMessage =
                'Database needs to be updated. Please restart the app and try again.';
          } else {
            errorMessage = 'Error saving supplier: $e';
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please enter supplier name'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
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
    return Scaffold(
      backgroundColor: Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Color(0xFFFDB462),
        elevation: 0,
        title: Text(
          isEditing ? 'EDIT ITEM' : 'ADD ITEM',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.black, size: 20.sp),
          onPressed: () => Navigator.pop(context),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(24.r)),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Item Information Card
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(20.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10.r,
                        offset: Offset(0, 2.h),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40.w,
                            height: 40.h,
                            decoration: BoxDecoration(
                              color: Color(0xFFFDB462),
                              borderRadius: BorderRadius.circular(20.r),
                            ),
                            child: Icon(
                              Icons.inventory_2_outlined,
                              color: Colors.black,
                              size: 20.sp,
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Text(
                            'Item Information',
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 24.h),

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
                SizedBox(height: 16.h),

                // Purchase Details Card
                isEditing
                    ? SizedBox()
                    : Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(20.w),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10.r,
                            offset: Offset(0, 2.h),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 40.w,
                                height: 40.h,
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade400,
                                  borderRadius: BorderRadius.circular(20.r),
                                ),
                                child: Icon(
                                  Icons.shopping_cart_outlined,
                                  color: Colors.white,
                                  size: 20.sp,
                                ),
                              ),
                              SizedBox(width: 12.w),
                              Text(
                                'Purchase Details',
                                style: TextStyle(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 24.h),

                          _buildInputField(
                            controller: _partyNameController,
                            focusNode: _partyNameFocusNode,
                            label: 'Supplier Name',
                            hint: 'Enter supplier name (optional)',
                            icon: Icons.person_outline,
                            validator: (value) => null,
                          ),
                          if (showSupplierSuggestions)
                            _buildSupplierSuggestions(),
                          SizedBox(height: 16.h),

                          _buildInputField(
                            controller: _partyAddressController,
                            focusNode: _partyAddressFocusNode,
                            label: 'Supplier Address',
                            hint: 'Enter supplier address (optional)',
                            icon: Icons.location_on_outlined,
                            maxLines: 2,
                            validator: (value) => null,
                          ),
                          SizedBox(height: 16.h),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _saveSupplierIfNew,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryBlue,
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(
                                      vertical: 12.h,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12.r),
                                    ),
                                  ),
                                  icon: Icon(Icons.save, size: 18.r),
                                  label: Text(
                                    'Save Supplier',
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
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
                                      return null;
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
                                child: _buildInputField(
                                  controller: _paidAmountController,
                                  focusNode: _paidAmountFocusNode,
                                  label: 'Paid Amount',
                                  hint: '0.00',
                                  icon: Icons.payments_outlined,
                                  keyboardType: TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty)
                                      return null;
                                    final v = double.tryParse(value);
                                    if (v == null || v < 0)
                                      return 'Invalid amount';
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16.h),

                          // Total Payment Display
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(16.w),
                            decoration: BoxDecoration(
                              color: Color(0xFFFDB462).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(
                                color: Color(0xFFFDB462).withOpacity(0.3),
                                width: 1.w,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Total Payment',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black87,
                                  ),
                                ),
                                Text(
                                  '₹${_calculateTotalPayment().toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                SizedBox(height: 32.h),

                // Save Button
                Container(
                  width: double.infinity,
                  height: 56.h,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(28.r),
                  ),
                  child: ElevatedButton(
                    onPressed: _saveItem,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28.r),
                      ),
                    ),
                    child: Text(
                      isEditing ? 'UPDATE ITEM' : 'ADD ITEM',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 16.h),

                // Cancel Button
                Container(
                  width: double.infinity,
                  height: 56.h,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(28.r),
                  ),
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28.r),
                      ),
                    ),
                    child: Text(
                      'CANCEL',
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
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
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          decoration: BoxDecoration(
            color: Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color:
                  focusNode.hasFocus ? Color(0xFFFDB462) : Colors.grey.shade300,
              width: 1.w,
            ),
          ),
          child: TextFormField(
            onTapOutside: (_) => FocusScope.of(context).unfocus(),
            controller: controller,
            focusNode: focusNode,
            keyboardType: keyboardType,
            maxLines: maxLines,
            style: TextStyle(
              fontSize: 16.sp,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                fontSize: 16.sp,
                color: Colors.grey.shade500,
              ),
              prefixIcon: Container(
                margin: EdgeInsets.all(12.w),
                width: 24.w,
                height: 24.h,
                decoration: BoxDecoration(
                  color: Color(0xFFFDB462).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(icon, color: Color(0xFFFDB462), size: 18.sp),
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
                borderSide: BorderSide(color: Colors.red.shade400, width: 1.w),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(color: Colors.red.shade400, width: 1.w),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: 16.h,
              ),
              errorStyle: TextStyle(
                color: Colors.red.shade400,
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

  Future<void> _saveItem() async {
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
            backgroundColor: Colors.green.shade400,
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
          final partyName = _partyNameController.text.trim();
          final partyAddress = _partyAddressController.text.trim();

          shopProvider.recordPurchase(
            shopId: widget.shop.id,
            item: newItem,
            quantity: qty,
            unitPurchasePrice: unitPurchasePrice,
            partyName: partyName,
            partyAddress: partyAddress,
            totalPayment: totalPayment,
            paidAmount: paidAmount,
          );
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Item added successfully!'),
            backgroundColor: Colors.green.shade400,
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
    _partyNameController.removeListener(_onPartyNameChanged);
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
