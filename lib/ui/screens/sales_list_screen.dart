import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../models/shop.dart';
import '../../models/sale_order.dart';
import '../../providers/shop_provider.dart';
import '../../theme/color.dart';
import '../../theme/style.dart';
import 'sale_detail_screen.dart';

class SalesListScreen extends StatelessWidget {
  final Shop shop;

  const SalesListScreen({super.key, required this.shop});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDB462),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFDB462),
        elevation: 0,
        leading: Container(
          margin: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new,
              color: Colors.black,
              size: 18.sp,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Text(
          'SALES',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
      ),
      body: Consumer<ShopProvider>(
        builder: (context, shopProvider, child) {
          final currentShop = shopProvider.shops.firstWhere(
            (s) => s.id == shop.id,
          );

          final saleOrders = shopProvider.getSaleOrders(shop.id);

          if (saleOrders.isEmpty) {
            return Container(
              color: Colors.white,
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(40.w),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Decorative circles in background
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          // Outer circle
                          Container(
                            width: 200.w,
                            height: 200.w,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.1),
                            ),
                          ),
                          // Middle circle
                          Container(
                            width: 150.w,
                            height: 150.w,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.15),
                            ),
                          ),
                          // Icon container
                          Container(
                            width: 100.w,
                            height: 100.w,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white,
                                  Colors.white.withOpacity(0.9),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 30,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.receipt_long_outlined,
                              size: 50.sp,
                              color: const Color(0xFFFDB462),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 40.h),
                      Text(
                        'No Sales Yet',
                        style: TextStyle(
                          fontSize: 28.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(height: 12.h),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 32.w),
                        child: Text(
                          'Start creating sales to see them appear here',
                          style: TextStyle(
                            fontSize: 16.sp,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w400,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      SizedBox(height: 32.h),
                      // Decorative element
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildFeatureItem(Icons.speed, 'Quick'),
                          SizedBox(width: 24.w),
                          _buildFeatureItem(Icons.check_circle_outline, 'Easy'),
                          SizedBox(width: 24.w),
                          _buildFeatureItem(Icons.trending_up, 'Track'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          return Column(
            children: [
              // Summary Cards
              Padding(
                padding: EdgeInsets.all(16.w),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        title: 'Total Sales',
                        value: saleOrders.length.toString(),
                        icon: Icons.receipt_long,
                        color: const Color(0xFF6C5CE7),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: _buildSummaryCard(
                        title: 'Revenue',
                        value: '₹${_calculateTotalRevenue(saleOrders)}',
                        icon: Icons.trending_up,
                        color: const Color(0xFF00B894),
                      ),
                    ),
                  ],
                ),
              ),

              // Sales List
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24.r),
                      topRight: Radius.circular(24.r),
                    ),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.all(16.w),
                        child: Row(
                          children: [
                            Text(
                              'Recent Sales',
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12.w,
                                vertical: 6.h,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5E6A8),
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: Text(
                                '${saleOrders.length} orders',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView.separated(
                          padding: EdgeInsets.symmetric(horizontal: 16.w),
                          itemCount: saleOrders.length,
                          separatorBuilder:
                              (context, index) => SizedBox(height: 12.h),
                          itemBuilder: (context, index) {
                            final saleOrder = saleOrders[index];
                            return _buildSaleOrderCard(
                              context,
                              currentShop,
                              saleOrder,
                            );
                          },
                        ),
                      ),
                      SizedBox(height: 16.h),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(icon, color: color, size: 20.sp),
          ),
          SizedBox(height: 12.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            title,
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _calculateTotalRevenue(List<SaleOrder> saleOrders) {
    double total = 0;
    for (var order in saleOrders) {
      total += order.total;
    }
    return total.toStringAsFixed(0);
  }

  Widget _buildSaleOrderCard(
    BuildContext context,
    Shop shop,
    SaleOrder saleOrder,
  ) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => SaleDetailScreen(shop: shop, saleOrder: saleOrder),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: Colors.grey.withOpacity(0.2), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Container(
                  width: 40.w,
                  height: 40.w,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C5CE7).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(
                    Icons.receipt,
                    color: const Color(0xFF6C5CE7),
                    size: 20.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bill #${saleOrder.billNumber}',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        saleOrder.formattedDateTime,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      saleOrder.formattedTotal,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF00B894),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 2.h,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5E6A8),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        '${saleOrder.itemCount} items',
                        style: TextStyle(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Customer info (if available)
            if (saleOrder.customerName.isNotEmpty ||
                saleOrder.customerPhone.isNotEmpty) ...[
              SizedBox(height: 12.h),
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 14.sp,
                      color: Colors.grey[600],
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (saleOrder.customerName.isNotEmpty)
                            Text(
                              saleOrder.customerName,
                              style: TextStyle(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                          if (saleOrder.customerPhone.isNotEmpty)
                            Text(
                              saleOrder.customerPhone,
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: Colors.grey[600],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            SizedBox(height: 12.h),

            // Items preview
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Qty: ${saleOrder.totalQuantity}',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C5CE7).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Text(
                    'View Details',
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF6C5CE7),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String label) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: const Color(0xFFFDB462).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Icon(icon, size: 20.sp, color: const Color(0xFFFDB462)),
        ),
        SizedBox(height: 8.h),
        Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
