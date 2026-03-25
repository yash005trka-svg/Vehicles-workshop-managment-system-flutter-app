import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'pdfscreen.dart'; // Your existing InvoicePdf class

class PdfShareScreen extends StatefulWidget {
  final Map<String, dynamic> bill;
  const PdfShareScreen({super.key, required this.bill});

  @override
  State<PdfShareScreen> createState() => _PdfShareScreenState();
}

class _PdfShareScreenState extends State<PdfShareScreen> {
  Uint8List? pdfData;

  @override
  void initState() {
    super.initState();
    generatePdf();
  }

  Future<void> generatePdf() async {
    final pdf = await InvoicePdf.generate(widget.bill);
    setState(() {
      pdfData = pdf;
    });
  }

  Future<void> openWhatsApp() async {
    final number = widget.bill['customerMobile'].toString();

    // Make sure number includes country code, e.g., +91XXXXXXXXXX
    final message = Uri.encodeComponent(
        "Hello ${widget.bill['customerName']}, your invoice for ${widget.bill['vehicleName']} (${widget.bill['vehicleNumber']}) is ready."
    );

    final whatsappUrl = Uri.parse("whatsapp://send?phone=$number&text=$message");

    if (await canLaunchUrl(whatsappUrl)) {
      await launchUrl(whatsappUrl);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("WhatsApp is not installed.")),
      );
    }
  }

  Future<void> sharePdfFile() async {
    if (pdfData == null) return;

    try {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/invoice.pdf');
      await file.writeAsBytes(pdfData!);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: "Hello ${widget.bill['customerName']}, here is your invoice.",
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sharing PDF: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoice PDF'),
        actions: [
          /*IconButton(
            icon: const Icon(Icons.call, color: Colors.green),
            onPressed: openWhatsApp,
          ),*/
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: sharePdfFile,
          ),
        ],
      ),
      body: pdfData == null
          ? const Center(child: CircularProgressIndicator())
          : PdfPreview(
        build: (format) => pdfData!,
      ),
    );
  }
}
