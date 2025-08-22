import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../models/sale.dart';
import '../../models/shop.dart';
import '../../theme/color.dart';
import '../../theme/style.dart';
import '../../services/pdf_service.dart';

class SaleDetailScreen extends StatelessWidget {
  final Sale sale;
  final Shop shop;

  const SaleDetailScreen({
    super.key,
    required this.sale,
    required this.shop,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          'Sale Details',
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
            padding: EdgeInsets.only(right: 5.w),
            child: IconButton(
              icon: Icon(
                Icons.print,
                color: AppColors.textOnPrimary,
                size: 24.sp,
              ),
              onPressed: () => _printBill(context),
              tooltip: 'Print Bill',
            ),
          ),
          Padding(
            padding: EdgeInsets.only(right: 10.w),
            child: IconButton(
              icon: Icon(
                Icons.picture_as_pdf,
                color: AppColors.textOnPrimary,
                size: 24.sp,
              ),
              onPressed: () => _generatePDF(context),
              tooltip: 'Generate PDF',
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSaleHeader(),
            SizedBox(height: 24.h),
            _buildItemsSection(),
            if (sale.additionalCosts.isNotEmpty) ...[
              SizedBox(height: 24.h),
              _buildAdditionalCostsSection(),
            ],
            SizedBox(height: 24.h),
            _buildTotalSection(),
            if (sale.notes != null && sale.notes!.isNotEmpty) ...[
              SizedBox(height: 24.h),
              _buildNotesSection(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSaleHeader() {
    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.receipt_long,
                color: Colors.white,
                size: 24.sp,
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  'Sale #${sale.id.substring(sale.id.length - 8)}',
                  style: AppTextStyles.headlineSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Icon(
                Icons.store,
                color: Colors.white.withOpacity(0.9),
                size: 18.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                shop.name,
                style: AppTextStyles.bodyLarge.copyWith(color: Colors.white),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Icon(
                Icons.access_time,
                color: Colors.white.withOpacity(0.9),
                size: 18.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                sale.formattedDateTime,
                style: AppTextStyles.bodyLarge.copyWith(color: Colors.white),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Icon(
                Icons.shopping_cart,
                color: Colors.white.withOpacity(0.9),
                size: 18.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                '${sale.totalQuantity} items',
                style: AppTextStyles.bodyLarge.copyWith(color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildItemsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Items', style: AppTextStyles.headlineSmall),
        SizedBox(height: 12.h),
        ...sale.items.map((item) => _buildItemCard(item)).toList(),
      ],
    );
  }

  Widget _buildItemCard(saleItem) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: saleItem.isPriceModified ? AppColors.warning : AppColors.borderLight,
          width: saleItem.isPriceModified ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  saleItem.itemName,
                  style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              if (saleItem.isPriceModified)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    'Modified Price',
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.warning),
                  ),
                ),
            ],
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              _buildDetailItem('Quantity', '${saleItem.quantity}'),
              SizedBox(width: 24.w),
              if (saleItem.isPriceModified) ...[
                _buildDetailItem('Original Price', saleItem.formattedOriginalPrice),
                SizedBox(width: 24.w),
              ],
              _buildDetailItem('Sale Price', saleItem.formattedSalePrice),
            ],
          ),
          SizedBox(height: 8.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (saleItem.isPriceModified)
                Text(
                  'Discount: ${((saleItem.originalPrice - saleItem.salePrice) * saleItem.quantity).toStringAsFixed(2)} ₹',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              Text(
                'Total: ${saleItem.formattedTotal}',
                style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
        ),
        Text(
          value,
          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildAdditionalCostsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Additional Costs', style: AppTextStyles.headlineSmall),
        SizedBox(height: 12.h),
        ...sale.additionalCosts.map((cost) => _buildAdditionalCostCard(cost)).toList(),
      ],
    );
  }

  Widget _buildAdditionalCostCard(additionalCost) {
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
                Text(
                  additionalCost.name,
                  style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                ),
                if (additionalCost.description != null && additionalCost.description!.isNotEmpty) ...[
                  SizedBox(height: 4.h),
                  Text(
                    additionalCost.description!,
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ],
            ),
          ),
          Text(
            additionalCost.formattedAmount,
            style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalSection() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: AppColors.primaryBlue, width: 2),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Items Subtotal:', style: AppTextStyles.bodyLarge),
              Text(sale.formattedSubtotal, 
                   style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          if (sale.additionalCostsTotal > 0) ...[
            SizedBox(height: 12.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Additional Costs:', style: AppTextStyles.bodyLarge),
                Text(sale.formattedAdditionalCostsTotal, 
                     style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
          ],
          Divider(height: 24.h, thickness: 1),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Grand Total:', style: AppTextStyles.headlineSmall.copyWith(fontWeight: FontWeight.bold)),
              Text(sale.formattedGrandTotal, 
                   style: AppTextStyles.headlineSmall.copyWith(
                     fontWeight: FontWeight.bold,
                     color: AppColors.primaryBlue,
                   )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Notes', style: AppTextStyles.headlineSmall),
        SizedBox(height: 12.h),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: AppColors.blueTinted,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: AppColors.primaryBlue.withOpacity(0.3)),
          ),
          child: Text(
            sale.notes!,
            style: AppTextStyles.bodyMedium,
          ),
        ),
      ],
    );
  }

  void _generatePDF(BuildContext context) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16.h),
                Text('Generating PDF...', style: AppTextStyles.bodyMedium),
              ],
            ),
          ),
        ),
      );

      final filePath = await PDFService.saveBillToFile(sale, shop);
      
      Navigator.pop(context); // Close loading dialog
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF saved successfully!\nLocation: $filePath'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          duration: Duration(seconds: 4),
        ),
      );
    } catch (e) {
      Navigator.pop(context); // Close loading dialog if open
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating PDF: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
      );
    }
  }

  void _printBill(BuildContext context) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16.h),
                Text('Preparing to print...', style: AppTextStyles.bodyMedium),
              ],
            ),
          ),
        ),
      );

      await PDFService.printBill(sale, shop);
      
      Navigator.pop(context); // Close loading dialog
    } catch (e) {
      Navigator.pop(context); // Close loading dialog if open
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error printing bill: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
      );
    }
  }
}