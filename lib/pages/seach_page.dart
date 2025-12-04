import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerce_shop/pages/product_details.dart';
import 'package:flutter/material.dart';

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
  
  // State Variables
  bool _isSearching = false; // Is the search logic running?
  bool _showAutocomplete = false; // Should we show the little box?
  
  // Filter Variables
  String _selectedSort = 'Relevance'; // Default
  final List<String> _sortOptions = ['Relevance', 'Price: Low to High', 'Price: High to Low'];

  Timer? _debounce; // To wait for user to stop typing before querying

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
    _debounce?.cancel();
    super.dispose();
  }

  // --- 1. AUTOCOMPLETE LOGIC ---
  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    
    // Wait 500ms after user stops typing to save database reads
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
    // Firestore is case-sensitive. This logic assumes product names are stored 
    // exactly how the user types them (e.g., "Watch"). 
    // For production, store a lowercase 'searchKey' in your database.
    
    // Capitalize first letter to match database format (e.g., "watch" -> "Watch")
    String formattedQuery = query; 
    if (query.isNotEmpty) {
       formattedQuery = query[0].toUpperCase() + query.substring(1);
    }

    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('products')
        .orderBy('Name')
        .startAt([formattedQuery])
        .endAt(['$formattedQuery\uf8ff']) // \uf8ff is a high unicode character
        .limit(5) // Only fetch top 5 for the small box
        .get();

    if (mounted) {
      setState(() {
        _autocompleteSuggestions = snapshot.docs;
        _showAutocomplete = true;
      });
    }
  }

  // --- 2. FULL SEARCH LOGIC ---
  Future<void> _performSearch(String query) async {
    setState(() {
      _showAutocomplete = false;
      _isSearching = true;
      _searchFocusNode.unfocus(); // Hide keyboard
    });

    String formattedQuery = query;
    if (query.isNotEmpty) {
      formattedQuery = query[0].toUpperCase() + query.substring(1);
    }

    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('products')
          .orderBy('Name')
          .startAt([formattedQuery])
          .endAt(['$formattedQuery\uf8ff'])
          .get();

      setState(() {
        _searchResults = snapshot.docs;
      });
      
      // Apply existing sort preference immediately
      _applySort();

    } catch (e) {
      print("Search Error: $e");
    } finally {
      setState(() => _isSearching = false);
    }
  }

  // --- 3. FILTER / SORT LOGIC (Client Side) ---
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
      } else {
        // Relevance (Default Firestore Order - Alphabetical usually)
        // We could re-query, or just accept the name order.
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          autofocus: true, // Open keyboard immediately
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
          // LAYER 1: The Results & Filters
          Column(
            children: [
              // Filters Bar (Only show if we have results)
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
                            padding: const EdgeInsets.all(16),
                            itemCount: _searchResults.length,
                            itemBuilder: (context, index) {
                              final data = _searchResults[index].data() as Map<String, dynamic>;
                              return _buildResultCard(data);
                            },
                          ),
              ),
            ],
          ),

          // LAYER 2: The Autocomplete Overlay (Shows on top)
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
                  physics: const NeverScrollableScrollPhysics(), // Just size to content
                  itemCount: _autocompleteSuggestions.length,
                  itemBuilder: (context, index) {
                    final data = _autocompleteSuggestions[index].data() as Map<String, dynamic>;
                    return ListTile(
                      leading: const Icon(Icons.history), // Or image
                      title: Text(data['Name'] ?? ''),
                      trailing: const Icon(Icons.north_west, size: 16),
                      onTap: () {
                        // User tapped a suggestion -> Fill text and search
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

  Widget _buildResultCard(Map<String, dynamic> data) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetails(productId: data['id'])));
      },
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
                  errorBuilder: (_,__,___) => const Icon(Icons.image, size: 40),
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
                        style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}