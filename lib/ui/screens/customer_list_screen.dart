import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../models/customer.dart';
import '../../models/shop.dart';
import '../../providers/shop_provider.dart';
import '../../theme/color.dart';
import '../../theme/style.dart';
import '../../database/database_helper.dart';

class CustomerListScreen extends StatefulWidget {
  final Shop shop;

  const CustomerListScreen({super.key, required this.shop});

  @override
  _CustomerListScreenState createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  List<Customer> customers = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    setState(() {
      isLoading = true;
    });

    try {
      final dbHelper = DatabaseHelper();
      final customerList = await dbHelper.getCustomers(widget.shop.id);
      setState(() {
        customers = customerList;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading customers: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFDB462),
        elevation: 0,
        title: Text(
          'CUSTOMERS',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.black, size: 20.sp),
          onPressed: () => Navigator.pop(context),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(24.r)),
        ),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : customers.isEmpty
              ? Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.w),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 120.w,
                          height: 120.h,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFDB462).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(60.r),
                          ),
                          child: Icon(
                            Icons.people_outline,
                            size: 60.sp,
                            color: const Color(0xFFFDB462),
                          ),
                        ),
                        SizedBox(height: 32.h),
                        Text(
                          'No Customers Yet',
                          style: TextStyle(
                            fontSize: 24.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 12.h),
                        Text(
                          'Customers will appear here when you\ncreate sales with new customers',
                          style: TextStyle(
                            fontSize: 16.sp,
                            color: Colors.grey.shade600,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    // Summary card
                    Container(
                      margin: EdgeInsets.all(16.w),
                      padding: EdgeInsets.all(20.w),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4A90E2),
                        borderRadius: BorderRadius.circular(24.r),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF4A90E2).withOpacity(0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 60.w,
                            height: 60.h,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(30.r),
                            ),
                            child: Icon(
                              Icons.people,
                              color: Colors.white,
                              size: 30.sp,
                            ),
                          ),
                          SizedBox(width: 20.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${customers.length}',
                                  style: TextStyle(
                                    fontSize: 32.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  'Total Customers',
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    color: Colors.white.withOpacity(0.9),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Customer list
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _loadCustomers,
                        child: ListView.builder(
                          padding: EdgeInsets.symmetric(horizontal: 16.w),
                          itemCount: customers.length,
                          itemBuilder: (context, index) {
                            final customer = customers[index];
                            return Container(
                              margin: EdgeInsets.only(bottom: 16.h),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20.r),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
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
                                          width: 56.w,
                                          height: 56.h,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF4A90E2).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(28.r),
                                          ),
                                          child: Icon(
                                            Icons.person,
                                            color: const Color(0xFF4A90E2),
                                            size: 28.sp,
                                          ),
                                        ),
                                        SizedBox(width: 16.w),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                customer.name,
                                                style: TextStyle(
                                                  fontSize: 18.sp,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                              SizedBox(height: 4.h),
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.phone,
                                                    size: 14.sp,
                                                    color: Colors.grey[600],
                                                  ),
                                                  SizedBox(width: 6.w),
                                                  Text(
                                                    customer.phone,
                                                    style: TextStyle(
                                                      fontSize: 14.sp,
                                                      color: Colors.grey[600],
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          decoration: BoxDecoration(
                                            color: Colors.red.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(20.r),
                                          ),
                                          child: IconButton(
                                            onPressed: () => _showDeleteDialog(customer),
                                            icon: Icon(
                                              Icons.delete_outline,
                                              color: Colors.red[400],
                                              size: 20.sp,
                                            ),
                                            tooltip: 'Delete Customer',
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (customer.address != null && customer.address!.isNotEmpty) ...[
                                      SizedBox(height: 16.h),
                                      Container(
                                        padding: EdgeInsets.all(12.w),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade50,
                                          borderRadius: BorderRadius.circular(12.r),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.location_on_outlined,
                                              size: 16.sp,
                                              color: Colors.grey[600],
                                            ),
                                            SizedBox(width: 8.w),
                                            Expanded(
                                              child: Text(
                                                customer.address!,
                                                style: TextStyle(
                                                  fontSize: 14.sp,
                                                  color: Colors.grey[700],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                    if (customer.email != null && customer.email!.isNotEmpty) ...[
                                      SizedBox(height: 12.h),
                                      Container(
                                        padding: EdgeInsets.all(12.w),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade50,
                                          borderRadius: BorderRadius.circular(12.r),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.email_outlined,
                                              size: 16.sp,
                                              color: Colors.grey[600],
                                            ),
                                            SizedBox(width: 8.w),
                                            Expanded(
                                              child: Text(
                                                customer.email!,
                                                style: TextStyle(
                                                  fontSize: 14.sp,
                                                  color: Colors.grey[700],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                    SizedBox(height: 16.h),
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF4A90E2).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(20.r),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.calendar_today_outlined,
                                            size: 14.sp,
                                            color: const Color(0xFF4A90E2),
                                          ),
                                          SizedBox(width: 6.w),
                                          Text(
                                            'Added: ${_formatDate(customer.createdAt)}',
                                            style: TextStyle(
                                              fontSize: 12.sp,
                                              color: const Color(0xFF4A90E2),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showDeleteDialog(Customer customer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
                size: 24.r,
              ),
            ),
            SizedBox(width: 12.w),
            Text(
              'Delete Customer',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${customer.name}"? This action cannot be undone.',
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
              onPressed: () async {
                Navigator.pop(context);
                await _deleteCustomer(customer);
              },
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(
                  horizontal: 20.w,
                  vertical: 12.h,
                ),
              ),
              child: Text(
                'Delete',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCustomer(Customer customer) async {
    try {
      final dbHelper = DatabaseHelper();
      await dbHelper.deleteCustomer(customer.id);

      // Refresh the customer list
      await _loadCustomers();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Customer "${customer.name}" deleted successfully'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting customer: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
