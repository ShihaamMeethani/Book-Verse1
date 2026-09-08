import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import '../../theme/app_colors.dart';

class PDFViewerScreen extends StatefulWidget {
  final String title;
  final Uint8List? pdfBytes;
  final String? pdfUrl;
  final String? filePath;

  const PDFViewerScreen({
    super.key,
    required this.title,
    this.pdfBytes,
    this.pdfUrl,
    this.filePath,
  }) : assert(
          pdfBytes != null || pdfUrl != null || filePath != null,
          'At least one of pdfBytes, pdfUrl, or filePath must be provided',
        );

  @override
  State<PDFViewerScreen> createState() => _PDFViewerScreenState();
}

class _PDFViewerScreenState extends State<PDFViewerScreen> {
  Uint8List? _bytes;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _resolveBytes();
  }

  Future<void> _resolveBytes() async {
    if (widget.pdfBytes != null) {
      setState(() {
        _bytes = widget.pdfBytes;
        _isLoading = false;
      });
      return;
    }

    if (widget.filePath != null && widget.filePath!.isNotEmpty) {
      try {
        final file = File(widget.filePath!);
        final bytes = await file.readAsBytes();
        if (mounted) {
          setState(() {
            _bytes = bytes;
            _isLoading = false;
          });
        }
        return;
      } catch (e) {
        if (mounted) {
          setState(() {
            _error = 'Error loading local PDF: $e';
            _isLoading = false;
          });
        }
        return;
      }
    }

    if (widget.pdfUrl != null && widget.pdfUrl!.isNotEmpty) {
      try {
        final response = await http.get(Uri.parse(widget.pdfUrl!));
        if (response.statusCode != 200) {
          throw Exception('HTTP ${response.statusCode}');
        }
        if (mounted) {
          setState(() {
            _bytes = response.bodyBytes;
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _error = e.toString();
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ink,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: 16),
            Text('Loading PDF…', style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    if (_error != null || _bytes == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.broken_image_rounded, color: AppColors.primary, size: 48),
              const SizedBox(height: 12),
              const Text(
                'Failed to load PDF',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Text(
                _error ?? 'Unable to display PDF content',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return PdfPreview(
      build: (format) => _bytes!,
      canChangeOrientation: false,
      canChangePageFormat: false,
      canDebug: false,
      allowSharing: true,
      allowPrinting: true,
      initialPageFormat: PdfPageFormat.a4,
      pdfFileName: '${widget.title}.pdf',
    );
  }
}
