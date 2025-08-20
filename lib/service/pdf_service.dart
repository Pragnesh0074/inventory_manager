import 'dart:io';
import 'package:inventory_manager/ui/screens/multi_item_sale_screen.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../models/shop.dart';

class PDFService {
  Future<String> generateBill({
    required Shop shop,
    required String billNumber,
    required DateTime dateTime,
    required String customerName,
    required String customerPhone,
    required List<SaleItem> saleItems,
    required double subtotal,
    required double tax,
    required double total,
  }) async {
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

            // Summary
            _buildSummary(subtotal, tax, total),
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
                    style: pw.TextStyle(fontSize: 12, color: PdfColor.fromHex('#666666')),
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
                    style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
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
              style: pw.TextStyle(fontSize: 11, color: PdfColor.fromHex('#333333')),
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
              style: pw.TextStyle(fontSize: 11, color: PdfColor.fromHex('#666666')),
            ),
          ],
        ],
      ),
    );
  }

  pw.Widget _buildItemsTable(List<SaleItem> saleItems) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColor.fromHex('#E0E0E0')),
      children: [
        // Header Row
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColor.fromHex('#F5F5F5')),
          children: [
            _buildTableCell('Item Name', isHeader: true),
            _buildTableCell('Unit Price', isHeader: true),
            _buildTableCell('Qty', isHeader: true),
            _buildTableCell('Total', isHeader: true),
          ],
        ),
        // Data Rows
        ...saleItems.map((saleItem) => pw.TableRow(
          children: [
            _buildTableCell(saleItem.item.name),
            _buildTableCell('₹${saleItem.item.price.toStringAsFixed(2)}'),
            _buildTableCell('${saleItem.quantity}'),
            _buildTableCell('₹${saleItem.totalPrice.toStringAsFixed(2)}'),
          ],
        )).toList(),
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
          color: isHeader ? PdfColor.fromHex('#333333') : PdfColor.fromHex('#666666'),
        ),
        textAlign: isHeader ? pw.TextAlign.center : pw.TextAlign.left,
      ),
    );
  }

  pw.Widget _buildSummary(double subtotal, double tax, double total) {
    return pw.Column(
      children: [
        pw.Container(
          padding: pw.EdgeInsets.all(15),
          decoration: pw.BoxDecoration(
            color: PdfColor.fromHex('#F8F9FA'),
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Column(
            children: [
              _buildSummaryRow('Subtotal:', '₹${subtotal.toStringAsFixed(2)}', false),
              pw.SizedBox(height: 8),
              _buildSummaryRow('GST (18%):', '₹${tax.toStringAsFixed(2)}', false),
              pw.SizedBox(height: 15),
              pw.Container(
                height: 1,
                color: PdfColor.fromHex('#DDD'),
              ),
              pw.SizedBox(height: 15),
              _buildSummaryRow('Total Amount:', '₹${total.toStringAsFixed(2)}', true),
            ],
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
            fontSize: isTotal ? 14 : 12,
            fontWeight: isTotal ? pw.FontWeight.bold : pw.FontWeight.normal,
            color: isTotal ? PdfColor.fromHex('#1976D2') : PdfColor.fromHex('#666666'),
          ),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: isTotal ? 16 : 12,
            fontWeight: pw.FontWeight.bold,
            color: isTotal ? PdfColor.fromHex('#4CAF50') : PdfColor.fromHex('#333333'),
          ),
        ),
      ],
    );
  }

  pw.Widget _buildFooter() {
    return pw.Column(
      children: [
        pw.Container(
          width: double.infinity,
          height: 1,
          color: PdfColor.fromHex('#E0E0E0'),
        ),
        pw.SizedBox(height: 20),
        pw.Text(
          'Thank you for your business!',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: PdfColor.fromHex('#1976D2'),
          ),
          textAlign: pw.TextAlign.center,
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          'This is a computer-generated invoice.',
          style: pw.TextStyle(
            fontSize: 10,
            color: PdfColor.fromHex('#999999'),
          ),
          textAlign: pw.TextAlign.center,
        ),
        pw.SizedBox(height: 20),
        pw.Container(
          padding: pw.EdgeInsets.all(15),
          decoration: pw.BoxDecoration(
            color: PdfColor.fromHex('#E3F2FD'),
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Column(
            children: [
              pw.Text(
                'Payment Terms & Conditions',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromHex('#1976D2'),
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                '• All payments should be made within 30 days of invoice date\n'
                    '• Late payments may be subject to a 1.5% monthly service charge\n'
                    '• Please include invoice number with payment\n'
                    '• For questions about this invoice, please contact us',
                style: pw.TextStyle(fontSize: 9, color: PdfColor.fromHex('#666666')),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final hour = dateTime.hour == 0 ? 12 : (dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour);
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '${dateTime.day} ${months[dateTime.month]} ${dateTime.year} at $hour:${dateTime.minute.toString().padLeft(2, '0')} $period';
  }

  Future<String> _savePDF(pw.Document pdf, String billNumber) async {
    // Request storage permission
    if (Platform.isAndroid) {
      var status = await Permission.storage.status;
      if (!status.isGranted) {
        status = await Permission.storage.request();
        if (!status.isGranted) {
          throw Exception('Storage permission not granted');
        }
      }
    }

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
    final fileName = 'Bill_${billNumber}_${DateTime.now().millisecondsSinceEpoch}.pdf';
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