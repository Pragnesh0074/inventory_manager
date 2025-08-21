import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:inventory_manager/service/pdf_service.dart';
import 'package:provider/provider.dart';
import '../../models/shop.dart';
import '../../models/sale_order.dart' as order_models;
import '../../providers/shop_provider.dart';
import '../../theme/color.dart';
import '../../theme/style.dart';
import 'multi_item_sale_screen.dart' show SaleItem;

class SaleSummaryScreen extends StatefulWidget {
  final Shop shop;
  final List<SaleItem> saleItems;
  final String customerName;
  final String customerPhone;

  const SaleSummaryScreen({
    super.key,
    required this.shop,
    required this.saleItems,
    required this.customerName,
    required this.customerPhone,
  });

  @override
  _SaleSummaryScreenState createState() => _SaleSummaryScreenState();
}

class _SaleSummaryScreenState extends State<SaleSummaryScreen> {
  bool isProcessing = false;
  String? billNumber;
  DateTime? saleDateTime;

  @override
  void initState() {
    super.initState();
    _generateBillNumber();
  }

  void _generateBillNumber() {
    final now = saleDateTime ?? DateTime.now();
    billNumber =
        'BILL${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}${now.millisecondsSinceEpoch.toString().substring(8)}';
    saleDateTime ??= now;
  }

  // Add this method to _SaleSummaryScreenState class
  Future<void> _selectDateTime() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: saleDateTime!,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.primaryBlue,
              onPrimary: AppColors.textOnPrimary,
              surface: AppColors.cardBackground,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(saleDateTime!),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: AppColors.primaryBlue,
                onPrimary: AppColors.textOnPrimary,
                surface: AppColors.cardBackground,
              ),
            ),
            child: child!,
          );
        },
      );

      if (pickedTime != null) {
        final newDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        setState(() {
          saleDateTime = newDateTime;
          // Regenerate bill number with new date
          _generateBillNumber();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final subtotal = widget.saleItems.fold(
      0.0,
      (sum, item) => sum + item.totalPrice,
    );
    final tax = subtotal * 0.18; // 18% GST
    final total = subtotal + tax;
    final totalItems = widget.saleItems.fold(
      0,
      (sum, item) => sum + item.quantity,
    );

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text('Sale Summary', style: AppTextStyles.appBarTitle),
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
              // Bill Header Card
              _buildBillHeaderCard(),
              SizedBox(height: 16.h),

              // Customer Info Card
              _buildCustomerInfoCard(),
              SizedBox(height: 16.h),

              // Items List Card
              _buildItemsListCard(),
              SizedBox(height: 16.h),

              // Bill Summary Card
              _buildBillSummaryCard(subtotal, tax, total, totalItems),
              SizedBox(height: 24.h),

              // Action Buttons
              _buildActionButtons(total),
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
          GestureDetector(
            onTap: _selectDateTime,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(
                  color: AppColors.primaryBlue.withOpacity(0.3),
                  width: 1.w,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatDateTime(saleDateTime!),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Icon(Icons.edit, size: 16.sp, color: AppColors.primaryBlue),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerInfoCard() {
    if (widget.customerName.isEmpty && widget.customerPhone.isEmpty) {
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

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowBlue,
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
              Icon(Icons.person, color: AppColors.primaryBlue, size: 20.sp),
              SizedBox(width: 8.w),
              Text(
                'Customer Information',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          if (widget.customerName.isNotEmpty) ...[
            Row(
              children: [
                Text(
                  'Name: ',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(widget.customerName, style: AppTextStyles.bodyMedium),
              ],
            ),
            SizedBox(height: 4.h),
          ],
          if (widget.customerPhone.isNotEmpty) ...[
            Row(
              children: [
                Text(
                  'Phone: ',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(widget.customerPhone, style: AppTextStyles.bodyMedium),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildItemsListCard() {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(20.w),
            child: Row(
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
          ),

          // Items List
          ListView.separated(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: widget.saleItems.length,
            separatorBuilder:
                (context, index) => Container(
                  margin: EdgeInsets.symmetric(horizontal: 20.w),
                  height: 1.h,
                  color: AppColors.surfaceLight,
                ),
            itemBuilder: (context, index) {
              final saleItem = widget.saleItems[index];
              return Container(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            saleItem.item.name,
                            style: AppTextStyles.bodyLarge.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            '₹${saleItem.item.price.toStringAsFixed(2)} each',
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
                            '×${saleItem.quantity}',
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
                        '₹${saleItem.totalPrice.toStringAsFixed(2)}',
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.success,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          SizedBox(height: 16.h),
        ],
      ),
    );
  }

  Widget _buildBillSummaryCard(
    double subtotal,
    double tax,
    double total,
    int totalItems,
  ) {
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

          // Summary Rows
          _buildSummaryRow('Items Count:', '$totalItems items', false),
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

  Widget _buildActionButtons(double total) {
    return Column(
      children: [
        // Complete Sale Button
        Container(
          width: double.infinity,
          height: 56.h,
          decoration: BoxDecoration(
            gradient: AppColors.accentGradient,
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowBlueFAB,
                blurRadius: 15.r,
                offset: Offset(0, 6.h),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: isProcessing ? null : _completeSale,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.r),
              ),
            ),
            child:
                isProcessing
                    ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20.w,
                          height: 20.h,
                          child: CircularProgressIndicator(
                            color: AppColors.textOnPrimary,
                            strokeWidth: 2.w,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Text('Processing...', style: AppTextStyles.buttonLarge),
                      ],
                    )
                    : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: AppColors.textOnPrimary,
                          size: 24.sp,
                        ),
                        SizedBox(width: 12.w),
                        Text('Complete Sale', style: AppTextStyles.buttonLarge),
                      ],
                    ),
          ),
        ),
        SizedBox(height: 12.h),

        // Generate PDF Button
        Container(
          width: double.infinity,
          height: 56.h,
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: AppColors.primaryBlue, width: 2.w),
          ),
          child: ElevatedButton(
            onPressed: isProcessing ? null : _generatePDFBill,
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
        SizedBox(height: 12.h),

        // Cancel Button
        SizedBox(
          width: double.infinity,
          height: 48.h,
          child: TextButton(
            onPressed: isProcessing ? null : () => Navigator.pop(context),
            style: TextButton.styleFrom(
              backgroundColor: AppColors.surfaceLight,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
            child: Text(
              'Back to Edit',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
              ),
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

  Future<void> _completeSale() async {
    setState(() {
      isProcessing = true;
    });

    try {
      final shopProvider = Provider.of<ShopProvider>(context, listen: false);

      // Calculate totals
      final subtotal = widget.saleItems.fold(
        0.0,
        (sum, item) => sum + item.totalPrice,
      );
      final tax = subtotal * 0.18;
      final total = subtotal + tax;

      // Create sale order
      final saleOrder = order_models.SaleOrder(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        shopId: widget.shop.id,
        items:
            widget.saleItems
                .map(
                  (item) => order_models.SaleItem(
                    item: item.item,
                    quantity: item.quantity,
                    unitPrice: item.item.price,
                  ),
                )
                .toList(),
        customerName:
            widget.customerName.isEmpty
                ? 'Walk-in Customer'
                : widget.customerName,
        customerPhone: widget.customerPhone,
        dateTime: saleDateTime!,
        subtotal: subtotal,
        tax: tax,
        total: total,
        billNumber: billNumber!,
      );

      // Create the sale order (this will also update inventory)
      await shopProvider.createSaleOrder(widget.shop.id, saleOrder);

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sale completed successfully!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
        );

        // Navigate back to inventory screen
        Navigator.of(context).popUntil(
          (route) => route.isFirst || route.settings.name == '/inventory',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error completing sale: $e'),
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
        setState(() {
          isProcessing = false;
        });
      }
    }
  }

  Future<void> _generatePDFBill() async {
    try {
      setState(() {
        isProcessing = true;
      });

      final subtotal = widget.saleItems.fold(
        0.0,
        (sum, item) => sum + item.totalPrice,
      );
      final tax = subtotal * 0.18;
      final total = subtotal + tax;

      final pdfService = PDFService();
      final filePath = await pdfService.generateBill(
        shop: widget.shop,
        billNumber: billNumber!,
        dateTime: saleDateTime!,
        customerName:
            widget.customerName.isEmpty
                ? 'Walk-in Customer'
                : widget.customerName,
        customerPhone: widget.customerPhone,
        saleItems: widget.saleItems,
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
        setState(() {
          isProcessing = false;
        });
      }
    }
  }
}
