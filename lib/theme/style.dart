import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:inventory_manager/theme/color.dart';

class AppTextStyles {
  // App Bar Styles
  static TextStyle appBarTitle = TextStyle(
    fontWeight: FontWeight.w600,
    fontSize: 20.sp,
    color: AppColors.textOnPrimary,
  );

  // Heading Styles
  static TextStyle headingLarge = TextStyle(
    fontSize: 22.sp,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  static TextStyle headingMedium = TextStyle(
    fontWeight: FontWeight.w600,
    fontSize: 18.sp,
    color: AppColors.textPrimary,
  );

  // Body Text Styles
  static TextStyle bodyLarge = TextStyle(
    fontSize: 16.sp,
    color: AppColors.textSecondary,
  );

  static TextStyle bodyMedium = TextStyle(
    color: AppColors.textSecondary,
    fontSize: 14.sp,
  );

  static TextStyle bodySmall = TextStyle(
    color: AppColors.blueText,
    fontSize: 12.sp,
    fontWeight: FontWeight.w500,
  );

  // Button Styles
  static TextStyle buttonLarge = TextStyle(
    color: AppColors.textOnPrimary,
    fontSize: 16.sp,
    fontWeight: FontWeight.w500,
  );

  static TextStyle buttonMedium = TextStyle(
    fontWeight: FontWeight.w500,
  );

  // Card Content Styles
  static TextStyle cardTitle = TextStyle(
    fontWeight: FontWeight.w600,
    fontSize: 18.sp,
    color: AppColors.textPrimary,
  );

  static TextStyle cardSubtitle = TextStyle(
    color: AppColors.textSecondary,
    fontSize: 14.sp,
  );

  static TextStyle cardCaption = TextStyle(
    color: AppColors.blueText,
    fontSize: 12.sp,
    fontWeight: FontWeight.w500,
  );

  // Menu Item Styles
  static TextStyle menuItem = TextStyle(
    fontWeight: FontWeight.w500,
  );

  static TextStyle menuItemPrimary = TextStyle(
    color: AppColors.primaryBlue,
    fontWeight: FontWeight.w500,
  );

  static TextStyle menuItemDanger = TextStyle(
    color: AppColors.error,
    fontWeight: FontWeight.w500,
  );

  // Dialog Styles
  static TextStyle dialogTitle = TextStyle(
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static TextStyle dialogContent = TextStyle(
    color: AppColors.textSecondary,
    fontSize: 16.sp,
  );

  static TextStyle dialogButton = TextStyle(
    color: AppColors.textSecondary,
    fontWeight: FontWeight.w500,
  );

  static TextStyle dialogButtonPrimary = TextStyle(
    color: AppColors.textOnPrimary,
    fontWeight: FontWeight.w500,
  );

  // Empty State Styles
  static TextStyle emptyStateTitle = TextStyle(
    fontSize: 22.sp,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  static TextStyle emptyStateSubtitle = TextStyle(
    fontSize: 16.sp,
    color: AppColors.textSecondary,
  );
}