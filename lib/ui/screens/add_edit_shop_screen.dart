import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../models/shop.dart';
import '../../providers/shop_provider.dart';
import '../../theme/color.dart';
import '../../theme/style.dart';

class AddEditShopScreen extends StatefulWidget {
  final Shop? shop;

  const AddEditShopScreen({super.key, this.shop});

  @override
  _AddEditShopScreenState createState() => _AddEditShopScreenState();
}

class _AddEditShopScreenState extends State<AddEditShopScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _gstController = TextEditingController();
  final _nameFocusNode = FocusNode();
  final _addressFocusNode = FocusNode();
  final _gstFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    if (widget.shop != null) {
      _nameController.text = widget.shop!.name;
      _addressController.text = widget.shop!.address;
      _gstController.text = widget.shop!.gstPercentage.toString();
    } else {
      _gstController.text = '18.0'; // Default GST percentage
    }

    // Add focus listeners to trigger UI updates
    _nameFocusNode.addListener(() => setState(() {}));
    _addressFocusNode.addListener(() => setState(() {}));
    _gstFocusNode.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.shop != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: Text(
          isEditing ? 'Edit Shop' : 'Add New Shop',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        backgroundColor: const Color(0xFFF5F6FA),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Container(
            padding: EdgeInsets.all(8.r),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.arrow_back_ios_new,
              color: Colors.black87,
              size: 18.r,
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(24.r),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(24.r),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 15,
                        spreadRadius: 1,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 80.w,
                        height: 80.h,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFE5B8),
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: Icon(
                          isEditing ? Icons.edit_outlined : Icons.add_business,
                          size: 36.r,
                          color: const Color(0xFFFF9500),
                        ),
                      ),
                      SizedBox(height: 20.h),
                      Text(
                        isEditing ? 'Update Shop Details' : 'Create New Shop',
                        style: TextStyle(
                          fontSize: 22.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        isEditing
                            ? 'Modify your shop information below'
                            : 'Fill in the details to create your new shop',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.grey[600],
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 32.h),

                // Form Section
                Container(
                  padding: EdgeInsets.all(24.r),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 15,
                        spreadRadius: 1,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Shop Information',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 24.h),

                      _buildInputField(
                        controller: _nameController,
                        focusNode: _nameFocusNode,
                        label: 'Shop Name',
                        hint: 'Enter your shop name',
                        icon: Icons.store_outlined,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter shop name';
                          }
                          if (value.length < 2) {
                            return 'Shop name must be at least 2 characters';
                          }
                          return null;
                        },
                      ),

                      SizedBox(height: 24.h),

                      _buildInputField(
                        controller: _addressController,
                        focusNode: _addressFocusNode,
                        label: 'Shop Address',
                        hint: 'Enter complete shop address',
                        icon: Icons.location_on_outlined,
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter shop address';
                          }
                          if (value.length < 5) {
                            return 'Please enter a valid address';
                          }
                          return null;
                        },
                      ),

                      SizedBox(height: 24.h),

                      _buildInputField(
                        controller: _gstController,
                        focusNode: _gstFocusNode,
                        label: 'GST Percentage (%)',
                        hint: 'Enter GST percentage (e.g., 18.0)',
                        icon: Icons.percent_outlined,
                        keyboardType: TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter GST percentage';
                          }
                          final gst = double.tryParse(value);
                          if (gst == null) {
                            return 'Please enter a valid number';
                          }
                          if (gst < 0 || gst > 100) {
                            return 'GST must be between 0 and 100';
                          }
                          return null;
                        },
                      ),

                      SizedBox(height: 24.h),
                    ],
                  ),
                ),

                SizedBox(height: 32.h),

                // Action Buttons
                Column(
                  children: [
                    Container(
                      width: double.infinity,
                      height: 56.h,
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(16.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _saveShop,
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
                              isEditing ? Icons.update : Icons.add_business,
                              color: Colors.white,
                              size: 20.r,
                            ),
                            SizedBox(width: 12.w),
                            Text(
                              isEditing ? 'UPDATE SHOP' : 'CREATE SHOP',
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: 16.h),

                    SizedBox(
                      width: double.infinity,
                      height: 56.h,
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.grey[100],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                        ),
                        child: Text(
                          'CANCEL',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[600],
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 40.h), // Bottom padding
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    final isFocused = focusNode.hasFocus;
    final hasError = _formKey.currentState?.validate() == false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 12.h),
        Container(
          decoration: BoxDecoration(
            color:
                isFocused ? const Color(0xFFF0F8FF) : const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color:
                  isFocused
                      ? const Color(0xFF4A90E2)
                      : Colors.grey.withOpacity(0.2),
              width: isFocused ? 2.w : 1.w,
            ),
            boxShadow:
                isFocused
                    ? [
                      BoxShadow(
                        color: const Color(0xFF4A90E2).withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                    : null,
          ),
          child: TextFormField(
            controller: controller,
            focusNode: focusNode,
            maxLines: maxLines,
            keyboardType: keyboardType,
            style: TextStyle(
              fontSize: 16.sp,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                fontSize: 16.sp,
                color: Colors.grey[500],
                fontWeight: FontWeight.w400,
              ),
              prefixIcon: Container(
                margin: EdgeInsets.all(12.r),
                width: 40.w,
                height: 40.h,
                decoration: BoxDecoration(
                  color:
                      isFocused
                          ? const Color(0xFF4A90E2).withOpacity(0.1)
                          : const Color(0xFFFFE5B8),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  icon,
                  color:
                      isFocused
                          ? const Color(0xFF4A90E2)
                          : const Color(0xFFFF9500),
                  size: 20.r,
                ),
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: maxLines > 1 ? 16.h : 20.h,
              ),
              errorStyle: TextStyle(
                color: Colors.red[400],
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
                height: 1.2,
              ),
            ),
            validator: validator,
            onTap: () => setState(() {}),
            onEditingComplete: () => setState(() {}),
          ),
        ),
      ],
    );
  }

  void _saveShop() {
    if (_formKey.currentState!.validate()) {
      final shopProvider = Provider.of<ShopProvider>(context, listen: false);

      if (widget.shop != null) {
        final updatedShop = Shop(
          id: widget.shop!.id,
          name: _nameController.text.trim(),
          address: _addressController.text.trim(),
          gstPercentage: double.tryParse(_gstController.text) ?? 18.0,
          createdDate: widget.shop!.createdDate,
          inventory: widget.shop!.inventory,
          transactions: widget.shop!.transactions,
        );
        shopProvider.updateShop(updatedShop);

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(6.r),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(Icons.check, color: Colors.white, size: 16.r),
                ),
                SizedBox(width: 12.w),
                Text(
                  'Shop updated successfully!',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green[400],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            margin: EdgeInsets.all(16.r),
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        final newShop = Shop(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: _nameController.text.trim(),
          address: _addressController.text.trim(),
          gstPercentage: double.tryParse(_gstController.text) ?? 18.0,
          createdDate: DateTime.now(),
        );
        shopProvider.addShop(newShop);

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(6.r),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(Icons.check, color: Colors.white, size: 16.r),
                ),
                SizedBox(width: 12.w),
                Text(
                  'Shop created successfully!',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green[400],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            margin: EdgeInsets.all(16.r),
            duration: const Duration(seconds: 2),
          ),
        );
      }

      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _gstController.dispose();
    _nameFocusNode.dispose();
    _addressFocusNode.dispose();
    _gstFocusNode.dispose();
    super.dispose();
  }
}
