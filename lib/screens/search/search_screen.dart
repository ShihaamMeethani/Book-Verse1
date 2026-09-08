import 'package:flutter/material.dart';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import '../../models/book_model.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/empty_state.dart';
import '../home/widgets/book_card.dart';
import '../../providers/book_provider.dart';

class SearchScreen extends StatefulWidget {
  final String? initialQuery;
  const SearchScreen({super.key, this.initialQuery});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _service = FirestoreService();
  late final TextEditingController _controller;
  Timer? _debounce;
  List<Book> _results = [];
  bool _searched = false;
  bool _isLoading = false;
  SortOption _sort = SortOption.popularity;

  final List<String> _trendingSearches = [
    'Atomic Habits',
    'Sci-Fi',
    'Psychology',
    'Fantasy',
    'Self-Help',
    'Bestseller',
  ];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery ?? '');
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _executeSearch(widget.initialQuery!);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      _executeSearch(query);
    });
  }

  void _executeSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _results = [];
        _searched = false;
        _isLoading = false;
      });
      return;
    }
    setState(() => _isLoading = true);
    final results = await _service.searchBooks(query.trim());
    _applySort(results);
    if (mounted) {
      setState(() {
        _searched = true;
        _isLoading = false;
      });
    }
  }

  void _applySort(List<Book> results) {
    switch (_sort) {
      case SortOption.priceLowHigh:
        results.sort((a, b) => a.effectivePrice.compareTo(b.effectivePrice));
        break;
      case SortOption.priceHighLow:
        results.sort((a, b) => b.effectivePrice.compareTo(a.effectivePrice));
        break;
      case SortOption.newest:
        results.sort((a, b) => b.releaseDate.compareTo(a.releaseDate));
        break;
      case SortOption.rating:
        results.sort((a, b) => b.avgRating.compareTo(a.avgRating));
        break;
      case SortOption.popularity:
        results.sort((a, b) => b.soldCount.compareTo(a.soldCount));
        break;
    }
    _results = results;
  }

  void _quickSearch(String term) {
    _controller.text = term;
    _executeSearch(term);
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                onPressed: () => Navigator.pop(context),
              )
            : const Padding(
                padding: EdgeInsets.only(left: 16),
                child: Icon(Icons.travel_explore_rounded, color: AppColors.primary),
              ),
        title: Container(
          height: 46,
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            color: dark ? AppColors.surfaceRaised : AppColors.paperSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: dark ? AppColors.surfaceBorder : AppColors.paperBorder,
            ),
          ),
          child: TextField(
            controller: _controller,
            autofocus: false,
            onChanged: _onChanged,
            style: GoogleFonts.inter(fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Search title, author, or genre...',
              hintStyle: GoogleFonts.inter(fontSize: 13.5, color: AppColors.textSecondary),
              prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary, size: 22),
              suffixIcon: _controller.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18, color: AppColors.textSecondary),
                      onPressed: () {
                        _controller.clear();
                        _executeSearch('');
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isLoading)
            const LinearProgressIndicator(minHeight: 2, color: AppColors.primary),
          if (_searched)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 16, 8),
              child: Row(
                children: [
                  Text(
                    '${_results.length} books found',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: dark ? AppColors.surfaceRaised : AppColors.paperSurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: dark ? AppColors.surfaceBorder : AppColors.paperBorder,
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<SortOption>(
                        value: _sort,
                        icon: const Icon(Icons.sort_rounded, size: 18, color: AppColors.primary),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: dark ? Colors.white : AppColors.ink,
                        ),
                        dropdownColor: dark ? AppColors.surfaceRaised : AppColors.paperSurface,
                        items: const [
                          DropdownMenuItem(value: SortOption.popularity, child: Text('Most Popular')),
                          DropdownMenuItem(value: SortOption.priceLowHigh, child: Text('Price: Low to High')),
                          DropdownMenuItem(value: SortOption.priceHighLow, child: Text('Price: High to Low')),
                          DropdownMenuItem(value: SortOption.newest, child: Text('Newest Release')),
                          DropdownMenuItem(value: SortOption.rating, child: Text('Highest Rated')),
                        ],
                        onChanged: (v) {
                          if (v == null) return;
                          setState(() {
                            _sort = v;
                            _applySort(List.of(_results));
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: !_searched
                ? SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Trending Searches',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _trendingSearches.map((tag) {
                            return ActionChip(
                              label: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.trending_up_rounded, size: 14, color: AppColors.primary),
                                  const SizedBox(width: 6),
                                  Text(
                                    tag,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              backgroundColor: dark ? AppColors.surfaceRaised : AppColors.paperSurface,
                              side: BorderSide(
                                color: dark ? AppColors.surfaceBorder : AppColors.paperBorder,
                              ),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              onPressed: () => _quickSearch(tag),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 32),
                        const EmptyState(
                          icon: Icons.travel_explore_rounded,
                          title: 'Discover Your Next Literary Adventure',
                          subtitle: 'Search across thousands of curated titles, acclaimed authors, and genres.',
                        ),
                      ],
                    ),
                  )
                : _results.isEmpty
                    ? const EmptyState(
                        icon: Icons.sentiment_dissatisfied_rounded,
                        title: 'No books found',
                        subtitle: 'Try searching for a different title, author name, or genre keyword.',
                      )
                    : FadeIn(
                        duration: const Duration(milliseconds: 250),
                        child: GridView.builder(
                          padding: const EdgeInsets.all(16),
                          physics: const BouncingScrollPhysics(),
                          itemCount: _results.length,
                          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 220,
                            mainAxisExtent: 330,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                          ),
                          itemBuilder: (context, i) => BookCard(book: _results[i]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

