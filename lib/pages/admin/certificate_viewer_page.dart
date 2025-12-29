//certificate_viewer_page.dart
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart'; // For flutter_pdfview
// Alternatively, use Syncfusion Flutter PDF Viewer if preferred

class CertificateViewerPage extends StatelessWidget {
  final String certificateUrl;

  const CertificateViewerPage({super.key, required this.certificateUrl});

  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('View Certificate'),
      backgroundColor: Colors.blue,
    ),
    body: Center(
      child: FutureBuilder<String>(
        future: _downloadPdf(certificateUrl),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else if (snapshot.hasData && snapshot.data != null) {
            return PDFView(
              filePath: snapshot.data,
              onError: (error) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('PDF Error: $error')),
                );
              },
              onRender: (pages) {
                print('PDF Rendered with $pages pages');
              },
            );
          } else {
            return const Text('Failed to load PDF');
          }
        },
      ),
    ),
  );
}

  Future<String> _downloadPdf(String url) async {
  try {
    final dir = await getTemporaryDirectory();
    final filePath = '${dir.path}/certificate.pdf';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);
      return filePath;
    } else {
      throw Exception('Failed to download PDF: HTTP ${response.statusCode}');
    }
  } catch (e) {
    throw Exception('Error downloading PDF: $e');
  }
}


}
