import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerce_shop/pages/product_details.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class SearchPage extends StatefulWidget {
  final String userCity;
  const SearchPage({super.key, this.userCity = 'Jaipur'});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  
  // Data Variables
  List<DocumentSnapshot> _searchResults = [];
  List<DocumentSnapshot> _autocompleteSuggestions = [];
  
  // Pagination
  final ScrollController _scrollController = ScrollController();
  
  // State Variables
  bool _isSearching = false;
  bool _showAutocomplete = false;
  String _selectedSort = 'Relevance';
  final List<String> _sortOptions = ['Relevance', 'Price: Low to High', 'Price: High to Low'];

  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });

    _searchController.addListener(_onSearchChanged);
    _searchFocusNode.addListener(() {
      if (mounted) {
        setState(() {
          _showAutocomplete = _searchFocusNode.hasFocus && _searchController.text.isNotEmpty;
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (_searchController.text.trim().isNotEmpty) {
        _fetchAutocomplete(_searchController.text.trim());
      } else {
        if(mounted) {
          setState(() {
            _autocompleteSuggestions = [];
            _showAutocomplete = false;
          });
        }
      }
    });
  }

  Future<void> _fetchAutocomplete(String query) async {
    String formattedQuery = query.isNotEmpty ? query[0].toUpperCase() + query.substring(1) : query;

    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('products')
          .orderBy('Name')
          .startAt([formattedQuery])
          .endAt(['$formattedQuery\uf8ff'])
          .limit(5)
          .get();

      if (mounted) {
        setState(() {
          _autocompleteSuggestions = snapshot.docs;
          _showAutocomplete = true;
        });
      }
    } catch (e) {
      debugPrint("Autocomplete error: $e");
    }
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) return;

    setState(() {
      _isSearching = true;
      _showAutocomplete = false;
      _searchFocusNode.unfocus();
      _searchResults = []; 
    });

    String formattedQuery = query.isNotEmpty ? query[0].toUpperCase() + query.substring(1) : query;

    try {
      Query queryRef = FirebaseFirestore.instance
          .collection('products')
          .where(
            Filter.or(
              Filter('category', isEqualTo: 'Home Decor'),
              Filter.and(
                Filter('category', isEqualTo: 'Furniture'),
                Filter('city', isEqualTo: widget.userCity),
              ),
            ),
          )
          .orderBy('Name')
          .startAt([formattedQuery])
          .endAt(['$formattedQuery\uf8ff'])
          .limit(50); 

      QuerySnapshot snapshot = await queryRef.get();

      setState(() {
        _searchResults = snapshot.docs;
        _isSearching = false;
      });
      
      _applySort(); 

    } catch (e) {
      debugPrint("Search Error: $e");
      if (mounted) setState(() => _isSearching = false);
    }
  }

  void _applySort() {
    if (_searchResults.isEmpty) return;

    setState(() {
      if (_selectedSort == 'Price: Low to High') {
        _searchResults.sort((a, b) {
          double priceA = ((a.data() as Map)['Price'] as num).toDouble();
          double priceB = ((b.data() as Map)['Price'] as num).toDouble();
          return priceA.compareTo(priceB);
        });
      } else if (_selectedSort == 'Price: High to Low') {
        _searchResults.sort((a, b) {
          double priceA = ((a.data() as Map)['Price'] as num).toDouble();
          double priceB = ((b.data() as Map)['Price'] as num).toDouble();
          return priceB.compareTo(priceA);
        });
      }
    });
  }

  // --- WIDGETS ---

  Widget _buildSearchShimmer(bool isDark) {
    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;
    final containerColor = isDark ? Colors.grey[900] : Colors.white;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: isDark ? Colors.transparent : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Shimmer.fromColors(
          baseColor: baseColor,
          highlightColor: highlightColor,
          child: Row(
            children: [
              Container(
                width: 70, height: 70,
                decoration: BoxDecoration(color: containerColor, borderRadius: BorderRadius.circular(8)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(width: double.infinity, height: 16, color: containerColor),
                    const SizedBox(height: 8),
                    Container(width: 100, height: 14, color: containerColor),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultCard(Map<String, dynamic> data, bool isDark, ColorScheme colorScheme) {
    final bool isGlobalItem = (data['category'] ?? '') != 'Furniture';
    final String itemCity = data['city'] ?? 'India';
    
    double rating = (data['averageRating'] as num?)?.toDouble() ?? 0.0;
    int reviewCount = (data['reviewCount'] as num?)?.toInt() ?? 0;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ProductDetails(productId: data['id'])),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isDark ? colorScheme.surfaceContainerHighest : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            if (!isDark) // No shadows in dark mode for cleaner look
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: data['Image'] ?? '',
                  width: 70, height: 70, fit: BoxFit.cover,
                  placeholder: (context, url) => Container(width: 70, height: 70, color: Colors.grey[200]),
                  errorWidget: (_,__,___) => const Icon(Icons.image_not_supported, color: Colors.grey),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['Name'] ?? 'No Name', 
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    
                    if (reviewCount > 0)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4.0),
                        child: Row(
                          children: [
                            const Icon(Icons.star, size: 14, color: Colors.amber),
                            const SizedBox(width: 4),
                            Text("$rating ($reviewCount)", style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                          ],
                        ),
                      ),
                      
                    Text(
                      "₹${data['Price']}", 
                      style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.w900, fontSize: 15),
                    ),
                    
                    if (isGlobalItem)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text("Ships from $itemCity", style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          textInputAction: TextInputAction.search,
          onSubmitted: (val) => _performSearch(val),
          style: TextStyle(color: colorScheme.onSurface, fontSize: 16),
          decoration: InputDecoration(
            hintText: "Search in ${widget.userCity}...",
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.grey[400]),
          ),
        ),
        actions: [
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: Icon(Icons.clear, color: colorScheme.onSurface),
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _searchResults = [];
                  _showAutocomplete = false;
                  _isSearching = false;
                });
              },
            )
        ],
      ),
      body: Stack(
        children: [
          // Results & Filters
          Column(
            children: [
              // Filters Bar
              if (_searchResults.isNotEmpty)
                Container(
                  color: colorScheme.surface,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(
                      children: _sortOptions.map((option) {
                        final isSelected = _selectedSort == option;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: FilterChip(
                            label: Text(option),
                            selected: isSelected,
                            onSelected: (bool selected) {
                              if (selected) {
                                setState(() => _selectedSort = option);
                                _applySort();
                              }
                            },
                            backgroundColor: isDark ? Colors.grey[800] : Colors.grey[100],
                            selectedColor: colorScheme.primaryContainer,
                            checkmarkColor: colorScheme.primary,
                            labelStyle: TextStyle(
                              color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
                            ),
                            side: BorderSide.none,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              
              // Results List
              Expanded(
                child: _isSearching 
                    ? ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: 5,
                        itemBuilder: (_,__) => _buildSearchShimmer(isDark))
                    : _searchResults.isEmpty && _searchController.text.isNotEmpty && !_showAutocomplete
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.search_off, size: 64, color: isDark ? Colors.grey[700] : Colors.grey[300]),
                                const SizedBox(height: 16),
                                Text("No products found.", style: TextStyle(color: Colors.grey[600])),
                              ],
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(16),
                            itemCount: _searchResults.length,
                            itemBuilder: (context, index) {
                              final data = _searchResults[index].data() as Map<String, dynamic>;
                              return _buildResultCard(data, isDark, colorScheme);
                            },
                          ),
              ),
            ],
          ),

          // Autocomplete Overlay
          if (_showAutocomplete && _autocompleteSuggestions.isNotEmpty)
            Positioned.fill(
              top: 0,
              child: Material(
                color: Colors.black54, 
                child: Column(
                  children: [
                    Container(
                      color: colorScheme.surface,
                      constraints: const BoxConstraints(maxHeight: 300),
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        itemCount: _autocompleteSuggestions.length,
                        itemBuilder: (context, index) {
                          final data = _autocompleteSuggestions[index].data() as Map<String, dynamic>;
                          return ListTile(
                            leading: Icon(Icons.history, size: 20, color: Colors.grey[400]),
                            title: Text(data['Name'] ?? '', style: TextStyle(color: colorScheme.onSurface)),
                            trailing: Icon(Icons.north_west, size: 16, color: Colors.grey[400]),
                            onTap: () {
                              _searchController.text = data['Name'];
                              _performSearch(data['Name']);
                            },
                          );
                        },
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _showAutocomplete = false),
                        child: Container(color: Colors.transparent),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}