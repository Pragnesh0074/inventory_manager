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
  final List<order_models.AdditionalCharge> additionalCharges;
  final String customerName;
  final String customerPhone;

  const SaleSummaryScreen({
    super.key,
    required this.shop,
    required this.saleItems,
    required this.additionalCharges,
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
  final TextEditingController _paidAmountController = TextEditingController();

  // Modern color scheme matching the uploaded images
  final Color primaryYellow = const Color(0xFFFDB462);
  final Color lightYellow = const Color(0xFFF8F9FA);
  final Color darkGray = const Color(0xFF2D3436);
  final Color lightGray = const Color(0xFFF8F9FA);
  final Color cardShadowColor = const Color(0x0F000000);

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
              primary: primaryYellow,
              onPrimary: darkGray,
              surface: Colors.white,
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
                primary: primaryYellow,
                onPrimary: darkGray,
                surface: Colors.white,
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
          _generateBillNumber();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final itemsSubtotal = widget.saleItems.fold(
      0.0,
          (sum, item) => sum + item.totalPrice,
    );
    final additionalChargesTotal = widget.additionalCharges.fold(
      0.0,
          (sum, charge) => sum + (charge?.totalAmount ?? 0.0),
    );
    final subtotal = itemsSubtotal + additionalChargesTotal;
    final tax = subtotal * 0.18; // 18% GST
    final total = subtotal + tax;
    final totalItems = widget.saleItems.fold(
      0,
          (sum, item) => sum + item.quantity,
    );

    return Scaffold(
      backgroundColor: lightYellow,
      appBar: AppBar(
        title: Text(
          'Sale Summary',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: darkGray,
          ),
        ),
        backgroundColor: primaryYellow,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: darkGray),
          onPressed: () => Navigator.pop(context),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(24.r),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBillHeaderCard(),
              SizedBox(height: 16.h),
              _buildCustomerInfoCard(),
              SizedBox(height: 16.h),
              _buildItemsListCard(),
              SizedBox(height: 16.h),
              if (widget.additionalCharges.isNotEmpty) ...[
                _buildAdditionalChargesCard(),
                SizedBox(height: 16.h),
              ],
              _buildBillSummaryCard(
                itemsSubtotal,
                additionalChargesTotal,
                subtotal,
                tax,
                total,
                totalItems,
              ),
              SizedBox(height: 24.h),
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
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: cardShadowColor,
            spreadRadius: 0,
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  primaryYellow,
                  primaryYellow.withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Icon(
              Icons.receipt_long_outlined,
              color: darkGray,
              size: 32.sp,
            ),
          ),
          SizedBox(height: 20.h),
          Text(
            widget.shop.name,
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.w700,
              color: darkGray,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8.h),
          Text(
            widget.shop.address,
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey[600],
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: primaryYellow.withOpacity(0.2),
              borderRadius: BorderRadius.circular(25.r),
              border: Border.all(
                color: primaryYellow.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Text(
              'Bill #$billNumber',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: darkGray,
              ),
            ),
          ),
          SizedBox(height: 12.h),
          GestureDetector(
            onTap: _selectDateTime,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: lightGray,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: Colors.grey[300]!,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.access_time_outlined,
                    size: 16.sp,
                    color: Colors.grey[600],
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    _formatDateTime(saleDateTime!),
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Icon(
                    Icons.edit_outlined,
                    size: 14.sp,
                    color: primaryYellow.withOpacity(0.8),
                  ),
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
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: cardShadowColor,
              spreadRadius: 0,
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(
                Icons.person_outline,
                color: Colors.grey[600],
                size: 20.sp,
              ),
            ),
            SizedBox(width: 16.w),
            Text(
              'Walk-in Customer',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: cardShadowColor,
            spreadRadius: 0,
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: primaryYellow.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  Icons.person_outline,
                  color: darkGray,
                  size: 20.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Text(
                'Customer Information',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: darkGray,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          if (widget.customerName.isNotEmpty) ...[
            _buildInfoRow('Name', widget.customerName, Icons.person),
            if (widget.customerPhone.isNotEmpty) SizedBox(height: 8.h),
          ],
          if (widget.customerPhone.isNotEmpty)
            _buildInfoRow('Phone', widget.customerPhone, Icons.phone),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16.sp,
          color: Colors.grey[600],
        ),
        SizedBox(width: 8.w),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 14.sp,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14.sp,
            color: darkGray,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildItemsListCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: cardShadowColor,
            spreadRadius: 0,
            blurRadius: 20,
            offset: const Offset(0, 8),
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
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: primaryYellow.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(
                    Icons.shopping_cart_outlined,
                    color: darkGray,
                    size: 20.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Text(
                  'Items Purchased',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: darkGray,
                  ),
                ),
                Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: lightGray,
                    borderRadius: BorderRadius.circular(15.r),
                  ),
                  child: Text(
                    '${widget.saleItems.length} items',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: widget.saleItems.length,
            separatorBuilder: (context, index) => Container(
              margin: EdgeInsets.symmetric(horizontal: 20.w),
              height: 1.h,
              color: lightGray,
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
                            saleItem.itemName,
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: darkGray,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Row(
                            children: [
                              Icon(
                                Icons.currency_rupee,
                                size: 12.sp,
                                color: saleItem.isPriceModified
                                    ? Colors.orange[600]
                                    : Colors.grey[600],
                              ),
                              Text(
                                '${saleItem.unitPrice.toStringAsFixed(2)} each',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: saleItem.isPriceModified
                                      ? Colors.orange[600]
                                      : Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        color: primaryYellow.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(15.r),
                      ),
                      child: Text(
                        '×${saleItem.quantity}',
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: darkGray,
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Text(
                      '₹${saleItem.totalPrice.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF27AE60),
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

  Widget _buildAdditionalChargesCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: cardShadowColor,
            spreadRadius: 0,
            blurRadius: 20,
            offset: const Offset(0, 8),
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
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: Colors.orange[100],
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(
                    Icons.add_circle_outline,
                    color: Colors.orange[600],
                    size: 20.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Text(
                  'Additional Charges',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: darkGray,
                  ),
                ),
              ],
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: widget.additionalCharges.length,
            separatorBuilder: (context, index) => Container(
              margin: EdgeInsets.symmetric(horizontal: 20.w),
              height: 1.h,
              color: lightGray,
            ),
            itemBuilder: (context, index) {
              final charge = widget.additionalCharges[index];
              return Container(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        charge?.name ?? '',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: darkGray,
                        ),
                      ),
                    ),
                    Text(
                      '₹${(charge?.amount ?? 0.0).toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.orange[600],
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
      double itemsSubtotal,
      double additionalChargesTotal,
      double subtotal,
      double tax,
      double total,
      int totalItems,
      ) {
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: cardShadowColor,
            spreadRadius: 0,
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF667EEA),
                      const Color(0xFF764BA2),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  Icons.calculate_outlined,
                  color: Colors.white,
                  size: 20.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Text(
                'Bill Summary',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: darkGray,
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: lightGray,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Column(
              children: [
                _buildSummaryRow('Items Count:', '$totalItems items', false),
                SizedBox(height: 8.h),
                _buildSummaryRow('Items Subtotal:', '₹${itemsSubtotal.toStringAsFixed(2)}', false),
                if (additionalChargesTotal > 0) ...[
                  SizedBox(height: 8.h),
                  _buildSummaryRow('Additional Charges:', '₹${additionalChargesTotal.toStringAsFixed(2)}', false),
                ],
                SizedBox(height: 8.h),
                _buildSummaryRow('Subtotal:', '₹${subtotal.toStringAsFixed(2)}', false),
                SizedBox(height: 8.h),
                _buildSummaryRow('GST (18%):', '₹${tax.toStringAsFixed(2)}', false),
              ],
            ),
          ),
          SizedBox(height: 16.h),
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF27AE60).withOpacity(0.1),
                  const Color(0xFF27AE60).withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: const Color(0xFF27AE60).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Amount:',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: darkGray,
                  ),
                ),
                Text(
                  '₹${total.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF27AE60),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20.h),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Amount Paid Now',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: darkGray,
                ),
              ),
              SizedBox(height: 8.h),
              TextField(
                controller: _paidAmountController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  prefixIcon: Icon(
                    Icons.payments_outlined,
                    color: Colors.grey[600],
                  ),
                  hintText: '0.00',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  filled: true,
                  fillColor: lightGray,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(color: primaryYellow, width: 2),
                  ),
                ),
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: darkGray,
                ),
              ),
            ],
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
            fontSize: 13.sp,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: darkGray,
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
            gradient: LinearGradient(
              colors: [
                const Color(0xFF27AE60),
                const Color(0xFF2ECC71),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF27AE60).withOpacity(0.3),
                spreadRadius: 0,
                blurRadius: 20,
                offset: const Offset(0, 8),
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
            child: isProcessing
                ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 20.w,
                  height: 20.h,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.w,
                  ),
                ),
                SizedBox(width: 12.w),
                Text(
                  'Processing...',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            )
                : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  color: Colors.white,
                  size: 24.sp,
                ),
                SizedBox(width: 12.w),
                Text(
                  'Complete Sale',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
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
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: const Color(0xFF3498DB),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: cardShadowColor,
                spreadRadius: 0,
                blurRadius: 15,
                offset: const Offset(0, 4),
              ),
            ],
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
                  Icons.picture_as_pdf_outlined,
                  color: const Color(0xFF3498DB),
                  size: 24.sp,
                ),
                SizedBox(width: 12.w),
                Text(
                  'Generate PDF Bill',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF3498DB),
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
              backgroundColor: lightGray,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
            child: Text(
              'Back to Edit',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14.sp,
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
    final hour = dateTime.hour == 0
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
      final itemsSubtotal = widget.saleItems.fold(
        0.0,
            (sum, item) => sum + item.totalPrice,
      );
      final additionalChargesTotal = widget.additionalCharges.fold(
        0.0,
            (sum, charge) => sum + charge.totalAmount,
      );
      final subtotal = itemsSubtotal + additionalChargesTotal;
      final tax = subtotal * 0.18;
      final total = subtotal + tax;
      final paidAmount = double.tryParse(_paidAmountController.text) ?? 0.0;

      // Create sale order
      final saleOrder = order_models.SaleOrder(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        shopId: widget.shop.id,
        items: widget.saleItems
            .map(
              (item) => order_models.SaleItem(
            item: item.item,
            temporaryItemName: item.temporaryItemName,
            temporaryItemPrice: item.temporaryItemPrice,
            quantity: item.quantity,
            unitPrice: item.unitPrice,
          ),
        )
            .toList(),
        additionalCharges: widget.additionalCharges
            .map(
              (charge) => order_models.AdditionalCharge(
            name: charge?.name ?? '',
            amount: charge?.amount ?? 0.0,
          ),
        )
            .toList(),
        customerName: widget.customerName.isEmpty
            ? 'Walk-in Customer'
            : widget.customerName,
        customerPhone: widget.customerPhone,
        dateTime: saleDateTime!,
        subtotal: subtotal,
        tax: tax,
        total: total,
        billNumber: billNumber!,
        paidAmount: paidAmount,
      );

      // Create the sale order (this will also update inventory)
      await shopProvider.createSaleOrder(widget.shop.id, saleOrder);

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8.w),
                Text('Sale completed successfully!'),
              ],
            ),
            backgroundColor: const Color(0xFF27AE60),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            margin: EdgeInsets.all(16.w),
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
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 8.w),
                Expanded(child: Text('Error completing sale: $e')),
              ],
            ),
            backgroundColor: Colors.red[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            margin: EdgeInsets.all(16.w),
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

      final itemsSubtotal = widget.saleItems.fold(
        0.0,
            (sum, item) => sum + item.totalPrice,
      );
      final additionalChargesTotal = widget.additionalCharges.fold(
        0.0,
            (sum, charge) => sum + charge.totalAmount,
      );
      final subtotal = itemsSubtotal + additionalChargesTotal;
      final tax = subtotal * 0.18;
      final total = subtotal + tax;

      final pdfService = PDFService();
      final filePath = await pdfService.generateBill(
        shop: widget.shop,
        billNumber: billNumber!,
        dateTime: saleDateTime!,
        customerName: widget.customerName.isEmpty
            ? 'Walk-in Customer'
            : widget.customerName,
        customerPhone: widget.customerPhone,
        saleItems: widget.saleItems,
        additionalCharges: widget.additionalCharges,
        subtotal: subtotal,
        tax: tax,
        total: total,
        context: context,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.picture_as_pdf, color: Colors.white),
                SizedBox(width: 8.w),
                Text('PDF bill generated successfully!'),
              ],
            ),
            backgroundColor: const Color(0xFF3498DB),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            margin: EdgeInsets.all(16.w),
          ),
        );
        pdfService.openPDF(filePath);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 8.w),
                Expanded(child: Text('Error generating PDF: $e')),
              ],
            ),
            backgroundColor: Colors.red[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            margin: EdgeInsets.all(16.w),
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