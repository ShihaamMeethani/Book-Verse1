// ignore_for_file: prefer_const_constructors

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../models/book_model.dart';
import '../models/cart_item_model.dart';
import '../models/order_model.dart';
import '../screens/book_details/pdf_viewer_screen.dart';
import 'firestore_service.dart';

class BookPdfService {
  BookPdfService._();
  static final BookPdfService instance = BookPdfService._();

  /// Generates the raw PDF bytes in-memory for the specified book and order.
  /// Does NOT require any native file system or path_provider plugin channels!
  Future<Uint8List> generateBookPdfBytes({
    required BookOrder order,
    required CartItem item,
    Book? bookDetails,
  }) async {
    Book? book = bookDetails;
    if (book == null) {
      try {
        book = await FirestoreService().getBook(item.bookId);
      } catch (_) {}
    }

    final pdf = pw.Document();

    const primaryColor = PdfColor.fromInt(0xFF4F46E5);
    const darkInk = PdfColor.fromInt(0xFF0F172A);
    const textMuted = PdfColor.fromInt(0xFF64748B);
    const lightBg = PdfColor.fromInt(0xFFF8FAFC);
    const accentGold = PdfColor.fromInt(0xFFD97706);
    const borderCol = PdfColor.fromInt(0xFFE2E8F0);

    final orderDateStr = DateFormat('MMMM d, yyyy · hh:mm a').format(order.createdAt);
    final shortOrderId = order.id.isNotEmpty
        ? (order.id.length > 8 ? order.id.substring(0, 8).toUpperCase() : order.id.toUpperCase())
        : 'BV-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

    final authorName = (book != null && book.author.isNotEmpty) ? book.author : 'BookVerse Author';
    final genresStr = (book != null && book.genres.isNotEmpty) ? book.genres.join(', ') : 'Literature & Fiction';
    final pagesCount = (book != null && book.pages > 0) ? '${book.pages} pages' : 'Standard Edition';
    final isbnStr = (book != null && book.isbn.isNotEmpty) ? book.isbn : 'BV-ED-$shortOrderId';
    final languageStr = (book != null && book.language.isNotEmpty) ? book.language : 'English';

    final description = (book != null && book.description.isNotEmpty)
        ? book.description
        : 'Thank you for purchasing "${item.title}". This digital companion edition gives you an immediate preview and reader overview while your order is processed.';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (pw.Context context) {
          return [
            // Header Banner
            pw.Container(
              padding: const pw.EdgeInsets.all(18),
              decoration: const pw.BoxDecoration(
                color: darkInk,
                borderRadius: pw.BorderRadius.all(pw.Radius.circular(12)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'BOOKVERSE',
                        style: const pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Official Digital Pass & Book Preview',
                        style: const pw.TextStyle(
                          color: PdfColor.fromInt(0xFF94A3B8),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: const pw.BoxDecoration(
                      color: primaryColor,
                      borderRadius: pw.BorderRadius.all(pw.Radius.circular(20)),
                    ),
                    child: pw.Text(
                      'VERIFIED PURCHASE',
                      style: const pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 20),

            // Order Verification Pill Bar
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: const pw.BoxDecoration(
                color: lightBg,
                borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
                border: pw.Border.fromBorderSide(pw.BorderSide(color: borderCol)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('ORDER NUMBER', style: pw.TextStyle(color: textMuted, fontSize: 8, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 2),
                      pw.Text('#$shortOrderId', style: pw.TextStyle(color: darkInk, fontSize: 11, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('ORDER DATE', style: pw.TextStyle(color: textMuted, fontSize: 8, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 2),
                      pw.Text(orderDateStr, style: const pw.TextStyle(color: darkInk, fontSize: 10)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('ITEM PRICE', style: pw.TextStyle(color: textMuted, fontSize: 8, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 2),
                      pw.Text('\$${item.price.toStringAsFixed(2)}', style: pw.TextStyle(color: primaryColor, fontSize: 11, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 24),

            // Book Main Title & Author Card
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(20),
              decoration: const pw.BoxDecoration(
                border: pw.Border.fromBorderSide(pw.BorderSide(color: primaryColor, width: 1.5)),
                borderRadius: pw.BorderRadius.all(pw.Radius.circular(12)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: const pw.BoxDecoration(
                      color: PdfColor.fromInt(0xFFFEF3C7),
                      borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
                    ),
                    child: pw.Text(
                      genresStr.toUpperCase(),
                      style: pw.TextStyle(color: accentGold, fontSize: 9, fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    item.title,
                    style: pw.TextStyle(
                      color: darkInk,
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 6),
                  pw.Text(
                    'by $authorName',
                    style: const pw.TextStyle(
                      color: primaryColor,
                      fontSize: 14,
                      fontStyle: pw.FontStyle.italic,
                    ),
                  ),
                  pw.SizedBox(height: 14),
                  pw.Divider(color: borderCol, thickness: 1),
                  pw.SizedBox(height: 10),
                  // Metadata row
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      _buildMetaItem('Language', languageStr, textMuted, darkInk),
                      _buildMetaItem('Length', pagesCount, textMuted, darkInk),
                      _buildMetaItem('ISBN', isbnStr, textMuted, darkInk),
                      _buildMetaItem('Quantity', 'x${item.quantity}', textMuted, darkInk),
                    ],
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 24),

            // Book Synopsis / Description
            pw.Text(
              'About the Book',
              style: pw.TextStyle(color: darkInk, fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            pw.Container(
              padding: const pw.EdgeInsets.all(14),
              decoration: const pw.BoxDecoration(
                color: lightBg,
                borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Text(
                description,
                style: const pw.TextStyle(
                  color: darkInk,
                  fontSize: 10.5,
                  lineSpacing: 3,
                ),
              ),
            ),

            pw.SizedBox(height: 24),

            // Opening Chapter / Reader Excerpt Section
            pw.Text(
              'Sample Reading Excerpt',
              style: pw.TextStyle(color: darkInk, fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: const pw.BoxDecoration(
                color: PdfColors.white,
                borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
                border: pw.Border.fromBorderSide(pw.BorderSide(color: borderCol)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'PROLOGUE & OPENING PASSAGE',
                    style: const pw.TextStyle(
                      color: primaryColor,
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    'The words on the page seemed to hold their breath before revealing their secrets. Every great story begins with a single step into the unknown, and "${item.title}" invites you into a world crafted with precision, emotion, and wonder.\n\n'
                    '"In between the lines of ink and time, stories find those who are ready to listen."\n\n'
                    'As a valued BookVerse reader, this digital copy secures your access to upcoming chapter releases, author commentary, and priority reader rewards.',
                    style: const pw.TextStyle(
                      color: darkInk,
                      fontSize: 10,
                      lineSpacing: 4,
                      fontStyle: pw.FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 28),

            // Footer & QR Code
            pw.Container(
              padding: const pw.EdgeInsets.all(14),
              decoration: const pw.BoxDecoration(
                color: lightBg,
                borderRadius: pw.BorderRadius.all(pw.Radius.circular(10)),
                border: pw.Border.fromBorderSide(pw.BorderSide(color: borderCol)),
              ),
              child: pw.Row(
                children: [
                  pw.BarcodeWidget(
                    barcode: pw.Barcode.qrCode(),
                    data: 'BookVerse:Order=${order.id}:Book=${item.bookId}',
                    width: 55,
                    height: 55,
                  ),
                  pw.SizedBox(width: 16),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Verified Digital Reader Certificate',
                          style: pw.TextStyle(color: darkInk, fontSize: 10, fontWeight: pw.FontWeight.bold),
                        ),
                        pw.SizedBox(height: 3),
                        pw.Text(
                          'Scan QR code to verify order authenticity and access digital perks. Generated via BookVerse App.',
                          style: const pw.TextStyle(color: textMuted, fontSize: 8.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ];
        },
      ),
    );

    return await pdf.save();
  }

  static pw.Widget _buildMetaItem(String label, String value, PdfColor labelCol, PdfColor valCol) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label, style: pw.TextStyle(color: labelCol, fontSize: 8)),
        pw.SizedBox(height: 2),
        pw.Text(value, style: pw.TextStyle(color: valCol, fontSize: 9.5, fontWeight: pw.FontWeight.bold)),
      ],
    );
  }

  /// Writes bytes to disk using pure Dart Directory.systemTemp (no plugin required).
  Future<File> getPdfFile({
    required BookOrder order,
    required CartItem item,
    Book? bookDetails,
  }) async {
    final bytes = await generateBookPdfBytes(order: order, item: item, bookDetails: bookDetails);
    final tempDir = Directory.systemTemp;
    final shortOrderId = order.id.isNotEmpty
        ? (order.id.length > 8 ? order.id.substring(0, 8).toUpperCase() : order.id.toUpperCase())
        : 'BV';
    final sanitizedTitle = item.title.replaceAll(RegExp(r'[^\w\s-]'), '').replaceAll(' ', '_');
    final fileName = 'BookVerse_${sanitizedTitle}_$shortOrderId.pdf';
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsBytes(bytes);
    return file;
  }

  /// Generates the book PDF bytes and opens in-app viewer.
  Future<void> openBookPdf(
    BuildContext context, {
    required BookOrder order,
    required CartItem item,
    Book? bookDetails,
  }) async {
    try {
      final bytes = await generateBookPdfBytes(order: order, item: item, bookDetails: bookDetails);
      if (!context.mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PDFViewerScreen(
            title: item.title,
            pdfBytes: bytes,
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to open book PDF: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  /// Shares or downloads the PDF across all platforms.
  Future<void> shareBookPdf({
    required BookOrder order,
    required CartItem item,
    Book? bookDetails,
  }) async {
    final bytes = await generateBookPdfBytes(order: order, item: item, bookDetails: bookDetails);
    final shortOrderId = order.id.isNotEmpty
        ? (order.id.length > 8 ? order.id.substring(0, 8).toUpperCase() : order.id.toUpperCase())
        : 'BV';
    final sanitizedTitle = item.title.replaceAll(RegExp(r'[^\w\s-]'), '').replaceAll(' ', '_');
    final fileName = 'BookVerse_${sanitizedTitle}_$shortOrderId.pdf';

    try {
      // Primary: cross-platform Printing.sharePdf (supports Windows, Web, Android, iOS)
      await Printing.sharePdf(bytes: bytes, filename: fileName);
      return;
    } catch (_) {}

    // Fallback: share_plus using pure Dart systemTemp file
    try {
      final file = await getPdfFile(order: order, item: item, bookDetails: bookDetails);
      await Share.shareXFiles(
        [XFile(file.path, name: fileName, mimeType: 'application/pdf')],
        subject: '${item.title} — BookVerse Digital Edition',
        text: 'Here is your digital book copy of "${item.title}" from BookVerse.',
      );
    } catch (_) {}
  }
}
