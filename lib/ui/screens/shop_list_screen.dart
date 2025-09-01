import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../models/shop.dart';
import '../../providers/shop_provider.dart';
import 'add_edit_shop_screen.dart';
import 'inventory_screen.dart';
import 'statistics_summary_screen.dart';

class ShopListScreen extends StatelessWidget {
  const ShopListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: Text(
          'INVENTORY MANAGEMENT',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: const Color(0xFFFDB462),
        elevation: 0,
        centerTitle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(24.r),
          ),
        ),
      ),
      body: Consumer<ShopProvider>(
        builder: (context, shopProvider, child) {
          if (shopProvider.shops.isEmpty) {
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
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orange.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.store_outlined,
                      size: 48.r,
                      color: const Color(0xFFFF9500),
                    ),
                  ),
                  SizedBox(height: 24.h),
                  Text(
                    'No shops available',
                    style: TextStyle(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Create your first shop to get started',
                    style: TextStyle(fontSize: 16.sp, color: Colors.grey[600]),
                  ),
                  SizedBox(height: 32.h),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () => _navigateToAddShop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black87,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: 32.w,
                          vertical: 16.h,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.add),
                      label: Text(
                        'ADD YOUR FIRST SHOP',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Summary Cards Section
              Container(
                margin: EdgeInsets.all(16.r),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Overview',
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Row(
                      children: [
                        // Total Shops Card
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.all(20.r),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4A90E2),
                              borderRadius: BorderRadius.circular(20.r),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF4A90E2,
                                  ).withOpacity(0.3),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: EdgeInsets.all(8.r),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12.r),
                                  ),
                                  child: Icon(
                                    Icons.store,
                                    color: Colors.white,
                                    size: 24.r,
                                  ),
                                ),
                                SizedBox(height: 12.h),
                                Text(
                                  '${shopProvider.shops.length}',
                                  style: TextStyle(
                                    fontSize: 28.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  'Total Shops',
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color: Colors.white.withOpacity(0.9),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(width: 16.w),
                        // Total Inventory Value Card
                        Expanded(
                          child: Container(
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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: EdgeInsets.all(8.r),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFFFF9500,
                                    ).withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12.r),
                                  ),
                                  child: Icon(
                                    Icons.attach_money,
                                    color: const Color(0xFFFF9500),
                                    size: 24.r,
                                  ),
                                ),
                                SizedBox(height: 12.h),
                                Text(
                                  '\$${_getTotalValue(shopProvider.shops)}',
                                  style: TextStyle(
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                Text(
                                  'Total Inventory Value',
                                  style: TextStyle(
                                    fontSize: 11.sp,
                                    color: Colors.black54,
                                    fontWeight: FontWeight.w500,
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

              // Shops List Section
              Expanded(
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Your Shops',
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () => _navigateToAddShop(context),
                            icon: const Icon(
                              Icons.add,
                              size: 20,
                              color: Color(0xFF4A90E2),
                            ),
                            label: Text(
                              'Add Shop',
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF4A90E2),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16.h),
                      Expanded(
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
                                    builder:
                                        (context) =>
                                            InventoryScreen(shop: shop),
                                  ),
                                );
                              },
                              child: Container(
                                margin: EdgeInsets.only(bottom: 16.h),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20.r),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 10,
                                      spreadRadius: 1,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: EdgeInsets.all(20.r),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 60.w,
                                        height: 60.h,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFFE5B8),
                                          borderRadius: BorderRadius.circular(
                                            16.r,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.store,
                                          color: const Color(0xFFFF9500),
                                          size: 28.r,
                                        ),
                                      ),
                                      SizedBox(width: 16.w),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              shop.name,
                                              style: TextStyle(
                                                fontSize: 18.sp,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black87,
                                              ),
                                            ),
                                            SizedBox(height: 4.h),
                                            Text(
                                              shop.address,
                                              style: TextStyle(
                                                fontSize: 14.sp,
                                                color: Colors.grey[600],
                                                fontWeight: FontWeight.w400,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            SizedBox(height: 12.h),
                                            Row(
                                              children: [
                                                Container(
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: 12.w,
                                                    vertical: 6.h,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: const Color(
                                                      0xFF4A90E2,
                                                    ).withOpacity(0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          20.r,
                                                        ),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        Icons
                                                            .inventory_2_outlined,
                                                        size: 16.r,
                                                        color: const Color(
                                                          0xFF4A90E2,
                                                        ),
                                                      ),
                                                      SizedBox(width: 4.w),
                                                      Text(
                                                        '${shop.inventory.length} items',
                                                        style: TextStyle(
                                                          fontSize: 12.sp,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: const Color(
                                                            0xFF4A90E2,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                SizedBox(width: 8.w),
                                                if (shop.inventory.isNotEmpty)
                                                  Container(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                          horizontal: 12.w,
                                                          vertical: 6.h,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.green
                                                          .withOpacity(0.1),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            20.r,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      'Active',
                                                      style: TextStyle(
                                                        fontSize: 12.sp,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color:
                                                            Colors.green[700],
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(width: 16.w),
                                      Container(
                                        decoration: BoxDecoration(
                                          color: Colors.grey[50],
                                          borderRadius: BorderRadius.circular(
                                            12.r,
                                          ),
                                        ),
                                        child: PopupMenuButton(
                                          color: Colors.white,
                                          icon: Icon(
                                            Icons.more_vert,
                                            color: Colors.grey[600],
                                            size: 20,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              16.r,
                                            ),
                                          ),
                                          elevation: 8,
                                          shadowColor: Colors.black.withOpacity(
                                            0.1,
                                          ),
                                          itemBuilder:
                                              (context) => [
                                                PopupMenuItem(
                                                  value: 'statistics',
                                                  child: Container(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                          vertical: 4.h,
                                                        ),
                                                    child: Row(
                                                      children: [
                                                        Icon(
                                                          Icons
                                                              .analytics_outlined,
                                                          size: 18,
                                                          color: const Color(
                                                            0xFF4A90E2,
                                                          ),
                                                        ),
                                                        SizedBox(width: 12.w),
                                                        Text(
                                                          'Statistics',
                                                          style: TextStyle(
                                                            fontSize: 14.sp,
                                                            fontWeight:
                                                                FontWeight.w500,
                                                            color:
                                                                Colors.black87,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                                PopupMenuItem(
                                                  value: 'edit',
                                                  child: Container(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                          vertical: 4.h,
                                                        ),
                                                    child: Row(
                                                      children: [
                                                        Icon(
                                                          Icons.edit_outlined,
                                                          size: 18,
                                                          color: const Color(
                                                            0xFF4A90E2,
                                                          ),
                                                        ),
                                                        SizedBox(width: 12.w),
                                                        Text(
                                                          'Edit',
                                                          style: TextStyle(
                                                            fontSize: 14.sp,
                                                            fontWeight:
                                                                FontWeight.w500,
                                                            color:
                                                                Colors.black87,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                                PopupMenuItem(
                                                  value: 'delete',
                                                  child: Container(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                          vertical: 4.h,
                                                        ),
                                                    child: Row(
                                                      children: [
                                                        Icon(
                                                          Icons.delete_outline,
                                                          size: 18,
                                                          color:
                                                              Colors.red[400],
                                                        ),
                                                        SizedBox(width: 12.w),
                                                        Text(
                                                          'Delete',
                                                          style: TextStyle(
                                                            fontSize: 14.sp,
                                                            fontWeight:
                                                                FontWeight.w500,
                                                            color:
                                                                Colors.red[400],
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                          onSelected: (value) {
                                            if (value == 'statistics') {
                                              _navigateToStatistics(
                                                context,
                                                shop,
                                              );
                                            } else if (value == 'edit') {
                                              _navigateToEditShop(
                                                context,
                                                shop,
                                              );
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
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      // bottomNavigationBar: Container(
      //   decoration: BoxDecoration(
      //     color: const Color(0xFFFFE5B8),
      //     borderRadius: BorderRadius.only(
      //       topLeft: Radius.circular(24.r),
      //       topRight: Radius.circular(24.r),
      //     ),
      //     boxShadow: [
      //       BoxShadow(
      //         color: Colors.black.withOpacity(0.1),
      //         blurRadius: 20,
      //         offset: const Offset(0, -5),
      //       ),
      //     ],
      //   ),
      //   child: SafeArea(
      //     child: Padding(
      //       padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
      //       child: Row(
      //         mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      //         children: [
      //           _buildBottomNavItem(
      //             icon: Icons.home_outlined,
      //             label: 'Home',
      //             isSelected: true,
      //             onTap: () {},
      //           ),
      //           _buildBottomNavItem(
      //             icon: Icons.inventory_2_outlined,
      //             label: 'Inventory',
      //             isSelected: false,
      //             onTap: () {},
      //           ),
      //           _buildBottomNavItem(
      //             icon: Icons.settings_outlined,
      //             label: 'Setting',
      //             isSelected: false,
      //             onTap: () {},
      //           ),
      //           _buildBottomNavItem(
      //             icon: Icons.person_outline,
      //             label: 'Account',
      //             isSelected: false,
      //             onTap: () {},
      //           ),
      //         ],
      //       ),
      //     ),
      //   ),
      // ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () => _navigateToAddShop(context),
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
      ),
    );
  }

  // Widget _buildBottomNavItem({
  //   required IconData icon,
  //   required String label,
  //   required bool isSelected,
  //   required VoidCallback onTap,
  // }) {
  //   return GestureDetector(
  //     onTap: onTap,
  //     child: Container(
  //       padding: EdgeInsets.symmetric(vertical: 8.h),
  //       child: Column(
  //         mainAxisSize: MainAxisSize.min,
  //         children: [
  //           Icon(
  //             icon,
  //             size: 24.r,
  //             color: isSelected ? Colors.black87 : Colors.grey[600],
  //           ),
  //           SizedBox(height: 4.h),
  //           Text(
  //             label,
  //             style: TextStyle(
  //               fontSize: 12.sp,
  //               fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
  //               color: isSelected ? Colors.black87 : Colors.grey[600],
  //             ),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  String _getTotalValue(List<Shop> shops) {
    double total = 0;
    for (var shop in shops) {
      for (var item in shop.inventory) {
        total += (item.price ?? 0) * (item.quantity ?? 0);
      }
    }
    return total.toStringAsFixed(0);
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
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.r),
            ),
            title: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.r),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(
                    Icons.warning_outlined,
                    color: Colors.red[400],
                    size: 24,
                  ),
                ),
                SizedBox(width: 12.w),
                Text(
                  'Delete Shop',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            content: Text(
              'Are you sure you want to delete "${shop.name}"? This action cannot be undone.',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey[700],
                height: 1.4,
              ),
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
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.red[400],
                  borderRadius: BorderRadius.circular(12.r),
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
}
