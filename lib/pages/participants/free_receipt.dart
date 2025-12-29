//free_receipt.dart
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class FreeReceiptPage extends StatelessWidget {
  final String tripName;
  final String dateTime;
  final String state;
  final String price;
  final String participantName;

  const FreeReceiptPage({
    Key? key,
    required this.tripName,
    required this.dateTime,
    required this.state,
    required this.price,
    required this.participantName,

  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip Receipt'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Trip Name: $tripName', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text('Date and Time: $dateTime', style: const TextStyle(fontSize: 18)),
            Text('State: $state', style: const TextStyle(fontSize: 18)),
            Text('Price: $price', style: const TextStyle(fontSize: 18)),
            Text('Participant: $participantName', style: const TextStyle(fontSize: 18)),
            const Spacer(),
            Center(
              child: ElevatedButton(
                onPressed: () => _createPdfAndShare(context),
                child: const Text('Download Receipt'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createPdfAndShare(BuildContext context) async {
    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Text('Trip Receipt', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold))
              ),
              pw.Padding(
                padding: pw.EdgeInsets.symmetric(vertical: 20),
                child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                    children: [
                      pw.Text('Billed To', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text('Receipt #0000457', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text('Date: $dateTime', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ]
                )
              ),
              pw.Table.fromTextArray(
                context: context,
                data: <List<String>>[
                  <String>['Trip Name', 'State', 'Price'],
                  <String>['$tripName', '$state', '$price'],
                ],
              ),
              pw.Padding(
                padding: pw.EdgeInsets.only(top: 20),
                child: pw.Text('Participant: $participantName', style: pw.TextStyle(fontSize: 18)),
              ),
              pw.Padding(
                padding: pw.EdgeInsets.only(top: 10),
                child: pw.Text('Thank you for joining!', style: pw.TextStyle(fontSize: 16, fontStyle: pw.FontStyle.italic)),
              ),
            ]
          );
        }
      )
    );

    final String dir = (await getApplicationDocumentsDirectory()).path;
    final String path = '$dir/receipt.pdf';
    final File file = File(path);
    await file.writeAsBytes(await doc.save());
    await Printing.sharePdf(bytes: await doc.save(), filename: 'receipt.pdf');
  }
}