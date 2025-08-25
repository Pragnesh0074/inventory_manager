import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:inventory_manager/models/sale_order.dart';
import 'package:inventory_manager/service/pdf_service.dart';
import '../../models/inventory_item.dart';
import '../../models/shop.dart';
import '../../models/sale_order.dart' as order_models;
import '../../ui/screens/multi_item_sale_screen.dart' as multi_sale;
import '../../theme/color.dart';
import '../../theme/style.dart';

class SaleDetailScreen extends StatefulWidget {
  final Shop shop;
  final SaleOrder saleOrder;

  const SaleDetailScreen({
    super.key,
    required this.shop,
    required this.saleOrder,
  });

  @override
  State<SaleDetailScreen> createState() => _SaleDetailScreenState();
}

class _SaleDetailScreenState extends State<SaleDetailScreen> {
  bool isProcessing = false;

  String _generateBillNumber(SaleOrder saleOrder) {
    final dt = saleOrder.dateTime;
    final idSuffix =
        saleOrder.id.length > 6
            ? saleOrder.id.substring(saleOrder.id.length - 6)
            : saleOrder.id;
    return 'BILL${dt.year}${dt.month.toString().padLeft(2, '0')}${dt.day.toString().padLeft(2, '0')}$idSuffix';
  }

  @override
  Widget build(BuildContext context) {
    final saleOrder = widget.saleOrder;
    final subtotal = saleOrder.subtotal;
    final tax = saleOrder.tax;
    final total = saleOrder.total;

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
              _buildSaleItemsCard(),
              SizedBox(height: 16.h),
              if (widget.saleOrder.additionalCharges.isNotEmpty) ...[
                _buildAdditionalChargesCard(),
                SizedBox(height: 16.h),
              ],
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
              'Bill #${_generateBillNumber(widget.saleOrder)}',
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.primaryBlue,
              ),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            _formatDateTime(widget.saleOrder.dateTime),
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerInfoCard() {
    final saleOrder = widget.saleOrder;
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.person_outline,
                color: AppColors.textSecondary,
                size: 20.sp,
              ),
              SizedBox(width: 12.w),
              Text(
                'Customer Information',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          if (saleOrder.customerName.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: Row(
                children: [
                  Text(
                    'Name: ',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    saleOrder.customerName,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          if (saleOrder.customerPhone.isNotEmpty)
            Row(
              children: [
                Text(
                  'Phone: ',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  saleOrder.customerPhone,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildSaleItemsCard() {
    final saleOrder = widget.saleOrder;
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
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: saleOrder.items.length,
              itemBuilder: (context, index) {
                final item = saleOrder.items[index];
                return Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                item.itemName,
                                style: AppTextStyles.bodyLarge.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (item.isTemporaryItem) ...[
                                SizedBox(width: 8.w),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 6.w,
                                    vertical: 2.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.warning.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4.r),
                                    border: Border.all(
                                      color: AppColors.warning.withOpacity(0.3),
                                      width: 1.w,
                                    ),
                                  ),
                                  child: Text(
                                    'Temporary',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.warning,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 10.sp,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            '₹${item.unitPrice.toStringAsFixed(2)} each',
                            style: AppTextStyles.bodySmall.copyWith(
                              color:
                                  item.isTemporaryItem
                                      ? AppColors.warning
                                      : AppColors.textSecondary,
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
                            '×${item.quantity}',
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
                        '₹${item.totalPrice.toStringAsFixed(2)}',
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.success,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBillSummaryCard(double subtotal, double tax, double total) {
    final inventoryItemsSubtotal = widget.saleOrder.items
        .where((item) => !item.isTemporaryItem)
        .fold(0.0, (sum, item) => sum + item.totalPrice);
    final temporaryItemsSubtotal = widget.saleOrder.items
        .where((item) => item.isTemporaryItem)
        .fold(0.0, (sum, item) => sum + item.totalPrice);
    final additionalChargesTotal = widget.saleOrder.additionalCharges.fold(
      0.0,
      (sum, charge) => sum + charge.totalAmount,
    );

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
            '${widget.saleOrder.totalQuantity} items',
            false,
          ),
          SizedBox(height: 8.h),
          _buildSummaryRow(
            'Inventory Items:',
            '₹${inventoryItemsSubtotal.toStringAsFixed(2)}',
            false,
          ),
          if (temporaryItemsSubtotal > 0) ...[
            SizedBox(height: 8.h),
            _buildSummaryRow(
              'Temporary Items:',
              '₹${temporaryItemsSubtotal.toStringAsFixed(2)}',
              false,
            ),
          ],
          if (additionalChargesTotal > 0) ...[
            SizedBox(height: 8.h),
            _buildSummaryRow(
              'Additional Charges:',
              '₹${additionalChargesTotal.toStringAsFixed(2)}',
              false,
            ),
          ],
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

  Widget _buildAdditionalChargesCard() {
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
                    Icons.add_circle_outline,
                    color: AppColors.primaryBlue,
                    size: 20.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Text('Additional Charges', style: AppTextStyles.headingMedium),
              ],
            ),
            SizedBox(height: 16.h),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: widget.saleOrder.additionalCharges.length,
              itemBuilder: (context, index) {
                final charge = widget.saleOrder.additionalCharges[index];
                return Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        charge.name,
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '₹${charge.amount.toStringAsFixed(2)}',
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.success,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
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
      final saleOrder = widget.saleOrder;
      final saleItems =
          saleOrder.items.map((item) {
            if (item.isTemporaryItem) {
              // Handle temporary items
              return multi_sale.SaleItem(
                temporaryItemName: item.temporaryItemName,
                temporaryItemPrice: item.temporaryItemPrice,
                quantity: item.quantity,
              );
            } else {
              // Handle inventory items
              InventoryItem? inventoryItem;
              try {
                inventoryItem = widget.shop.inventory.firstWhere(
                  (i) => i.id == item.item?.id,
                );
              } catch (_) {
                inventoryItem = InventoryItem(
                  id: item.item?.id ?? '',
                  name: item.itemName,
                  price: item.unitPrice,
                  quantity: 0,
                  createdDate: item.item?.createdDate ?? DateTime.now(),
                  lastUpdated: item.item?.lastUpdated ?? DateTime.now(),
                );
              }
              return multi_sale.SaleItem(
                item: inventoryItem,
                quantity: item.quantity,
              );
            }
          }).toList();

      final pdfService = PDFService();
      final filePath = await pdfService.generateBill(
        shop: widget.shop,
        billNumber: _generateBillNumber(saleOrder),
        dateTime: saleOrder.dateTime,
        customerName:
            saleOrder.customerName.isEmpty
                ? 'Walk-in Customer'
                : saleOrder.customerName,
        customerPhone: saleOrder.customerPhone,
        saleItems: saleItems,
        additionalCharges:
            saleOrder.additionalCharges
                .map(
                  (charge) => order_models.AdditionalCharge(
                    name: charge.name,
                    amount: charge.amount,
                  ),
                )
                .toList(),
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
          ),
        );
        pdfService.openPDF(filePath);
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
