import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerce_shop/pages/product_details.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  
  // Data Variables
  List<DocumentSnapshot> _searchResults = [];
  List<DocumentSnapshot> _autocompleteSuggestions = [];
  
  // Pagination for Search Results
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;
  bool _hasMoreResults = true;
  DocumentSnapshot? _lastSearchDoc;
  static const int _searchLimit = 20;
  
  // State Variables
  bool _isSearching = false;
  bool _showAutocomplete = false;
  String _selectedSort = 'Relevance';
  final List<String> _sortOptions = ['Relevance', 'Price: Low to High', 'Price: High to Low'];

  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _searchFocusNode.addListener(() {
      setState(() {
        _showAutocomplete = _searchFocusNode.hasFocus && _searchController.text.isNotEmpty;
      });
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
        setState(() {
          _autocompleteSuggestions = [];
          _showAutocomplete = false;
        });
      }
    });
  }

  Future<void> _fetchAutocomplete(String query) async {
    String formattedQuery = query.isNotEmpty ? query[0].toUpperCase() + query.substring(1) : query;

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
  }

  // 🔥 PAGINATED SEARCH (NEW)
  Future<void> _performSearch(String query, {bool loadMore = false}) async {
    if (!loadMore) {
      setState(() {
        _searchResults.clear();
        _lastSearchDoc = null;
        _hasMoreResults = true;
        _showAutocomplete = false;
        _isSearching = true;
        _searchFocusNode.unfocus();
      });
    } else {
      setState(() => _isLoadingMore = true);
    }

    String formattedQuery = query.isNotEmpty ? query[0].toUpperCase() + query.substring(1) : query;

    try {
      Query queryRef = FirebaseFirestore.instance
          .collection('products')
          .orderBy('Name')
          .startAt([formattedQuery])
          .endAt(['$formattedQuery\uf8ff'])
          .limit(_searchLimit);

      if (loadMore && _lastSearchDoc != null) {
        queryRef = queryRef.startAfterDocument(_lastSearchDoc!);
      }

      QuerySnapshot snapshot = await queryRef.get();

      if (snapshot.docs.length < _searchLimit) {
        _hasMoreResults = false;
      }

      if (snapshot.docs.isNotEmpty) {
        _lastSearchDoc = snapshot.docs.last;
        setState(() {
          _searchResults.addAll(snapshot.docs);
        });
      }
      
      _applySort();
    } catch (e) {
      print("Search Error: $e");
    } finally {
      setState(() {
        _isSearching = false;
        _isLoadingMore = false;
      });
    }
  }

  void _applySort() {
    if (_searchResults.isEmpty) return;

    setState(() {
      if (_selectedSort == 'Price: Low to High') {
        _searchResults.sort((a, b) {
          double priceA = (a['Price'] as num).toDouble();
          double priceB = (b['Price'] as num).toDouble();
          return priceA.compareTo(priceB);
        });
      } else if (_selectedSort == 'Price: High to Low') {
        _searchResults.sort((a, b) {
          double priceA = (a['Price'] as num).toDouble();
          double priceB = (b['Price'] as num).toDouble();
          return priceB.compareTo(priceA);
        });
      }
    });
  }

  // 🔥 SEARCH RESULT SHIMMER (NEW)
  Widget _buildSearchShimmer() {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 200,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 120,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
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

  Widget _buildResultCard(Map<String, dynamic> data) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ProductDetails(productId: data['id'])),
      ),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  data['Image'] ?? '',
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (_,__,___) => Container(
                    width: 60,
                    height: 60,
                    color: Colors.grey[200],
                    child: const Icon(Icons.image, size: 30),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data['Name'] ?? 'No Name', 
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text("₹${data['Price']}", 
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary, 
                          fontWeight: FontWeight.bold
                        )),
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
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          autofocus: true,
          textInputAction: TextInputAction.search,
          onSubmitted: _performSearch,
          decoration: InputDecoration(
            hintText: "Search headphones, laptops...",
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.grey[400]),
          ),
          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              _searchController.clear();
              setState(() {
                _searchResults = [];
                _showAutocomplete = false;
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
                SingleChildScrollView(
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
                          backgroundColor: colorScheme.surface,
                          selectedColor: colorScheme.primaryContainer,
                          checkmarkColor: colorScheme.primary,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              
              // Results List
              Expanded(
                child: _isSearching
                    ? const Center(child: CircularProgressIndicator())
                    : _searchResults.isEmpty && _searchController.text.isNotEmpty && !_showAutocomplete
                        ? const Center(child: Text("No products found."))
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(16),
                            itemCount: _searchResults.length + (_isLoadingMore ? 3 : (_hasMoreResults ? 1 : 0)),
                            itemBuilder: (context, index) {
                              // 🔥 SHIMMER WHEN LOADING MORE
                              if (index >= _searchResults.length) {
                                return _buildSearchShimmer();
                              }

                              final data = _searchResults[index].data() as Map<String, dynamic>;
                              return _buildResultCard(data);
                            },
                          ),
              ),
            ],
          ),

          // Autocomplete Overlay
          if (_showAutocomplete && _autocompleteSuggestions.isNotEmpty)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Material(
                elevation: 4,
                color: colorScheme.surface,
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _autocompleteSuggestions.length,
                  itemBuilder: (context, index) {
                    final data = _autocompleteSuggestions[index].data() as Map<String, dynamic>;
                    return ListTile(
                      leading: const Icon(Icons.history),
                      title: Text(data['Name'] ?? ''),
                      trailing: const Icon(Icons.north_west, size: 16),
                      onTap: () {
                        _searchController.text = data['Name'];
                        _performSearch(data['Name']);
                      },
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}
