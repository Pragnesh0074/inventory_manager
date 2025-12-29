import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:inventory_manager/ui/screens/multi_item_sale_screen.dart';
import 'package:inventory_manager/ui/screens/sale_summary_screen.dart';
import 'package:provider/provider.dart';
import '../../models/inventory_item.dart';
import '../../models/shop.dart';
import '../../providers/shop_provider.dart';
import 'add_edit_item_screen.dart';
import 'item_detail_screen.dart';
import 'monthly_summary_screen.dart';
import 'sales_list_screen.dart';
import 'purchases_list_screen.dart';
import 'sales_payments_list_screen.dart';
import 'customer_list_screen.dart';
import 'supplier_list_screen.dart';

class InventoryScreen extends StatefulWidget {
  final Shop shop;

  const InventoryScreen({super.key, required this.shop});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _showInitialLoader();
  }

  void _showInitialLoader() {
    setState(() {
      _isLoading = true;
    });

    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      _isSearching = query.isNotEmpty;
    });
  }

  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _isSearching = false;
    });
  }

  List<InventoryItem> _getFilteredInventory(List<InventoryItem> inventory) {
    if (_searchQuery.isEmpty) {
      return inventory;
    }

    return inventory.where((item) {
      return item.name.toLowerCase().contains(_searchQuery) ||
          item.quantity.toString().contains(_searchQuery) ||
          item.price.toString().contains(_searchQuery) ||
          item.id.toLowerCase().contains(_searchQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isLoading,
      child: Stack(
        children: [
          Scaffold(
            backgroundColor: Color(0xFFF5F7FA),
            appBar: AppBar(
              backgroundColor: Color(0xFFFDB462),
              elevation: 0,
              title: Text(
                'INVENTORY',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              centerTitle: true,
              leading: IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.black, size: 24.sp),
                onPressed: () => Navigator.pop(context),
              ),
              actions: [
                // Search Icon Button
                if (!_isSearching)
                  IconButton(
                    icon: Icon(Icons.search, color: Colors.black, size: 24.sp),
                    onPressed: () {
                      setState(() {
                        _isSearching = true;
                      });
                      // Focus search field after a short delay
                      Future.delayed(const Duration(milliseconds: 100), () {
                        FocusScope.of(context).requestFocus(FocusNode());
                      });
                    },
                  ),
                // Search Text Field
                if (_isSearching)
                  Expanded(
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 8.w),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: _onSearchChanged,
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: 'Search items...',
                          hintStyle: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14.sp,
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: Colors.grey[600],
                            size: 20.sp,
                          ),
                          suffixIcon:
                              _searchQuery.isNotEmpty
                                  ? IconButton(
                                    icon: Icon(
                                      Icons.clear,
                                      color: Colors.grey[600],
                                      size: 20.sp,
                                    ),
                                    onPressed: _clearSearch,
                                  )
                                  : null,
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 12.h,
                          ),
                        ),
                        style: TextStyle(fontSize: 14.sp, color: Colors.black87),
                      ),
                    ),
                  ),
                // Close Search Button
                if (_isSearching)
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.black, size: 24.sp),
                    onPressed: _clearSearch,
                  ),
              ],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(24.r)),
              ),
            ),
            body: Consumer<ShopProvider>(
              builder: (context, shopProvider, child) {
                final currentShop = shopProvider.shops.firstWhere(
                  (s) => s.id == widget.shop.id,
                );

                if (currentShop.inventory.isEmpty) {
                  return _buildEmptyState(context, currentShop);
                }

                final filteredInventory = _getFilteredInventory(
                  currentShop.inventory,
                );

                if (filteredInventory.isEmpty && _searchQuery.isNotEmpty) {
                  return _buildNoSearchResults();
                }

                return Column(
                  children: [
                    _buildSummaryCards(currentShop),
                    SizedBox(height: 8.h),
                    // Search Results Info
                    if (_searchQuery.isNotEmpty) ...[
                      Container(
                        margin: EdgeInsets.symmetric(horizontal: 16.w),
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 8.h,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFDB462).withOpacity(0.4),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.search, size: 16.sp, color: Colors.black),
                            SizedBox(width: 8.w),
                            Text(
                              '${filteredInventory.length} result${filteredInventory.length == 1 ? '' : 's'} for "$_searchQuery"',
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: Colors.black,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            TextButton(
                              onPressed: _clearSearch,
                              child: Text(
                                'Clear',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: Colors.black,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 8.h),
                    ],
                    Expanded(
                      child: ListView.separated(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 8.h,
                        ),
                        itemCount: filteredInventory.length,
                        separatorBuilder: (context, index) => SizedBox(height: 12.h),
                        itemBuilder: (context, index) {
                          final item = filteredInventory[index];
                          return _buildInventoryCard(context, currentShop, item);
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
            floatingActionButton: Container(
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(20.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: FloatingActionButton.extended(
                onPressed:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MultiItemSaleScreen(shop: widget.shop),
                      ),
                    ),
                backgroundColor: Colors.transparent,
                elevation: 0,
                icon: const Icon(Icons.add, color: Colors.white),
                label: Text(
                  'CREATE SALE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
            bottomNavigationBar: Container(
              height: 80.h,
              decoration: BoxDecoration(
                color: const Color(0xFFFDB462),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20.r),
                  topRight: Radius.circular(20.r),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10.r,
                    offset: Offset(0, -2.h),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildBottomNavItem(
                    Icons.receipt_long,
                    'Sales',
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SalesListScreen(shop: widget.shop),
                      ),
                    ),
                  ),
                  _buildBottomNavItem(
                    Icons.add_box_sharp,
                    'Add Item',
                    () => _navigateToAddItem(context, widget.shop),
                  ),
                  _buildBottomNavItem(
                    Icons.analytics,
                    'Summary',
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MonthlySummaryScreen(shop: widget.shop),
                      ),
                    ),
                  ),
                  _buildBottomNavItem(
                    Icons.shopping_bag,
                    'Purchases',
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PurchasesListScreen(shop: widget.shop),
                      ),
                    ),
                  ),
                  _buildBottomNavItem(
                    Icons.account_balance_wallet,
                    'Payments',
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => SalesPaymentsListScreen(shop: widget.shop),
                      ),
                    ),
                  ),
                  _buildBottomNavItem(
                    Icons.more_horiz,
                    'More',
                    () => _showMoreOptions(context, widget.shop),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: Container(
                  padding: EdgeInsets.all(24.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFFFDB462),
                        ),
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        'Loading...',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNoSearchResults() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120.w,
              height: 120.h,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.2),
                borderRadius: BorderRadius.circular(60.r),
              ),
              child: Icon(
                Icons.search_off,
                size: 60.sp,
                color: Colors.grey[400],
              ),
            ),
            SizedBox(height: 32.h),
            Text(
              'No Items Found',
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              'No items match your search for\n"$_searchQuery"',
              style: TextStyle(
                fontSize: 16.sp,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24.h),
            TextButton.icon(
              onPressed: _clearSearch,
              icon: Icon(Icons.clear, size: 18.sp),
              label: Text('Clear Search'),
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFFFDB462).withOpacity(0.4),
                foregroundColor: Colors.black,
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.r),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards(Shop shop) {
    final totalItems = shop.inventory.length;
    final lowStockItems =
        shop.inventory.where((item) => item.quantity < 10).length;
    final totalValue = shop.inventory.fold(
      0.0,
      (sum, item) => sum + (item.price * item.quantity),
    );

    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
              icon: Icons.inventory_2_outlined,
              value: totalItems.toString(),
              label: 'Total Items',
              color: Color(0xFF4A90E2),
              iconBg: Color(0xFF2D3748),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: _buildSummaryCard(
              icon: Icons.warning_amber_outlined,
              value: lowStockItems.toString(),
              label: 'Low Stock',
              color: Color(0xFFFFE5B8),
              iconBg: Colors.orange.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    required Color iconBg,
  }) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24.r),
      ),
      child: Column(
        children: [
          Container(
            width: 48.w,
            height: 48.h,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(24.r),
            ),
            child: Icon(icon, color: Colors.white, size: 24.sp),
          ),
          SizedBox(height: 16.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 32.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
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
        padding: EdgeInsets.all(16.w),
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
        child: Row(
          children: [
            // Item info section
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
                  SizedBox(height: 8.h),
                  Container(
                    width: double.infinity,
                    height: 8.h,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: (item.quantity / 100).clamp(0.0, 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color:
                              isLowStock
                                  ? Colors.orange.shade400
                                  : Colors.green.shade400,
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Row(
                    children: [
                      Text(
                        '${item.quantity} pcs',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      Spacer(),
                      if (isLowStock)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 4.h,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Text(
                            'Reorder level',
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: Colors.orange.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(width: 16.w),
            // Action button
            InkWell(
              onTap: () => _showMenuOptions(context, shop, item),
              child: Container(
                width: 48.w,
                height: 48.h,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(24.r),
                ),
                child: Icon(Icons.menu, color: Colors.white, size: 24.sp),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, Shop shop) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120.w,
              height: 120.h,
              decoration: BoxDecoration(
                color: Color(0xFFFDB462).withOpacity(0.2),
                borderRadius: BorderRadius.circular(60.r),
              ),
              child: Icon(
                Icons.inventory_2_outlined,
                size: 60.sp,
                color: Color(0xFFFDB462),
              ),
            ),
            SizedBox(height: 32.h),
            Text(
              'No Items Yet',
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              'Start building your inventory by\nadding your first item',
              style: TextStyle(
                fontSize: 16.sp,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 40.h),
            Container(
              width: 200.w,
              height: 50.h,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(25.r),
              ),
              child: ElevatedButton(
                onPressed: () => _navigateToAddItem(context, shop),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25.r),
                  ),
                ),
                child: Text(
                  'ADD STOCK',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMenuOptions(BuildContext context, Shop shop, InventoryItem item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.8,
            maxChildSize: 0.8,
            minChildSize: 0.3,
            builder:
                (context, scrollController) => Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24.r),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Handle bar
                      Container(
                        margin: EdgeInsets.only(top: 12.h),
                        width: 40.w,
                        height: 4.h,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2.r),
                        ),
                      ),
                      SizedBox(height: 20.h),
                      // Title
                      Text(
                        item.name,
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 20.h),
                      // Scrollable content
                      Expanded(
                        child: SingleChildScrollView(
                          controller: scrollController,
                          padding: EdgeInsets.symmetric(horizontal: 24.w),
                          child: Column(
                            children: [
                              _buildMenuOption(
                                icon: Icons.point_of_sale,
                                title: 'Quick Sale',
                                color: Color(0xFFFDB462),
                                onTap: () {
                                  Navigator.pop(context);
                                  _showQuickSaleDialog(context, shop, item);
                                },
                              ),
                              SizedBox(height: 16.h),
                              _buildMenuOption(
                                icon: Icons.add_shopping_cart,
                                title: 'Add Stock',
                                color: Colors.green.shade400,
                                onTap: () {
                                  Navigator.pop(context);
                                  _showAddStockDialog(context, shop, item);
                                },
                              ),
                              SizedBox(height: 16.h),
                              _buildMenuOption(
                                icon: Icons.remove_shopping_cart_outlined,
                                title: 'Remove Stock',
                                color: Colors.red.shade400,
                                onTap: () {
                                  Navigator.pop(context);
                                  _showRemoveItemDialog(context, shop, item);
                                },
                              ),
                              SizedBox(height: 16.h),
                              _buildMenuOption(
                                icon: Icons.visibility,
                                title: 'View Details',
                                color: Colors.blue.shade400,
                                onTap: () {
                                  Navigator.pop(context);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => ItemDetailScreen(
                                            shop: shop,
                                            item: item,
                                          ),
                                    ),
                                  );
                                },
                              ),
                              SizedBox(height: 16.h),
                              _buildMenuOption(
                                icon: Icons.edit,
                                title: 'Edit Item',
                                color: Colors.grey.shade600,
                                onTap: () {
                                  Navigator.pop(context);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => AddEditItemScreen(
                                            shop: shop,
                                            item: item,
                                          ),
                                    ),
                                  );
                                },
                              ),
                              SizedBox(height: 16.h),
                              _buildMenuOption(
                                icon: Icons.delete,
                                title: 'Delete Item',
                                color: Colors.red.shade400,
                                onTap: () {
                                  Navigator.pop(context);
                                  _showDeleteDialog(context, shop, item);
                                },
                              ),
                              SizedBox(height: 40.h), // Extra bottom padding
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
          ),
    );
  }

  Widget _buildMenuOption({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 20.w),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          children: [
            Container(
              width: 40.w,
              height: 40.h,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Icon(icon, color: Colors.white, size: 20.sp),
            ),
            SizedBox(width: 16.w),
            Text(
              title,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ],
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
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.r),
            ),
            title: Text(
              'Quick Sale - ${item.name}',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: Color(0xFFFDB462).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.inventory,
                          color: Color(0xFFFDB462),
                          size: 20.sp,
                        ),
                        SizedBox(width: 12.w),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Available: ${item.quantity}',
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                            Text(
                              'Price: ₹${item.price.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: Colors.black54,
                              ),
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
                    decoration: InputDecoration(
                      labelText: 'Quantity to sell',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide(color: Color(0xFFFDB462)),
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  TextField(
                    controller: customerNameController,
                    decoration: InputDecoration(
                      labelText: 'Customer Name (Optional)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide(color: Color(0xFFFDB462)),
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  TextField(
                    controller: customerPhoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Customer Phone (Optional)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide(color: Color(0xFFFDB462)),
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
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Color(0xFFFDB462),
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
                                additionalCharges: [],
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
                          backgroundColor: Colors.red.shade400,
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
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
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
    final partyNameController = TextEditingController();
    final partyAddressController = TextEditingController();
    final unitPriceController = TextEditingController();
    final paidAmountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            double calcTotal() {
              final qty = int.tryParse(quantityController.text) ?? 0;
              final price = double.tryParse(unitPriceController.text) ?? 0.0;
              return qty * price;
            }

            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.r),
              ),
              title: Text(
                'Add Stock - ${item.name}',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: Color(0xFFFDB462).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.inventory,
                            color: Color(0xFFFDB462),
                            size: 20.sp,
                          ),
                          SizedBox(width: 12.w),
                          Text(
                            'Current Stock: ${item.quantity}',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16.h),
                    TextField(
                      controller: quantityController,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setStateDialog(() {}),
                      decoration: InputDecoration(
                        labelText: 'Quantity to add',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide(color: Color(0xFFFDB462)),
                        ),
                      ),
                    ),
                    SizedBox(height: 12.h),
                    TextField(
                      controller: unitPriceController,
                      keyboardType: TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      onChanged: (_) => setStateDialog(() {}),
                      decoration: InputDecoration(
                        labelText: 'Purchase Unit Price',
                        prefixIcon: Icon(Icons.currency_rupee_rounded),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide(color: Color(0xFFFDB462)),
                        ),
                      ),
                    ),
                    SizedBox(height: 12.h),
                    TextField(
                      controller: paidAmountController,
                      keyboardType: TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Paid Amount',
                        prefixIcon: Icon(Icons.payments_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide(color: Color(0xFFFDB462)),
                        ),
                      ),
                    ),
                    SizedBox(height: 12.h),
                    TextField(
                      controller: partyNameController,
                      decoration: InputDecoration(
                        labelText: 'Supplier Name (optional)',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide(color: Color(0xFFFDB462)),
                        ),
                      ),
                    ),
                    SizedBox(height: 12.h),
                    TextField(
                      controller: partyAddressController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Supplier Address (optional)',
                        prefixIcon: Icon(Icons.location_on_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide(color: Color(0xFFFDB462)),
                        ),
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: Colors.grey.shade200),
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
                            '₹${calcTotal().toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 16.sp,
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
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Color(0xFFFDB462),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: TextButton(
                    onPressed: () async {
                      final qty = int.tryParse(quantityController.text) ?? 0;
                      final unitPrice = double.tryParse(
                        unitPriceController.text,
                      );
                      final paid =
                          double.tryParse(paidAmountController.text) ?? 0.0;
                      if (qty > 0 && unitPrice != null) {
                        await Provider.of<ShopProvider>(
                          context,
                          listen: false,
                        ).recordPurchase(
                          shopId: shop.id,
                          item: item,
                          quantity: qty,
                          unitPurchasePrice: unitPrice,
                          partyName: partyNameController.text.trim(),
                          partyAddress: partyAddressController.text.trim(),
                          totalPayment: unitPrice * qty,
                          paidAmount: paid,
                        );
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Added $qty ${item.name}(s) to stock',
                              ),
                              backgroundColor: Colors.green.shade400,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                            ),
                          );
                        }
                      }
                    },
                    child: Text(
                      'Save Purchase',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
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

  void _showRemoveItemDialog(
    BuildContext context,
    Shop shop,
    InventoryItem item,
  ) {
    final quantityController = TextEditingController();
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.r),
            ),
            title: Text(
              'Remove Stock - ${item.name}',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: Color(0xFFFDB462).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.inventory,
                        color: Color(0xFFFDB462),
                        size: 20.sp,
                      ),
                      SizedBox(width: 12.w),
                      Text(
                        'Available: ${item.quantity}',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16.h),
                TextField(
                  controller: quantityController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Quantity to remove',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide(color: Color(0xFFFDB462)),
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
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Color(0xFFFDB462),
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
                          content: Text('Removed $quantity ${item.name}(s)'),
                          backgroundColor: Colors.green.shade400,
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
                          backgroundColor: Colors.red.shade400,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                      );
                    }
                  },
                  child: Text(
                    'Remove',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildBottomNavItem(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.black87, size: 22.sp),
            SizedBox(height: 4.h),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.sp,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, Shop shop, InventoryItem item) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.r),
            ),
            title: Text(
              'Delete Item',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            content: Text(
              'Are you sure you want to delete "${item.name}"?',
              style: TextStyle(fontSize: 14.sp, color: Colors.black54),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.red.shade400,
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
                        backgroundColor: Colors.red.shade400,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                    );
                  },
                  child: Text(
                    'Delete',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
    );
  }

  void _showMoreOptions(BuildContext context, Shop shop) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.4,
            maxChildSize: 0.6,
            minChildSize: 0.3,
            builder:
                (context, scrollController) => Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24.r),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Handle bar
                      Container(
                        margin: EdgeInsets.only(top: 12.h),
                        width: 40.w,
                        height: 4.h,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2.r),
                        ),
                      ),
                      SizedBox(height: 20.h),
                      // Title
                      Text(
                        'More Options',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 20.h),
                      // Scrollable content
                      Expanded(
                        child: SingleChildScrollView(
                          controller: scrollController,
                          padding: EdgeInsets.symmetric(horizontal: 24.w),
                          child: Column(
                            children: [
                              _buildMoreOption(
                                icon: Icons.people_outline,
                                title: 'Customer List',
                                subtitle: 'View and manage customers',
                                color: Color(0xFF4A90E2),
                                onTap: () {
                                  Navigator.pop(context);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) =>
                                              CustomerListScreen(shop: shop),
                                    ),
                                  );
                                },
                              ),
                              SizedBox(height: 16.h),
                              _buildMoreOption(
                                icon: Icons.business_outlined,
                                title: 'Supplier List',
                                subtitle: 'View and manage suppliers',
                                color: Color(0xFFFDB462),
                                onTap: () {
                                  Navigator.pop(context);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) =>
                                              SupplierListScreen(shop: shop),
                                    ),
                                  );
                                },
                              ),
                              SizedBox(height: 40.h), // Extra bottom padding
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
          ),
    );
  }

  Widget _buildMoreOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 20.w),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: color.withOpacity(0.2), width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 48.w,
              height: 48.h,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(24.r),
              ),
              child: Icon(icon, color: Colors.white, size: 24.sp),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16.sp),
          ],
        ),
      ),
    );
  }
}
