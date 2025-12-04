import 'package:flutter/material.dart';

class AppWidget {
  static TextStyle boldTextStyle() {
    return const TextStyle(
      fontFamily: 'Lato',
      fontSize: 28.0,
      color: Color.fromRGBO(0, 0, 0, 1),
      fontWeight: FontWeight.bold,
    );
  }

  static TextStyle lightTextStyle() {
    return TextStyle(
      fontFamily: 'Lato',
      fontSize: 20.0,
      color: Colors.grey[600],
      fontWeight: FontWeight.w400,
    );
  }

  static TextStyle buttonTextStyle() {
    return const TextStyle(
      fontFamily: 'Lato',
      fontSize: 16.0,
      color: Colors.white,
      fontWeight: FontWeight.w600,
    );
  }

  // --- NEW: Global Rating Row Widget ---
  static Widget buildRatingRow(Map<String, dynamic> data) {
    double rating = (data['averageRating'] as num?)?.toDouble() ?? 0.0;
    int count = (data['reviewCount'] as num?)?.toInt() ?? 0;

    // Don't show anything if no reviews yet
    if (count == 0) return const SizedBox(height: 5);

    return Padding(
      padding: const EdgeInsets.only(bottom: 5.0),
      child: Row(
        children: [
          const Icon(Icons.star, color: Colors.amber, size: 14),
          const SizedBox(width: 4),
          Text(
            rating.toStringAsFixed(1), // e.g. "4.5"
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
          Text(
            " ($count)", // e.g. " (12)"
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
        ],
      ),
    );
  }
}