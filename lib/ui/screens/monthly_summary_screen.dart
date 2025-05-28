import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../models/shop.dart';
import '../../models/transaction.dart';
import '../../providers/shop_provider.dart';
import '../../theme/color.dart';
import '../../theme/style.dart';

class MonthlySummaryScreen extends StatefulWidget {
  final Shop shop;

  const MonthlySummaryScreen({super.key, required this.shop});

  @override
  _MonthlySummaryScreenState createState() => _MonthlySummaryScreenState();
}

class _MonthlySummaryScreenState extends State<MonthlySummaryScreen> {
  DateTime selectedMonth = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          'Monthly Summary',
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
      ),
      body: Consumer<ShopProvider>(
        builder: (context, shopProvider, child) {
          return FutureBuilder<List<Transaction>>(
            future: shopProvider.getMonthlyTransactions(widget.shop.id, selectedMonth),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: Container(
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
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          color: AppColors.primaryBlue,
                          strokeWidth: 3.w,
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          'Loading summary...',
                          style: AppTextStyles.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                );
              }

              final transactions = snapshot.data ?? [];
              final totalSales = transactions.fold(0.0, (sum, trans) => sum + trans.totalAmount);
              final totalItems = transactions.fold(0, (sum, trans) => sum + trans.quantity);

              return SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.all(24.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Month Selection Header
                      _buildMonthSelectorCard(),
                      SizedBox(height: 20.h),

                      // Summary Statistics Cards
                      _buildSummaryStatsGrid(totalSales, totalItems, transactions.length),
                      SizedBox(height: 20.h),

                      // Sales Chart Section
                      _buildSalesChartCard(transactions),
                      SizedBox(height: 20.h),

                      // Recent Transactions Section
                      _buildTransactionsCard(transactions),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildMonthSelectorCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowBlue,
            blurRadius: 15.r,
            spreadRadius: 2.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              gradient: AppColors.lightGradient,
              borderRadius: BorderRadius.circular(12.r),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowBlueStrong,
                  blurRadius: 10.r,
                  offset: Offset(0, 4.h),
                ),
              ],
            ),
            child: Icon(
              Icons.calendar_month,
              color: AppColors.textOnPrimary,
              size: 24.sp,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selected Period',
                  style: AppTextStyles.bodySmall,
                ),
                SizedBox(height: 4.h),
                Text(
                  _getMonthYear(selectedMonth),
                  style: AppTextStyles.headingMedium,
                ),
              ],
            ),
          ),
          IconButton(
            icon: Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: AppColors.blueTinted,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(
                Icons.edit_calendar,
                color: AppColors.primaryBlue,
                size: 20.sp,
              ),
            ),
            onPressed: () => _selectMonth(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStatsGrid(double totalSales, int totalItems, int transactionCount) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Sales',
                '₹${totalSales.toStringAsFixed(2)}',
                Icons.currency_rupee_rounded,
                AppColors.success,
                AppColors.success.withOpacity(0.1),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _buildStatCard(
                'Items Sold',
                totalItems.toString(),
                Icons.shopping_cart,
                AppColors.primaryBlue,
                AppColors.blueTinted,
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        _buildStatCard(
          'Total Transactions',
          transactionCount.toString(),
          Icons.receipt_long,
          AppColors.warning,
          AppColors.warning.withOpacity(0.1),
          fullWidth: true,
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, Color bgColor, {bool fullWidth = false}) {
    return Container(
      width: fullWidth ? double.infinity : null,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            value,
            style: AppTextStyles.headingLarge.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
              fontSize: 24.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSalesChartCard(List<Transaction> transactions) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20.r),
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
            padding: EdgeInsets.all(24.w),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: AppColors.blueTinted,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(
                    Icons.bar_chart,
                    color: AppColors.primaryBlue,
                    size: 20.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Text(
                  'Daily Sales Chart',
                  style: AppTextStyles.headingMedium,
                ),
              ],
            ),
          ),
          Container(
            height: 220.h,
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
            child: _buildSalesChart(transactions),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsCard(List<Transaction> transactions) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20.r),
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
            padding: EdgeInsets.all(24.w),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: AppColors.blueTinted,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(
                    Icons.history,
                    color: AppColors.primaryBlue,
                    size: 20.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Text(
                  'Recent Transactions',
                  style: AppTextStyles.headingMedium,
                ),
              ],
            ),
          ),
          transactions.isEmpty
              ? _buildEmptyTransactionsState()
              : _buildTransactionsList(transactions),
        ],
      ),
    );
  }

  Widget _buildEmptyTransactionsState() {
    return Container(
      padding: EdgeInsets.all(40.w),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: AppColors.blueTinted,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.receipt_outlined,
              size: 40.sp,
              color: AppColors.primaryBlue,
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            'No Transactions',
            style: AppTextStyles.emptyStateTitle.copyWith(fontSize: 18.sp),
          ),
          SizedBox(height: 8.h),
          Text(
            'No transactions found for ${_getMonthYear(selectedMonth)}',
            style: AppTextStyles.emptyStateSubtitle.copyWith(fontSize: 14.sp),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsList(List<Transaction> transactions) {
    return Container(
      constraints: BoxConstraints(maxHeight: 400.h),
      child: ListView.separated(
        shrinkWrap: true,
        padding: EdgeInsets.only(bottom: 16.h),
        itemCount: transactions.length,
        separatorBuilder: (context, index) => Container(
          margin: EdgeInsets.symmetric(horizontal: 24.w),
          height: 1.h,
          color: AppColors.surfaceLight,
        ),
        itemBuilder: (context, index) {
          final transaction = transactions[index];
          return Container(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
            child: Row(
              children: [
                Container(
                  width: 48.w,
                  height: 48.h,
                  decoration: BoxDecoration(
                    gradient: AppColors.lightGradient,
                    borderRadius: BorderRadius.circular(12.r),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryBlue.withOpacity(0.3),
                        blurRadius: 8.r,
                        offset: Offset(0, 2.h),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.shopping_cart,
                    color: Colors.white,
                    size: 24.sp,
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transaction.itemName,
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        transaction.formattedDateTime,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      transaction.formattedTotal,
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.success,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: AppColors.blueTinted,
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Text(
                        'Qty: ${transaction.quantity}',
                        style: TextStyle(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSalesChart(List<Transaction> transactions) {
    if (transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: AppColors.blueTinted,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.bar_chart_outlined,
                size: 32.sp,
                color: AppColors.primaryBlue,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              'No data to display',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    // Group transactions by day
    Map<int, double> dailySales = {};
    for (var transaction in transactions) {
      int day = transaction.dateTime.day;
      dailySales[day] = (dailySales[day] ?? 0) + transaction.totalAmount;
    }

    if (dailySales.isEmpty) {
      return Center(
        child: Text(
          'No data to display',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      );
    }

    final maxSales = dailySales.values.reduce((a, b) => a > b ? a : b);
    final sortedDays = dailySales.keys.toList()..sort();

    return Column(
      children: [
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: sortedDays.take(7).map((day) {
              final sales = dailySales[day] ?? 0;
              final height = maxSales > 0 ? (sales / maxSales) * 120 : 0;

              return Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    width: 24.w,
                    height: height.toDouble(),
                    decoration: BoxDecoration(
                      gradient: AppColors.lightGradient,
                      borderRadius: BorderRadius.circular(6.r),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryBlue.withOpacity(0.3),
                          blurRadius: 4.r,
                          offset: Offset(0, 2.h),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    day.toString(),
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          'Day of Month',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textHint,
          ),
        ),
      ],
    );
  }

  String _getMonthYear(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  void _selectMonth(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDatePickerMode: DatePickerMode.year,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primaryBlue,
              onPrimary: AppColors.textOnPrimary,
              surface: AppColors.cardBackground,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != selectedMonth) {
      setState(() {
        selectedMonth = DateTime(picked.year, picked.month);
      });
    }
  }
}