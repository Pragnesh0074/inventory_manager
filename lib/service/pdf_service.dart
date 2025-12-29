import 'dart:io';
import 'package:inventory_manager/models/sale_order.dart' hide SaleItem;
import 'package:inventory_manager/ui/screens/multi_item_sale_screen.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:flutter/material.dart';
import '../../models/shop.dart';
import 'permission_service.dart';

class PDFService {
  final PermissionService _permissionService = PermissionService();

  Future<String> generateBill({
    required Shop shop,
    required String billNumber,
    required DateTime dateTime,
    required String customerName,
    required String customerPhone,
    required List<SaleItem> saleItems,
    required List<AdditionalCharge> additionalCharges,
    required double subtotal,
    required double tax,
    required double total,
    required double customGSTPercentage,
    required BuildContext context,
  }) async {
    // Check and request permissions first
    if (!await _permissionService.areAllPermissionsGranted()) {
      // Request all permissions at once
      final granted = await _permissionService.requestAllPermissions(context);
      if (!granted) {
        throw Exception('Storage permission not granted');
      }
    }

    final pdf = pw.Document();

    // Add page to PDF
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(20),
        build: (pw.Context context) {
          return [
            // Header
            _buildHeader(shop, billNumber, dateTime),
            pw.SizedBox(height: 20),

            // Customer Info
            _buildCustomerInfo(customerName, customerPhone),
            pw.SizedBox(height: 20),

            // Items Table
            _buildItemsTable(saleItems),
            pw.SizedBox(height: 20),

            // Additional Charges (if any)
            if (additionalCharges.isNotEmpty) ...[
              _buildAdditionalChargesTable(additionalCharges),
              pw.SizedBox(height: 20),
            ],

            // Summary
            _buildSummary(shop, subtotal, tax, total, customGSTPercentage),
            pw.SizedBox(height: 30),

            // Footer
            _buildFooter(),
          ];
        },
      ),
    );

    // Save PDF
    return await _savePDF(pdf, billNumber);
  }

  pw.Widget _buildHeader(Shop shop, String billNumber, DateTime dateTime) {
    return pw.Container(
      padding: pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#E3F2FD'),
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    shop.name,
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromHex('#1976D2'),
                    ),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    shop.address,
                    style: pw.TextStyle(
                      fontSize: 12,
                      color: PdfColor.fromHex('#666666'),
                    ),
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'INVOICE',
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromHex('#1976D2'),
                    ),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    'Bill #$billNumber',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 15),
          pw.Container(
            padding: pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#FFFFFF'),
              borderRadius: pw.BorderRadius.circular(15),
            ),
            child: pw.Text(
              _formatDateTime(dateTime),
              style: pw.TextStyle(
                fontSize: 11,
                color: PdfColor.fromHex('#333333'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildCustomerInfo(String customerName, String customerPhone) {
    return pw.Container(
      padding: pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColor.fromHex('#E0E0E0')),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Bill To:',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#1976D2'),
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            customerName,
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
          if (customerPhone.isNotEmpty) ...[
            pw.SizedBox(height: 3),
            pw.Text(
              'Phone: $customerPhone',
              style: pw.TextStyle(
                fontSize: 11,
                color: PdfColor.fromHex('#666666'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  pw.Widget _buildItemsTable(List<SaleItem> saleItems) {
    return pw.Table(
      border: pw.TableBorder.all(
        color: PdfColor.fromHex('#E0E0E0'),
        width: 0.5,
      ),
      columnWidths: {
        0: const pw.FlexColumnWidth(3), // Item Name & Description
        1: const pw.FlexColumnWidth(1.5), // Unit Price
        2: const pw.FlexColumnWidth(1.2), // GST %
        3: const pw.FlexColumnWidth(1.5), // Price + GST
        4: const pw.FlexColumnWidth(1), // Qty
        5: const pw.FlexColumnWidth(1.8), // Total
      },
      children: [
        // Header Row
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColor.fromHex('#1976D2')),
          children: [
            _buildTableHeaderCell('Item Details'),
            _buildTableHeaderCell('Unit Price'),
            _buildTableHeaderCell('GST %'),
            _buildTableHeaderCell('Price + GST'),
            _buildTableHeaderCell('Qty'),
            _buildTableHeaderCell('Total'),
          ],
        ),
        // Data Rows
        ...saleItems.map((saleItem) {
          // Calculate GST for this item (assuming same GST % for all items)
          final gstPercentage = 18.0; // You can make this dynamic
          final unitPriceBeforeGST =
              saleItem.unitPrice / (1 + gstPercentage / 100);
          final totalPrice = saleItem.unitPrice * saleItem.quantity;

          return pw.TableRow(
            children: [
              // Item Name & Description
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      saleItem.itemName,
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromHex('#000000'),
                      ),
                    ),
                    if (saleItem.description != null &&
                        saleItem.description!.isNotEmpty)
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(top: 3),
                        child: pw.Text(
                          saleItem.description!,
                          style: pw.TextStyle(
                            fontSize: 8,
                            fontStyle: pw.FontStyle.italic,
                            color: PdfColor.fromHex('#666666'),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Unit Price (before GST)
              _buildTableDataCell(
                'Rs. ${unitPriceBeforeGST.toStringAsFixed(2)}',
                align: pw.TextAlign.right,
              ),
              // GST %
              _buildTableDataCell(
                '${gstPercentage.toStringAsFixed(0)}%',
                align: pw.TextAlign.center,
              ),
              // Price + GST
              _buildTableDataCell(
                'Rs. ${saleItem.unitPrice.toStringAsFixed(2)}',
                align: pw.TextAlign.right,
                isBold: true,
              ),
              // Quantity
              _buildTableDataCell(
                saleItem.quantity.toStringAsFixed(0),
                align: pw.TextAlign.center,
              ),
              // Total
              _buildTableDataCell(
                'Rs. ${totalPrice.toStringAsFixed(2)}',
                align: pw.TextAlign.right,
                isBold: true,
                color: PdfColor.fromHex('#1976D2'),
              ),
            ],
          );
        }),
      ],
    );
  }

  pw.Widget _buildTableHeaderCell(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: pw.FontWeight.bold,
          color: PdfColor.fromHex('#FFFFFF'),
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  pw.Widget _buildTableDataCell(
    String text, {
    pw.TextAlign align = pw.TextAlign.left,
    bool isBold = false,
    PdfColor? color,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: color ?? PdfColor.fromHex('#333333'),
        ),
        textAlign: align,
      ),
    );
  }

  pw.Widget _buildAdditionalChargesTable(
    List<AdditionalCharge> additionalCharges,
  ) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColor.fromHex('#E0E0E0')),
      children: [
        // Header Row
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColor.fromHex('#F5F5F5')),
          children: [
            _buildTableCell('Additional Charges', isHeader: true),
            _buildTableCell('Amount', isHeader: true),
          ],
        ),
        // Data Rows
        ...additionalCharges
            .map(
              (charge) => pw.TableRow(
                children: [
                  _buildTableCell(charge.name),
                  _buildTableCell('Rs. ${charge.amount.toStringAsFixed(2)}'),
                ],
              ),
            )
            .toList(),
      ],
    );
  }

  pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Container(
      padding: pw.EdgeInsets.all(10),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 12 : 11,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          color:
              isHeader
                  ? PdfColor.fromHex('#333333')
                  : PdfColor.fromHex('#666666'),
        ),
        textAlign: isHeader ? pw.TextAlign.center : pw.TextAlign.left,
      ),
    );
  }

  pw.Widget _buildSummary(
    Shop shop,
    double subtotal,
    double tax,
    double total,
    double customGSTPercentage,
  ) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Left side - Terms & Conditions
        pw.Expanded(
          flex: 3,
          child: pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColor.fromHex('#E0E0E0')),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Terms & Conditions',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromHex('#1976D2'),
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  '- Payment due within 30 days\n'
                  '- Goods once sold will not be taken back\n'
                  '- All disputes subject to local jurisdiction',
                  style: pw.TextStyle(
                    fontSize: 8,
                    color: PdfColor.fromHex('#666666'),
                  ),
                ),
              ],
            ),
          ),
        ),
        pw.SizedBox(width: 15),
        // Right side - Bill Summary
        pw.Expanded(
          flex: 2,
          child: pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#F8F9FA'),
              borderRadius: pw.BorderRadius.circular(8),
              border: pw.Border.all(color: PdfColor.fromHex('#E0E0E0')),
            ),
            child: pw.Column(
              children: [
                _buildSummaryRow(
                  'Subtotal:',
                  'Rs. ${subtotal.toStringAsFixed(2)}',
                  false,
                ),
                pw.SizedBox(height: 6),
                _buildSummaryRow(
                  'GST (${customGSTPercentage.toStringAsFixed(1)}%):',
                  'Rs. ${tax.toStringAsFixed(2)}',
                  false,
                ),
                pw.SizedBox(height: 10),
                pw.Container(height: 1, color: PdfColor.fromHex('#1976D2')),
                pw.SizedBox(height: 10),
                _buildSummaryRow(
                  'Total Amount:',
                  'Rs. ${total.toStringAsFixed(2)}',
                  true,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  pw.Widget _buildSummaryRow(String label, String value, bool isTotal) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: isTotal ? 11 : 9,
            fontWeight: isTotal ? pw.FontWeight.bold : pw.FontWeight.normal,
            color: PdfColor.fromHex(isTotal ? '#1976D2' : '#666666'),
          ),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: isTotal ? 13 : 10,
            fontWeight: pw.FontWeight.bold,
            color: PdfColor.fromHex(isTotal ? '#4CAF50' : '#333333'),
          ),
        ),
      ],
    );
  }

  pw.Widget _buildFooter() {
    return pw.Column(
      children: [
        pw.SizedBox(height: 30),
        // Signature Section
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            // Customer Signature
            pw.Container(
              width: 200,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    height: 50,
                    decoration: pw.BoxDecoration(
                      border: pw.Border(
                        bottom: pw.BorderSide(
                          color: PdfColor.fromHex('#000000'),
                          width: 1,
                        ),
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    'Customer Signature',
                    style: pw.TextStyle(
                      fontSize: 9,
                      color: PdfColor.fromHex('#666666'),
                    ),
                  ),
                ],
              ),
            ),
            // Authorized Signature
            pw.Container(
              width: 200,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Container(
                    height: 50,
                    decoration: pw.BoxDecoration(
                      border: pw.Border(
                        bottom: pw.BorderSide(
                          color: PdfColor.fromHex('#000000'),
                          width: 1,
                        ),
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    'Authorized Signature',
                    style: pw.TextStyle(
                      fontSize: 9,
                      color: PdfColor.fromHex('#666666'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 25),
        // Thank you message
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: PdfColor.fromHex('#E3F2FD'),
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Column(
            children: [
              pw.Text(
                'Thank You for Your Business!',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromHex('#1976D2'),
                ),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'This is a computer-generated invoice and does not require a physical signature.',
                style: pw.TextStyle(
                  fontSize: 8,
                  color: PdfColor.fromHex('#666666'),
                ),
                textAlign: pw.TextAlign.center,
              ),
            ],
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

  Future<String> _savePDF(pw.Document pdf, String billNumber) async {
    // Get the directory for saving PDF
    Directory? directory;
    if (Platform.isAndroid) {
      directory = await getExternalStorageDirectory();
      // Create a subdirectory for bills
      final billsDir = Directory('${directory!.path}/Bills');
      if (!await billsDir.exists()) {
        await billsDir.create(recursive: true);
      }
      directory = billsDir;
    } else {
      directory = await getApplicationDocumentsDirectory();
    }

    // Create file path
    final fileName =
        'Bill_${billNumber}_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final filePath = '${directory.path}/$fileName';
    final file = File(filePath);

    // Save PDF to file
    await file.writeAsBytes(await pdf.save());

    return filePath;
  }

  Future<void> openPDF(String filePath) async {
    try {
      final result = await OpenFile.open(filePath);
      if (result.type != ResultType.done) {
        throw Exception('Could not open PDF: ${result.message}');
      }
    } catch (e) {
      throw Exception('Error opening PDF: $e');
    }
  }

  // Method to share PDF (optional)
  Future<void> sharePDF(String filePath) async {
    try {
      // You can implement share functionality here using share_plus package
      // await Share.shareFiles([filePath], text: 'Invoice Bill');
    } catch (e) {
      throw Exception('Error sharing PDF: $e');
    }
  }
}
