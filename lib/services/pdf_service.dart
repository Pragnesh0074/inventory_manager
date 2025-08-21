import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import '../models/sale.dart';
import '../models/shop.dart';

class PDFService {
  static Future<Uint8List> generateSaleBill(Sale sale, Shop shop) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            _buildHeader(shop, sale),
            pw.SizedBox(height: 20),
            _buildSaleInfo(sale),
            pw.SizedBox(height: 20),
            _buildItemsTable(sale),
            if (sale.additionalCosts.isNotEmpty) ...[
              pw.SizedBox(height: 20),
              _buildAdditionalCostsTable(sale),
            ],
            pw.SizedBox(height: 20),
            _buildTotalSection(sale),
            if (sale.notes != null && sale.notes!.isNotEmpty) ...[
              pw.SizedBox(height: 20),
              _buildNotesSection(sale),
            ],
            pw.Spacer(),
            _buildFooter(),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildHeader(Shop shop, Sale sale) {
    return pw.Row(
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
                color: PdfColors.blue800,
              ),
            ),
            pw.SizedBox(height: 5),
            pw.Text(
              shop.address,
              style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
            ),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              'SALE BILL',
              style: pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue800,
              ),
            ),
            pw.SizedBox(height: 5),
            pw.Text(
              'Bill #${sale.id.substring(sale.id.length - 8)}',
              style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildSaleInfo(Sale sale) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Date:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text(sale.formattedDateTime, style: const pw.TextStyle(fontSize: 12)),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Total Items:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text('${sale.totalQuantity}', style: const pw.TextStyle(fontSize: 12)),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Sale ID:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text(sale.id, style: const pw.TextStyle(fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildItemsTable(Sale sale) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Items',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          columnWidths: {
            0: const pw.FlexColumnWidth(3),
            1: const pw.FlexColumnWidth(1),
            2: const pw.FlexColumnWidth(1.5),
            3: const pw.FlexColumnWidth(1.5),
            4: const pw.FlexColumnWidth(1.5),
          },
          children: [
            // Header
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey100),
              children: [
                _buildTableCell('Item Name', isHeader: true),
                _buildTableCell('Qty', isHeader: true),
                _buildTableCell('Original Price', isHeader: true),
                _buildTableCell('Sale Price', isHeader: true),
                _buildTableCell('Total', isHeader: true),
              ],
            ),
            // Items
            ...sale.items.map((item) => pw.TableRow(
              children: [
                _buildTableCell(item.itemName),
                _buildTableCell('${item.quantity}'),
                _buildTableCell('₹${item.originalPrice.toStringAsFixed(2)}'),
                _buildTableCell(
                  '₹${item.salePrice.toStringAsFixed(2)}',
                  textColor: item.isPriceModified ? PdfColors.orange : PdfColors.black,
                ),
                _buildTableCell('₹${item.totalAmount.toStringAsFixed(2)}'),
              ],
            )).toList(),
            // Subtotal row
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey50),
              children: [
                _buildTableCell('Subtotal', isHeader: true, alignment: pw.Alignment.centerRight),
                _buildTableCell(''),
                _buildTableCell(''),
                _buildTableCell(''),
                _buildTableCell('₹${sale.subtotal.toStringAsFixed(2)}', isHeader: true),
              ],
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildAdditionalCostsTable(Sale sale) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Additional Costs',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          columnWidths: {
            0: const pw.FlexColumnWidth(3),
            1: const pw.FlexColumnWidth(3),
            2: const pw.FlexColumnWidth(1.5),
          },
          children: [
            // Header
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey100),
              children: [
                _buildTableCell('Name', isHeader: true),
                _buildTableCell('Description', isHeader: true),
                _buildTableCell('Amount', isHeader: true),
              ],
            ),
            // Additional costs
            ...sale.additionalCosts.map((cost) => pw.TableRow(
              children: [
                _buildTableCell(cost.name),
                _buildTableCell(cost.description ?? '-'),
                _buildTableCell('₹${cost.amount.toStringAsFixed(2)}'),
              ],
            )).toList(),
            // Additional costs total row
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey50),
              children: [
                _buildTableCell('Additional Costs Total', isHeader: true, alignment: pw.Alignment.centerRight),
                _buildTableCell(''),
                _buildTableCell('₹${sale.additionalCostsTotal.toStringAsFixed(2)}', isHeader: true),
              ],
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildTotalSection(Sale sale) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.blue800, width: 2),
        borderRadius: pw.BorderRadius.circular(8),
        color: PdfColors.blue50,
      ),
      child: pw.Column(
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Items Subtotal:', style: const pw.TextStyle(fontSize: 14)),
              pw.Text('₹${sale.subtotal.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 14)),
            ],
          ),
          if (sale.additionalCostsTotal > 0) ...[
            pw.SizedBox(height: 8),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Additional Costs:', style: const pw.TextStyle(fontSize: 14)),
                pw.Text('₹${sale.additionalCostsTotal.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 14)),
              ],
            ),
          ],
          pw.Divider(color: PdfColors.blue800, thickness: 1),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'GRAND TOTAL:',
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800),
              ),
              pw.Text(
                '₹${sale.grandTotal.toStringAsFixed(2)}',
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildNotesSection(Sale sale) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Notes',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300),
            borderRadius: pw.BorderRadius.circular(8),
            color: PdfColors.grey50,
          ),
          child: pw.Text(
            sale.notes!,
            style: const pw.TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildFooter() {
    return pw.Column(
      children: [
        pw.Divider(color: PdfColors.grey400),
        pw.SizedBox(height: 10),
        pw.Text(
          'Thank you for your business!',
          style: pw.TextStyle(fontSize: 14, fontStyle: pw.FontStyle.italic, color: PdfColors.grey600),
          textAlign: pw.TextAlign.center,
        ),
        pw.SizedBox(height: 5),
        pw.Text(
          'Generated on ${DateTime.now().toString().split('.')[0]}',
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey500),
          textAlign: pw.TextAlign.center,
        ),
      ],
    );
  }

  static pw.Widget _buildTableCell(
    String text, {
    bool isHeader = false,
    pw.Alignment? alignment,
    PdfColor? textColor,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      alignment: alignment ?? pw.Alignment.centerLeft,
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 12 : 10,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: textColor ?? (isHeader ? PdfColors.black : PdfColors.grey800),
        ),
      ),
    );
  }

  static Future<void> printBill(Sale sale, Shop shop) async {
    final pdfData = await generateSaleBill(sale, shop);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfData,
      name: 'Sale_Bill_${sale.id.substring(sale.id.length - 8)}.pdf',
    );
  }

  static Future<String> saveBillToFile(Sale sale, Shop shop) async {
    final pdfData = await generateSaleBill(sale, shop);
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/Sale_Bill_${sale.id.substring(sale.id.length - 8)}.pdf');
    await file.writeAsBytes(pdfData);
    return file.path;
  }
}