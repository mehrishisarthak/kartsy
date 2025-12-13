// ---------------------------------------------------------------------------
// ✅ DYNAMIC REGION SERVICE
// Fetches serviceable areas from Firestore ('config/service_areas')
// Uses caching to ensure minimal read costs (1 read per session max).
// ---------------------------------------------------------------------------
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class RegionService {
  // Memory Cache
  static Map<String, List<String>>? _cachedRegions;

  // Fallback if offline or DB is empty
  static const Map<String, List<String>> _defaults = {
    'Rajasthan': ['Jaipur'],
  };

  /// Initialize: Fetches data only if cache is empty
  static Future<void> init() async {
    if (_cachedRegions != null) return; // Use Memory Cache (0 Cost)

    try {
      // Source.serverAndCache: Tries local persistence first, then network.
      final doc = await FirebaseFirestore.instance
          .collection('controls')
          .doc('service_areas')
          .get(const GetOptions(source: Source.serverAndCache));

      if (doc.exists && doc.data() != null) {
        _cachedRegions = {};
        doc.data()!.forEach((key, value) {
          if (value is List) {
            _cachedRegions![key] = List<String>.from(value);
          }
        });
      }
    } catch (e) {
      debugPrint("Warning: Could not fetch regions, using defaults. Error: $e");
    }

    // Ensure we never crash due to null
    _cachedRegions ??= _defaults;
  }

  static List<String> getStates() => _cachedRegions?.keys.toList() ?? _defaults.keys.toList();

  static List<String> getCities(String? state) {
    if (state == null) return [];
    return _cachedRegions?[state] ?? _defaults[state] ?? [];
  }
}
// ---------------------------------------------------------------------------
