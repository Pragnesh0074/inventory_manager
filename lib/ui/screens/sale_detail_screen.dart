import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:inventory_manager/service/pdf_service.dart';
import 'package:inventory_manager/ui/screens/multi_item_sale_screen.dart';
import '../../models/inventory_item.dart';
import '../../models/shop.dart';
import '../../models/transaction.dart' as trans_model;
import '../../theme/color.dart';
import '../../theme/style.dart';

class SaleDetailScreen extends StatefulWidget {
  final Shop shop;
  final trans_model.Transaction transaction;

  const SaleDetailScreen({
    super.key,
    required this.shop,
    required this.transaction,
  });

  @override
  State<SaleDetailScreen> createState() => _SaleDetailScreenState();
}

class _SaleDetailScreenState extends State<SaleDetailScreen> {
  bool isProcessing = false;
  late final String billNumber;
  late final DateTime billDateTime;

  @override
  void initState() {
    super.initState();
    billDateTime = widget.transaction.dateTime;
    billNumber = _generateBillNumber(widget.transaction);
  }

  String _generateBillNumber(trans_model.Transaction t) {
    final dt = t.dateTime;
    final idSuffix = t.id.length > 6 ? t.id.substring(t.id.length - 6) : t.id;
    return 'BILL${dt.year}${dt.month.toString().padLeft(2, '0')}${dt.day.toString().padLeft(2, '0')}$idSuffix';
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.transaction;
    final subtotal = t.totalAmount;
    final tax = subtotal * 0.18;
    final total = subtotal + tax;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text('Sale Details', style: AppTextStyles.appBarTitle),
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
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBillHeaderCard(),
              SizedBox(height: 16.h),
              _buildCustomerInfoCard(),
              SizedBox(height: 16.h),
              _buildSaleInfoCard(t),
              SizedBox(height: 16.h),
              _buildBillSummaryCard(subtotal, tax, total),
              SizedBox(height: 24.h),
              _buildActionButtons(subtotal, tax, total),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBillHeaderCard() {
    return Container(
      width: double.infinity,
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
        children: [
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              gradient: AppColors.lightGradient,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              Icons.receipt_long,
              color: AppColors.textOnPrimary,
              size: 32.sp,
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            widget.shop.name,
            style: AppTextStyles.headingLarge,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 4.h),
          Text(
            widget.shop.address,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 12.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: AppColors.blueTinted,
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Text(
              'Bill #$billNumber',
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.primaryBlue,
              ),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            _formatDateTime(billDateTime),
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerInfoCard() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Row(
        children: [
          Icon(
            Icons.person_outline,
            color: AppColors.textSecondary,
            size: 20.sp,
          ),
          SizedBox(width: 12.w),
          Text(
            'Walk-in Customer',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaleInfoCard(trans_model.Transaction t) {
    return Container(
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
      child: Padding(
        padding: EdgeInsets.all(20.w),
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
                    Icons.shopping_cart,
                    color: AppColors.primaryBlue,
                    size: 20.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Text('Items Purchased', style: AppTextStyles.headingMedium),
              ],
            ),
            SizedBox(height: 16.h),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.itemName,
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        '₹${t.price.toStringAsFixed(2)} each',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 6.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.blueTinted,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Text(
                        '×${t.quantity}',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    '₹${t.totalAmount.toStringAsFixed(2)}',
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.success,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBillSummaryCard(double subtotal, double tax, double total) {
    return Container(
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
                  Icons.calculate,
                  color: AppColors.primaryBlue,
                  size: 20.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Text('Bill Summary', style: AppTextStyles.headingMedium),
            ],
          ),
          SizedBox(height: 20.h),
          _buildSummaryRow(
            'Items Count:',
            '${widget.transaction.quantity} items',
            false,
          ),
          SizedBox(height: 8.h),
          _buildSummaryRow(
            'Subtotal:',
            '₹${subtotal.toStringAsFixed(2)}',
            false,
          ),
          SizedBox(height: 8.h),
          _buildSummaryRow('GST (18%):', '₹${tax.toStringAsFixed(2)}', false),
          SizedBox(height: 12.h),
          Container(
            height: 1.h,
            color: AppColors.surfaceLight,
            margin: EdgeInsets.symmetric(vertical: 8.h),
          ),
          _buildSummaryRow(
            'Total Amount:',
            '₹${total.toStringAsFixed(2)}',
            true,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, bool isTotal) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style:
              isTotal
                  ? AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w700,
                  )
                  : AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
        ),
        Text(
          value,
          style:
              isTotal
                  ? AppTextStyles.headingMedium.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w700,
                  )
                  : AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(double subtotal, double tax, double total) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 56.h,
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: AppColors.primaryBlue, width: 2.w),
          ),
          child: ElevatedButton(
            onPressed:
                isProcessing
                    ? null
                    : () => _generatePDFBill(subtotal, tax, total),
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
                  Icons.picture_as_pdf,
                  color: AppColors.primaryBlue,
                  size: 24.sp,
                ),
                SizedBox(width: 12.w),
                Text(
                  'Generate PDF Bill',
                  style: AppTextStyles.buttonLarge.copyWith(
                    color: AppColors.primaryBlue,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final hour =
        dateTime.hour == 0
            ? 12
            : (dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour);
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '${dateTime.day} ${months[dateTime.month]} ${dateTime.year} at $hour:${dateTime.minute.toString().padLeft(2, '0')} $period';
  }

  Future<void> _generatePDFBill(
    double subtotal,
    double tax,
    double total,
  ) async {
    try {
      setState(() => isProcessing = true);

      // Try to find the item from the shop inventory; if missing, construct a minimal item
      final t = widget.transaction;
      InventoryItem? inventoryItem;
      try {
        inventoryItem = widget.shop.inventory.firstWhere(
          (i) => i.id == t.itemId,
        );
      } catch (_) {
        inventoryItem = InventoryItem(
          id: t.itemId,
          name: t.itemName,
          price: t.price,
          quantity: 0,
          createdDate: t.dateTime,
          lastUpdated: t.dateTime,
        );
      }

      final saleItems = [SaleItem(item: inventoryItem, quantity: t.quantity)];

      final pdfService = PDFService();
      final filePath = await pdfService.generateBill(
        shop: widget.shop,
        billNumber: billNumber,
        dateTime: billDateTime,
        customerName: 'Walk-in Customer',
        customerPhone: '',
        saleItems: saleItems,
        subtotal: subtotal,
        tax: tax,
        total: total,
        context: context,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF bill generated successfully!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            action: SnackBarAction(
              label: 'View',
              textColor: AppColors.textOnPrimary,
              onPressed: () => pdfService.openPDF(filePath),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
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
    } finally {
      if (mounted) {
        setState(() => isProcessing = false);
      }
    }
  }
}
