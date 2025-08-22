import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../models/shop.dart';
import '../../models/inventory_item.dart';
import '../../models/sale_item.dart';
import '../../models/additional_cost.dart';
import '../../models/sale.dart';
import '../../providers/shop_provider.dart';
import '../../theme/color.dart';
import '../../theme/style.dart';

class MultiItemSaleScreen extends StatefulWidget {
  final Shop shop;

  const MultiItemSaleScreen({super.key, required this.shop});

  @override
  State<MultiItemSaleScreen> createState() => _MultiItemSaleScreenState();
}

class _MultiItemSaleScreenState extends State<MultiItemSaleScreen> {
  final List<SaleItem> _saleItems = [];
  final List<AdditionalCost> _additionalCosts = [];
  final TextEditingController _notesController = TextEditingController();

  double get _subtotal => _saleItems.fold(0.0, (sum, item) => sum + item.totalAmount);
  double get _additionalCostsTotal => _additionalCosts.fold(0.0, (sum, cost) => sum + cost.amount);
  double get _grandTotal => _subtotal + _additionalCostsTotal;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          'New Sale - ${widget.shop.name}',
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
          if (_saleItems.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(right: 10.w),
              child: IconButton(
                icon: Icon(
                  Icons.receipt,
                  color: AppColors.textOnPrimary,
                  size: 24.sp,
                ),
                onPressed: _completeSale,
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          _buildSummaryCard(),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Items'),
                  if (_saleItems.isEmpty) _buildEmptyItemsState() else _buildItemsList(),
                  SizedBox(height: 24.h),
                  _buildSectionTitle('Additional Costs'),
                  if (_additionalCosts.isEmpty) _buildEmptyAdditionalCostsState() else _buildAdditionalCostsList(),
                  SizedBox(height: 24.h),
                  _buildNotesSection(),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButtons(),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      margin: EdgeInsets.all(16.w),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: AppColors.accentGradient,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withOpacity(0.3),
            blurRadius: 15,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Subtotal:', style: AppTextStyles.bodyLarge.copyWith(color: Colors.white)),
              Text('₹${_subtotal.toStringAsFixed(2)}', style: AppTextStyles.bodyLarge.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
          if (_additionalCostsTotal > 0) ...[
            SizedBox(height: 8.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Additional Costs:', style: AppTextStyles.bodyLarge.copyWith(color: Colors.white)),
                Text('₹${_additionalCostsTotal.toStringAsFixed(2)}', style: AppTextStyles.bodyLarge.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
          Divider(color: Colors.white.withOpacity(0.5), height: 20.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Grand Total:', style: AppTextStyles.headlineSmall.copyWith(color: Colors.white)),
              Text('₹${_grandTotal.toStringAsFixed(2)}', style: AppTextStyles.headlineSmall.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Text(title, style: AppTextStyles.headlineSmall),
    );
  }

  Widget _buildEmptyItemsState() {
    return Container(
      padding: EdgeInsets.all(32.w),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 48.sp,
            color: AppColors.textSecondary,
          ),
          SizedBox(height: 16.h),
          Text(
            'No items added yet',
            style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary),
          ),
          SizedBox(height: 8.h),
          Text(
            'Tap the + button to add items to this sale',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildItemsList() {
    return Column(
      children: _saleItems.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        return _buildSaleItemCard(item, index);
      }).toList(),
    );
  }

  Widget _buildSaleItemCard(SaleItem item, int index) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: item.isPriceModified ? AppColors.warning : AppColors.borderLight,
          width: item.isPriceModified ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.itemName,
                  style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                icon: Icon(Icons.edit, color: AppColors.primaryBlue, size: 20.sp),
                onPressed: () => _editSaleItem(index),
              ),
              IconButton(
                icon: Icon(Icons.delete, color: AppColors.error, size: 20.sp),
                onPressed: () => _removeSaleItem(index),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Text('Qty: ${item.quantity}', style: AppTextStyles.bodyMedium),
              SizedBox(width: 16.w),
              if (item.isPriceModified) ...[
                Text('Original: ${item.formattedOriginalPrice}', 
                     style: AppTextStyles.bodyMedium.copyWith(
                       decoration: TextDecoration.lineThrough,
                       color: AppColors.textSecondary,
                     )),
                SizedBox(width: 8.w),
              ],
              Text('Price: ${item.formattedSalePrice}', style: AppTextStyles.bodyMedium),
            ],
          ),
          SizedBox(height: 4.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (item.isPriceModified)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    'Price Modified',
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.warning),
                  ),
                ),
              Text('Total: ${item.formattedTotal}', 
                   style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyAdditionalCostsState() {
    return Container(
      padding: EdgeInsets.all(32.w),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          Icon(
            Icons.add_circle_outline,
            size: 48.sp,
            color: AppColors.textSecondary,
          ),
          SizedBox(height: 16.h),
          Text(
            'No additional costs',
            style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary),
          ),
          SizedBox(height: 8.h),
          Text(
            'Add delivery charges, taxes, or other costs',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalCostsList() {
    return Column(
      children: _additionalCosts.asMap().entries.map((entry) {
        final index = entry.key;
        final cost = entry.value;
        return _buildAdditionalCostCard(cost, index);
      }).toList(),
    );
  }

  Widget _buildAdditionalCostCard(AdditionalCost cost, int index) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(cost.name, style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
                if (cost.description != null && cost.description!.isNotEmpty) ...[
                  SizedBox(height: 4.h),
                  Text(cost.description!, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
                ],
              ],
            ),
          ),
          Text(cost.formattedAmount, style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
          SizedBox(width: 8.w),
          IconButton(
            icon: Icon(Icons.edit, color: AppColors.primaryBlue, size: 20.sp),
            onPressed: () => _editAdditionalCost(index),
          ),
          IconButton(
            icon: Icon(Icons.delete, color: AppColors.error, size: 20.sp),
            onPressed: () => _removeAdditionalCost(index),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Notes (Optional)'),
        TextField(
          controller: _notesController,
          maxLines: 3,
          style: AppTextStyles.bodyLarge,
          decoration: InputDecoration(
            hintText: 'Add any notes about this sale...',
            hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
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
    );
  }

  Widget _buildFloatingActionButtons() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton(
          heroTag: "add_cost",
          onPressed: _showAddAdditionalCostDialog,
          backgroundColor: AppColors.warning,
          child: Icon(Icons.attach_money, color: Colors.white),
        ),
        SizedBox(height: 12.h),
        FloatingActionButton(
          heroTag: "add_item",
          onPressed: _showAddItemDialog,
          backgroundColor: AppColors.primaryBlue,
          child: Icon(Icons.add, color: Colors.white),
        ),
      ],
    );
  }

  void _showAddItemDialog() {
    showDialog(
      context: context,
      builder: (context) => _AddItemDialog(
        shop: widget.shop,
        onItemAdded: (saleItem) {
          setState(() {
            // Check if item already exists and update quantity instead
            final existingIndex = _saleItems.indexWhere((item) => item.itemId == saleItem.itemId && item.salePrice == saleItem.salePrice);
            if (existingIndex != -1) {
              final existingItem = _saleItems[existingIndex];
              final newQuantity = existingItem.quantity + saleItem.quantity;
              final newTotal = saleItem.salePrice * newQuantity;
              _saleItems[existingIndex] = existingItem.copyWith(
                quantity: newQuantity,
                totalAmount: newTotal,
              );
            } else {
              _saleItems.add(saleItem);
            }
          });
        },
      ),
    );
  }

  void _showAddAdditionalCostDialog() {
    showDialog(
      context: context,
      builder: (context) => _AddAdditionalCostDialog(
        onCostAdded: (cost) {
          setState(() {
            _additionalCosts.add(cost);
          });
        },
      ),
    );
  }

  void _editSaleItem(int index) {
    final item = _saleItems[index];
    showDialog(
      context: context,
      builder: (context) => _EditSaleItemDialog(
        saleItem: item,
        onItemUpdated: (updatedItem) {
          setState(() {
            _saleItems[index] = updatedItem;
          });
        },
      ),
    );
  }

  void _removeSaleItem(int index) {
    setState(() {
      _saleItems.removeAt(index);
    });
  }

  void _editAdditionalCost(int index) {
    final cost = _additionalCosts[index];
    showDialog(
      context: context,
      builder: (context) => _AddAdditionalCostDialog(
        existingCost: cost,
        onCostAdded: (updatedCost) {
          setState(() {
            _additionalCosts[index] = updatedCost;
          });
        },
      ),
    );
  }

  void _removeAdditionalCost(int index) {
    setState(() {
      _additionalCosts.removeAt(index);
    });
  }

  void _completeSale() {
    if (_saleItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please add at least one item to complete the sale'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        ),
      );
      return;
    }

    final sale = Sale.create(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      shopId: widget.shop.id,
      items: _saleItems,
      additionalCosts: _additionalCosts,
      dateTime: DateTime.now(),
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );

    Provider.of<ShopProvider>(context, listen: false).completeSale(sale);
    
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sale completed successfully!'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      ),
    );
  }
}

class _AddItemDialog extends StatefulWidget {
  final Shop shop;
  final Function(SaleItem) onItemAdded;

  const _AddItemDialog({required this.shop, required this.onItemAdded});

  @override
  State<_AddItemDialog> createState() => _AddItemDialogState();
}

class _AddItemDialogState extends State<_AddItemDialog> {
  InventoryItem? _selectedItem;
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  @override
  void dispose() {
    _quantityController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.backgroundLight,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      title: Text('Add Item', style: AppTextStyles.dialogTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<InventoryItem>(
              value: _selectedItem,
              decoration: InputDecoration(
                labelText: 'Select Item',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
              ),
              items: widget.shop.inventory.where((item) => item.quantity > 0).map((item) {
                return DropdownMenuItem(
                  value: item,
                  child: Text('${item.name} (Available: ${item.quantity})'),
                );
              }).toList(),
              onChanged: (item) {
                setState(() {
                  _selectedItem = item;
                  _priceController.text = item?.price.toString() ?? '';
                });
              },
            ),
            SizedBox(height: 16.h),
            TextField(
              controller: _quantityController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Quantity',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
              ),
            ),
            SizedBox(height: 16.h),
            TextField(
              controller: _priceController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Price per unit',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                suffixText: '₹',
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
            onPressed: _addItem,
            child: Text('Add', style: AppTextStyles.dialogButtonPrimary),
          ),
        ),
      ],
    );
  }

  void _addItem() {
    if (_selectedItem == null) return;
    
    final quantity = int.tryParse(_quantityController.text) ?? 0;
    final price = double.tryParse(_priceController.text) ?? 0.0;
    
    if (quantity <= 0 || price <= 0) return;
    if (quantity > _selectedItem!.quantity) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Quantity exceeds available stock'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    
    final saleItem = SaleItem(
      itemId: _selectedItem!.id,
      itemName: _selectedItem!.name,
      quantity: quantity,
      originalPrice: _selectedItem!.price,
      salePrice: price,
      totalAmount: price * quantity,
    );
    
    widget.onItemAdded(saleItem);
    Navigator.pop(context);
  }
}

class _EditSaleItemDialog extends StatefulWidget {
  final SaleItem saleItem;
  final Function(SaleItem) onItemUpdated;

  const _EditSaleItemDialog({required this.saleItem, required this.onItemUpdated});

  @override
  State<_EditSaleItemDialog> createState() => _EditSaleItemDialogState();
}

class _EditSaleItemDialogState extends State<_EditSaleItemDialog> {
  late TextEditingController _quantityController;
  late TextEditingController _priceController;

  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController(text: widget.saleItem.quantity.toString());
    _priceController = TextEditingController(text: widget.saleItem.salePrice.toString());
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.backgroundLight,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      title: Text('Edit ${widget.saleItem.itemName}', style: AppTextStyles.dialogTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _quantityController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Quantity',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
            ),
          ),
          SizedBox(height: 16.h),
          TextField(
            controller: _priceController,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Price per unit',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
              suffixText: '₹',
              helperText: 'Original price: ₹${widget.saleItem.originalPrice}',
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
            onPressed: _updateItem,
            child: Text('Update', style: AppTextStyles.dialogButtonPrimary),
          ),
        ),
      ],
    );
  }

  void _updateItem() {
    final quantity = int.tryParse(_quantityController.text) ?? 0;
    final price = double.tryParse(_priceController.text) ?? 0.0;
    
    if (quantity <= 0 || price <= 0) return;
    
    final updatedItem = widget.saleItem.copyWith(
      quantity: quantity,
      salePrice: price,
      totalAmount: price * quantity,
    );
    
    widget.onItemUpdated(updatedItem);
    Navigator.pop(context);
  }
}

class _AddAdditionalCostDialog extends StatefulWidget {
  final Function(AdditionalCost) onCostAdded;
  final AdditionalCost? existingCost;

  const _AddAdditionalCostDialog({required this.onCostAdded, this.existingCost});

  @override
  State<_AddAdditionalCostDialog> createState() => _AddAdditionalCostDialogState();
}

class _AddAdditionalCostDialogState extends State<_AddAdditionalCostDialog> {
  late TextEditingController _nameController;
  late TextEditingController _amountController;
  late TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existingCost?.name ?? '');
    _amountController = TextEditingController(text: widget.existingCost?.amount.toString() ?? '');
    _descriptionController = TextEditingController(text: widget.existingCost?.description ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.backgroundLight,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      title: Text(widget.existingCost == null ? 'Add Additional Cost' : 'Edit Additional Cost', 
                  style: AppTextStyles.dialogTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Cost Name',
              hintText: 'e.g., Delivery, Tax, Service Charge',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
            ),
          ),
          SizedBox(height: 16.h),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Amount',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
              suffixText: '₹',
            ),
          ),
          SizedBox(height: 16.h),
          TextField(
            controller: _descriptionController,
            decoration: InputDecoration(
              labelText: 'Description (Optional)',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
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
            onPressed: _addCost,
            child: Text(widget.existingCost == null ? 'Add' : 'Update', 
                        style: AppTextStyles.dialogButtonPrimary),
          ),
        ),
      ],
    );
  }

  void _addCost() {
    final name = _nameController.text.trim();
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    final description = _descriptionController.text.trim();
    
    if (name.isEmpty || amount <= 0) return;
    
    final cost = AdditionalCost(
      id: widget.existingCost?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      amount: amount,
      description: description.isEmpty ? null : description,
    );
    
    widget.onCostAdded(cost);
    Navigator.pop(context);
  }
}