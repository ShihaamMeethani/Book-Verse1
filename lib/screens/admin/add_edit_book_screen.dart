import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../models/book_model.dart';
import '../../services/firestore_service.dart';
import '../../services/storage_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';

class AddEditBookScreen extends StatefulWidget {
  final Book? book;
  const AddEditBookScreen({super.key, this.book});

  @override
  State<AddEditBookScreen> createState() => _AddEditBookScreenState();
}

class _AddEditBookScreenState extends State<AddEditBookScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = FirestoreService();
  final _storage = StorageService();
  final _uuid = const Uuid();

  late TextEditingController _title,
      _author,
      _description,
      _price,
      _discountPrice,
      _stock,
      _pages,
      _genres,
      _isbn,
      _coverUrlController;
  Uint8List? _newCoverBytes;
  String? _existingCoverUrl;
  bool _isBestseller = false, _isNewArrival = false, _isFeatured = false;
  bool _saving = false;


  @override
  void initState() {
    super.initState();
    final b = widget.book;
    _title = TextEditingController(text: b?.title ?? '');
    _author = TextEditingController(text: b?.author ?? '');
    _description = TextEditingController(text: b?.description ?? '');
    _price = TextEditingController(text: b?.price.toString() ?? '');
    _discountPrice = TextEditingController(text: b?.discountPrice?.toString() ?? '');
    _stock = TextEditingController(text: b?.stock.toString() ?? '');
    _pages = TextEditingController(text: b?.pages.toString() ?? '');
    _genres = TextEditingController(text: b?.genres.join(', ') ?? '');
    _isbn = TextEditingController(text: b?.isbn ?? '');
    _coverUrlController = TextEditingController(text: b?.coverUrl ?? '');
    _existingCoverUrl = b?.coverUrl;
    _isBestseller = b?.isBestseller ?? false;
    _isNewArrival = b?.isNewArrival ?? false;
    _isFeatured = b?.isFeatured ?? false;

    _coverUrlController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _title.dispose();
    _author.dispose();
    _description.dispose();
    _price.dispose();
    _discountPrice.dispose();
    _stock.dispose();
    _pages.dispose();
    _genres.dispose();
    _isbn.dispose();
    _coverUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _newCoverBytes = bytes;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      String coverUrl = _coverUrlController.text.trim();

      if (_newCoverBytes != null) {
        try {
          coverUrl = await _storage.uploadBookCoverBytes(_newCoverBytes!);
          _coverUrlController.text = coverUrl;
        } catch (storageError) {
          debugPrint('Cloudinary upload error: $storageError');
          throw Exception('Book cover upload failed. Please check your Cloudinary upload preset and try again.');
        }
      }

      if (coverUrl.isEmpty) {
        coverUrl = _existingCoverUrl ??
            'https://images.unsplash.com/photo-1544947950-fa07a98d237f?auto=format&fit=crop&w=800&q=80';
      }

      final parsedGenres = _genres.text
          .split(',')
          .map((g) => g.trim())
          .where((g) => g.isNotEmpty)
          .toList();

      final book = Book(
        id: widget.book?.id ?? _uuid.v4(),
        title: _title.text.trim(),
        author: _author.text.trim(),
        description: _description.text.trim().isEmpty
            ? 'A compelling and beautifully written book available now on BookVerse.'
            : _description.text.trim(),
        coverUrl: coverUrl,
        genres: parsedGenres.isEmpty ? ['General'] : parsedGenres,
        price: double.tryParse(_price.text.trim()) ?? 0,
        discountPrice: _discountPrice.text.trim().isEmpty
            ? null
            : double.tryParse(_discountPrice.text.trim()),
        stock: int.tryParse(_stock.text.trim()) ?? 10,
        pages: int.tryParse(_pages.text.trim()) ?? 150,
        isbn: _isbn.text.trim(),
        isBestseller: _isBestseller,
        isNewArrival: _isNewArrival,
        isFeatured: _isFeatured,
        releaseDate: widget.book?.releaseDate ?? DateTime.now(),
        avgRating: widget.book?.avgRating ?? 4.5,
        ratingCount: widget.book?.ratingCount ?? 1,
        soldCount: widget.book?.soldCount ?? 0,
      );

      await _service.addOrUpdateBook(book);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.book == null ? 'Book added successfully!' : 'Book updated successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      final message = e.toString().contains('permission-denied')
          ? 'You don\'t have admin permission to save books.'
          : 'Failed to save book: $e';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasBytes = _newCoverBytes != null;
    final urlText = _coverUrlController.text.trim();
    final hasUrl = urlText.isNotEmpty;
    final hasExisting = _existingCoverUrl != null && _existingCoverUrl!.isNotEmpty;

    ImageProvider? displayImage;
    if (hasBytes) {
      displayImage = MemoryImage(_newCoverBytes!);
    } else if (hasUrl) {
      displayImage = NetworkImage(urlText);
    } else if (hasExisting) {
      displayImage = NetworkImage(_existingCoverUrl!);
    }

    return Scaffold(
      appBar: AppBar(title: Text(widget.book == null ? 'Add Book' : 'Edit Book')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ── Cover Image Preview & Selector ─────────────────────────
            FadeInDown(
              duration: const Duration(milliseconds: 350),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOut,
                      height: 190,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceDim,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2), width: 1.2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        image: displayImage != null
                            ? DecorationImage(
                                image: displayImage,
                                fit: BoxFit.cover,
                                onError: (_, __) {},
                              )
                            : null,
                      ),
                      child: displayImage == null
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.add_photo_alternate_rounded,
                                        size: 36, color: AppColors.primary),
                                  ),
                                  const SizedBox(height: 10),
                                  const Text(
                                    'Tap to upload cover from device',
                                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Or paste an image URL below',
                                    style: TextStyle(
                                      color: AppColors.textSecondary.withValues(alpha: 0.8),
                                      fontSize: 11.5,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : Align(
                              alignment: Alignment.bottomRight,
                              child: Container(
                                margin: const EdgeInsets.all(10),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.65),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.edit_rounded, size: 14, color: Colors.white),
                                    SizedBox(width: 4),
                                    Text('Change Cover',
                                        style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  CustomTextField(
                    controller: _coverUrlController,
                    label: 'Cover Image URL (optional or paste online link)',
                    hint: 'https://images.unsplash.com/...',
                    keyboardType: TextInputType.url,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // ── Form fields ──────────────────────────────────────────
            FadeInUp(
              duration: const Duration(milliseconds: 350),
              delay: const Duration(milliseconds: 60),
              child: Column(
                children: [
                  CustomTextField(
                    controller: _title,
                    label: 'Title',
                    validator: (v) => v!.trim().isEmpty ? 'Please enter a book title' : null,
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    controller: _author,
                    label: 'Author',
                    validator: (v) => v!.trim().isEmpty ? 'Please enter author name' : null,
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    controller: _description,
                    label: 'Description',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    controller: _genres,
                    label: 'Genres (comma-separated, e.g. Fiction, Sci-Fi)',
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          controller: _price,
                          label: 'Price (\$)',
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          validator: (v) => v!.trim().isEmpty ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomTextField(
                          controller: _discountPrice,
                          label: 'Discount Price (optional)',
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          controller: _stock,
                          label: 'Stock Quantity',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomTextField(
                          controller: _pages,
                          label: 'Page Count',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    controller: _isbn,
                    label: 'ISBN (optional)',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // ── Flags / Badges ───────────────────────────────────────
            FadeInUp(
              duration: const Duration(milliseconds: 350),
              delay: const Duration(milliseconds: 100),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                margin: const EdgeInsets.only(top: 8),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Bestseller'),
                      subtitle: const Text('Highlights in Bestsellers section', style: TextStyle(fontSize: 11)),
                      value: _isBestseller,
                      onChanged: (v) => setState(() => _isBestseller = v),
                      activeThumbColor: AppColors.primary,
                    ),
                    SwitchListTile(
                      title: const Text('New Arrival'),
                      subtitle: const Text('Highlights in New Arrivals section', style: TextStyle(fontSize: 11)),
                      value: _isNewArrival,
                      onChanged: (v) => setState(() => _isNewArrival = v),
                      activeThumbColor: AppColors.primary,
                    ),
                    SwitchListTile(
                      title: const Text('Featured on Home'),
                      subtitle: const Text('Shows on top hero carousel on Home', style: TextStyle(fontSize: 11)),
                      value: _isFeatured,
                      onChanged: (v) => setState(() => _isFeatured = v),
                      activeThumbColor: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Save Button ──────────────────────────────────────────
            FadeInUp(
              duration: const Duration(milliseconds: 350),
              delay: const Duration(milliseconds: 140),
              child: CustomButton(
                label: widget.book == null ? 'Add Book' : 'Save Changes',
                isLoading: _saving,
                onPressed: _save,
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
