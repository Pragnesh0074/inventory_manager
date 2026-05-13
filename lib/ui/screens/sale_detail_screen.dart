import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:stockly/models/sale_order.dart';
import 'package:stockly/service/pdf_service.dart';
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
          'SALE DETAILS',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
        actions: [
          Container(
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
                Icons.picture_as_pdf,
                color: const Color(0xFF6C5CE7),
                size: 18.sp,
              ),
              onPressed:
                  isProcessing
                      ? null
                      : () => _generatePDFBill(subtotal, tax, total),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Section
            Container(
              width: double.infinity,
              margin: EdgeInsets.all(16.w),
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Shop icon
                  Container(
                    width: 60.w,
                    height: 60.w,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6C5CE7).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    child: Icon(
                      Icons.store,
                      color: const Color(0xFF6C5CE7),
                      size: 30.sp,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    widget.shop.name,
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    widget.shop.address,
                    style: TextStyle(fontSize: 13.sp, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16.h),
                  // Bill number badge
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 8.h,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5E6A8),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Text(
                      'Bill #${_generateBillNumber(widget.saleOrder)}',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    _formatDateTime(widget.saleOrder.dateTime),
                    style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),

            // Content Section
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24.r),
                  topRight: Radius.circular(24.r),
                ),
              ),
              child: Column(
                children: [
                  SizedBox(height: 20.h),

                  // Customer Info
                  if (saleOrder.customerName.isNotEmpty ||
                      saleOrder.customerPhone.isNotEmpty)
                    _buildCustomerInfoCard(),

                  SizedBox(height: 16.h),

                  // Items Section
                  _buildSaleItemsCard(),

                  SizedBox(height: 16.h),

                  // Additional Charges
                  if (widget.saleOrder.additionalCharges.isNotEmpty) ...[
                    _buildAdditionalChargesCard(),
                    SizedBox(height: 16.h),
                  ],

                  // Bill Summary
                  _buildBillSummaryCard(subtotal, tax, total),

                  SizedBox(height: 24.h),

                  // Generate PDF Button
                  _buildActionButtons(subtotal, tax, total),

                  SizedBox(height: 24.h),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerInfoCard() {
    final saleOrder = widget.saleOrder;
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(6.w),
                decoration: BoxDecoration(
                  color: const Color(0xFF6C5CE7).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  Icons.person_outline,
                  color: const Color(0xFF6C5CE7),
                  size: 16.sp,
                ),
              ),
              SizedBox(width: 10.w),
              Text(
                'Customer Information',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          if (saleOrder.customerName.isNotEmpty ||
              saleOrder.customerPhone.isNotEmpty) ...[
            SizedBox(height: 12.h),
            if (saleOrder.customerName.isNotEmpty)
              Text(
                saleOrder.customerName,
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            if (saleOrder.customerPhone.isNotEmpty)
              Text(
                saleOrder.customerPhone,
                style: TextStyle(fontSize: 13.sp, color: Colors.grey[600]),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildSaleItemsCard() {
    final saleOrder = widget.saleOrder;
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00B894).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(
                    Icons.shopping_cart_outlined,
                    color: const Color(0xFF00B894),
                    size: 18.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Text(
                  'Items Purchased',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 4.h,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5E6A8),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    '${saleOrder.items.length} items',
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(height: 1, color: Colors.grey.withOpacity(0.2)),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.all(16.w),
            itemCount: saleOrder.items.length,
            separatorBuilder: (context, index) => SizedBox(height: 12.h),
            itemBuilder: (context, index) {
              final item = saleOrder.items[index];
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                item.itemName,
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            if (item.isTemporaryItem) ...[
                              SizedBox(width: 6.w),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 6.w,
                                  vertical: 2.h,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4.r),
                                  border: Border.all(
                                    color: Colors.orange.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  'Temp',
                                  style: TextStyle(
                                    fontSize: 8.sp,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.orange,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (item.description != null &&
                            item.description!.isNotEmpty) ...[
                          SizedBox(height: 2.h),
                          Text(
                            item.description!,
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                        SizedBox(height: 2.h),
                        Text(
                          '₹${item.unitPrice.toStringAsFixed(2)} each',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6C5CE7).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      '×${item.quantity}',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF6C5CE7),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Text(
                    '₹${item.totalPrice.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF00B894),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalChargesCard() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(
                    Icons.add_circle_outline,
                    color: Colors.blue,
                    size: 18.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Text(
                  'Additional Charges',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          Container(height: 1, color: Colors.grey.withOpacity(0.2)),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.all(16.w),
            itemCount: widget.saleOrder.additionalCharges.length,
            separatorBuilder: (context, index) => SizedBox(height: 8.h),
            itemBuilder: (context, index) {
              final charge = widget.saleOrder.additionalCharges[index];
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    charge.name,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    '₹${charge.amount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF00B894),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
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
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C5CE7).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(
                    Icons.calculate,
                    color: const Color(0xFF6C5CE7),
                    size: 18.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Text(
                  'Bill Summary',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          Container(height: 1, color: Colors.grey.withOpacity(0.2)),
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              children: [
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
                _buildSummaryRow(
                  'GST (${subtotal > 0 ? (tax / subtotal * 100).toStringAsFixed(1) : widget.shop.gstPercentage.toStringAsFixed(1)}%):',
                  '₹${tax.toStringAsFixed(2)}',
                  false,
                ),
                SizedBox(height: 12.h),
                Container(height: 1, color: Colors.grey.withOpacity(0.3)),
                SizedBox(height: 12.h),
                _buildSummaryRow(
                  'Total Amount:',
                  '₹${total.toStringAsFixed(2)}',
                  true,
                ),
              ],
            ),
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
          style: TextStyle(
            fontSize: isTotal ? 15.sp : 13.sp,
            fontWeight: isTotal ? FontWeight.w600 : FontWeight.w500,
            color: isTotal ? Colors.black87 : Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 16.sp : 14.sp,
            fontWeight: isTotal ? FontWeight.w700 : FontWeight.w600,
            color: isTotal ? const Color(0xFF00B894) : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(double subtotal, double tax, double total) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      width: double.infinity,
      height: 50.h,
      child: ElevatedButton(
        onPressed:
            isProcessing ? null : () => _generatePDFBill(subtotal, tax, total),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6C5CE7),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isProcessing)
              SizedBox(
                width: 20.w,
                height: 20.h,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            else
              Icon(Icons.picture_as_pdf, size: 20.sp),
            SizedBox(width: 8.w),
            Text(
              isProcessing ? 'Generating...' : 'Generate PDF Bill',
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
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
                description: item.description,
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
                description: item.description,
              );
            }
          }).toList();

      // Calculate the GST percentage from the existing sale data
      final calculatedGSTPercentage =
          subtotal > 0 ? (tax / subtotal) * 100 : widget.shop.gstPercentage;

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
        customGSTPercentage: calculatedGSTPercentage,
        context: context,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF bill generated successfully!'),
            backgroundColor: const Color(0xFF00B894),
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
            backgroundColor: Colors.red,
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
