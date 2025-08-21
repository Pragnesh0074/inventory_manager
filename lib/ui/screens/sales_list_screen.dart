import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../models/sale.dart';
import '../../models/shop.dart';
import '../../providers/shop_provider.dart';
import '../../theme/color.dart';
import '../../theme/style.dart';
import 'sale_detail_screen.dart';

class SalesListScreen extends StatefulWidget {
  final Shop shop;

  const SalesListScreen({super.key, required this.shop});

  @override
  State<SalesListScreen> createState() => _SalesListScreenState();
}

class _SalesListScreenState extends State<SalesListScreen> {
  List<Sale> _sales = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSales();
  }

  Future<void> _loadSales() async {
    setState(() => _isLoading = true);
    try {
      final sales = await Provider.of<ShopProvider>(context, listen: false)
          .getSales(widget.shop.id);
      setState(() {
        _sales = sales;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading sales: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          'Sales History - ${widget.shop.name}',
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
                Icons.refresh,
                color: AppColors.textOnPrimary,
                size: 24.sp,
              ),
              onPressed: _loadSales,
            ),
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _sales.isEmpty
              ? _buildEmptyState()
              : _buildSalesList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 80.sp,
              color: AppColors.textSecondary,
            ),
            SizedBox(height: 24.h),
            Text(
              'No sales yet',
              style: AppTextStyles.headlineSmall.copyWith(color: AppColors.textSecondary),
            ),
            SizedBox(height: 16.h),
            Text(
              'Sales will appear here once you start making transactions',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSalesList() {
    return Column(
      children: [
        _buildSummaryCard(),
        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.all(16.w),
            itemCount: _sales.length,
            separatorBuilder: (context, index) => SizedBox(height: 12.h),
            itemBuilder: (context, index) {
              final sale = _sales[index];
              return _buildSaleCard(sale);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard() {
    final totalSales = _sales.length;
    final totalRevenue = _sales.fold(0.0, (sum, sale) => sum + sale.grandTotal);
    final totalItems = _sales.fold(0, (sum, sale) => sum + sale.totalQuantity);

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
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryItem('Total Sales', '$totalSales'),
          ),
          Container(width: 1, height: 40.h, color: Colors.white.withOpacity(0.3)),
          Expanded(
            child: _buildSummaryItem('Items Sold', '$totalItems'),
          ),
          Container(width: 1, height: 40.h, color: Colors.white.withOpacity(0.3)),
          Expanded(
            child: _buildSummaryItem('Revenue', '₹${totalRevenue.toStringAsFixed(2)}'),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(color: Colors.white.withOpacity(0.9)),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 4.h),
        Text(
          value,
          style: AppTextStyles.bodyLarge.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSaleCard(Sale sale) {
    return InkWell(
      onTap: () => _navigateToSaleDetail(sale),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: AppColors.borderLight),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowLight,
              blurRadius: 8,
              offset: Offset(0, 4),
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
                    color: AppColors.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(
                    Icons.receipt,
                    color: AppColors.primaryBlue,
                    size: 20.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sale #${sale.id.substring(sale.id.length - 8)}',
                        style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        sale.formattedDateTime,
                        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      sale.formattedGrandTotal,
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                    if (sale.hasModifiedPrices)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: Text(
                          'Modified',
                          style: AppTextStyles.bodySmall.copyWith(color: AppColors.warning),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Row(
              children: [
                _buildInfoChip(Icons.shopping_cart, '${sale.totalQuantity} items'),
                SizedBox(width: 12.w),
                if (sale.additionalCosts.isNotEmpty)
                  _buildInfoChip(Icons.attach_money, '${sale.additionalCosts.length} extras'),
                if (sale.notes != null && sale.notes!.isNotEmpty) ...[
                  SizedBox(width: 12.w),
                  _buildInfoChip(Icons.note, 'Notes'),
                ],
              ],
            ),
            if (sale.items.isNotEmpty) ...[
              SizedBox(height: 8.h),
              Text(
                sale.items.take(3).map((item) => item.itemName).join(', ') +
                    (sale.items.length > 3 ? ' and ${sale.items.length - 3} more' : ''),
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: AppColors.blueTinted,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14.sp, color: AppColors.primaryBlue),
          SizedBox(width: 4.w),
          Text(
            text,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.primaryBlue),
          ),
        ],
      ),
    );
  }

  void _navigateToSaleDetail(Sale sale) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SaleDetailScreen(sale: sale, shop: widget.shop),
      ),
    );
  }
}