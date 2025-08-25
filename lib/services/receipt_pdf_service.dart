import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:open_filex/open_filex.dart';
import 'package:school_management/model_class/invoice.dart'; // Assuming your Invoice model is here

class ReceiptPdfService {
  static Future<void> generateAndOpenReceiptPdf(Invoice invoice) async {
    final pdf = pw.Document();

    final image = pw.MemoryImage(
      (await rootBundle.load('images/school_logo.png')).buffer.asUint8List(),
    );

    // Load fonts
    final fontData = await rootBundle.load("assets/fonts/Poppins-Regular.ttf");
    final boldFontData = await rootBundle.load("assets/fonts/Poppins-Bold.ttf");
    final ttf = pw.Font.ttf(fontData);
    final boldTtf = pw.Font.ttf(boldFontData);
    final theme = pw.ThemeData.withFont(base: ttf, bold: boldTtf);

    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    // Helper to format timestamp to date
    String formatDate(int? timestamp) {
      if (timestamp == null) return 'N/A';
      return DateFormat.yMMMd()
          .format(DateTime.fromMillisecondsSinceEpoch(timestamp));
    }

    pdf.addPage(
      pw.Page(
        theme: theme,
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Image(image, width: 80, height: 80),
                  pw.SizedBox(width: 20),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'POLE STAR ACADEMY - SONITPUR, ASSAM',
                        style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold, fontSize: 18),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                          'No. 219/3 & 219/5, Gunjur, Whitefield Sarjapur Road, Bangalore - 560087'),
                      pw.Text('Tel: +91 88610 63812/ +91 88610 63814'),
                      pw.Text('Email: support.varthur@chrysalishigh.com'),
                    ],
                  ),
                ],
              ),
              pw.Divider(),
              pw.SizedBox(height: 8),
              pw.Center(
                  child: pw.Text('FEE RECEIPT',
                      style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold, fontSize: 16))),
              pw.SizedBox(height: 8),
              pw.Table(
                columnWidths: {
                  0: const pw.FlexColumnWidth(2),
                  1: const pw.FlexColumnWidth(3)
                },
                children: [
                  pw.TableRow(children: [
                    pw.Text('ADMISSION NUMBER:',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text(invoice.studentAdmissionNumber ??
                        'N/A'), // Use actual invoice data
                  ]),
                  pw.TableRow(children: [
                    pw.Text('RECEIPT NUMBER:',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text(invoice.id), // Use actual invoice data
                  ]),
                  pw.TableRow(children: [
                    pw.Text('STUDENT NAME:',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text(invoice.studentName), // Use actual invoice data
                  ]),
                  pw.TableRow(children: [
                    pw.Text('DATE:',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text(formatDate(
                        invoice.paymentDate)), // Use actual invoice data
                  ]),
                  pw.TableRow(children: [
                    pw.Text('CLASS:',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text(invoice.className), // Use actual invoice data
                  ]),
                  pw.TableRow(children: [
                    pw.Text('ACADEMIC YEAR:',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text(invoice.academicYear ??
                        'N/A'), // Use actual invoice data
                  ]),
                  pw.TableRow(children: [
                    pw.Text("FATHER'S NAME:",
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text(
                        invoice.fatherName ?? 'N/A'), // Use actual invoice data
                  ]),
                  pw.TableRow(children: [
                    pw.Text("MOTHER'S NAME:",
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text(
                        invoice.motherName ?? 'N/A'), // Use actual invoice data
                  ]),
                ],
              ),
              pw.Divider(),
              pw.SizedBox(height: 8),
              pw.Table(
                border: pw.TableBorder.all(),
                columnWidths: {
                  0: const pw.FlexColumnWidth(),
                  1: const pw.FlexColumnWidth()
                },
                children: [
                  pw.TableRow(children: [
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text('FEE CATEGORY',
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text('AMOUNT',
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                  ]),
                  // Assuming invoice.feeDetails is a list of maps or a custom object
                  // You'll need to adapt this based on your Invoice model's structure for fee details
                  pw.TableRow(children: [
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child:
                            pw.Text(invoice.feeCategory ?? 'N/A')), // Example
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(currencyFormat
                            .format(invoice.amountDue))), // Example
                  ]),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Text(
                      'TOTAL AMOUNT PAYABLE: ${currencyFormat.format(invoice.amountDue)}',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
              pw.SizedBox(height: 8),
              pw.Text('PAYMENTS',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  pw.TableRow(
                    decoration:
                        const pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text('S.NO',
                              style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold))),
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text('MODE OF PAYMENT',
                              style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold))),
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text('CHEQUE/REFERENCE NO',
                              style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold))),
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text('DATE',
                              style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold))),
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text('BANK NAME',
                              style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold))),
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text('AMOUNT',
                              style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold))),
                    ],
                  ),
                  // Assuming invoice.payments is a list of payment objects
                  pw.TableRow(children: [
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text('1')),
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child:
                            pw.Text(invoice.paymentMethod ?? 'N/A')), // Example
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child:
                            pw.Text(invoice.referenceNumber ?? '-')), // Example
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(
                            formatDate(invoice.paymentDate))), // Example
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(invoice.bankName ?? 'N/A')), // Example
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(currencyFormat
                            .format(invoice.amountPaid))), // Example
                  ]),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Text(
                      'TOTAL AMOUNT PAID: ${currencyFormat.format(invoice.amountPaid)}',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
              pw.SizedBox(height: 8),
              pw.Text(
                  'Rupees In Words:\n${invoice.amountPaidInWords ?? 'N/A'}'), // You'll need to add this field to your Invoice model or generate it
              pw.SizedBox(height: 8),
              pw.Text('REMARKS: ${invoice.remarks ?? ''}'), // Example
            ],
          );
        },
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File("${output.path}/invoice_receipt_${invoice.id}.pdf");
    await file.writeAsBytes(await pdf.save());

    await OpenFilex.open(file.path);
  }
}
