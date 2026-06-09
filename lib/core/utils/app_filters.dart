import 'package:flutter/material.dart';

class AppFilters {
  static const Map<String, String> filters = {
    'original': 'Original',
    'grayscale': 'Grayscale',
    'sepia': 'Sepia',
    'invert': 'Inverted',
    'vintage': 'Vintage',
    'warm': 'Warm Tone',
    'cool': 'Cool Tone',
  };

  static ColorFilter getFilter(String filterId) {
    switch (filterId) {
      case 'grayscale':
        return const ColorFilter.matrix([
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0,      0,      0,      1, 0,
        ]);
      case 'sepia':
        return const ColorFilter.matrix([
          0.393, 0.769, 0.189, 0, 0,
          0.349, 0.686, 0.168, 0, 0,
          0.272, 0.534, 0.131, 0, 0,
          0,     0,     0,     1, 0,
        ]);
      case 'invert':
        return const ColorFilter.matrix([
          -1,  0,  0, 0, 255,
           0, -1,  0, 0, 255,
           0,  0, -1, 0, 255,
           0,  0,  0, 1,   0,
        ]);
      case 'vintage':
        return const ColorFilter.matrix([
          0.9, 0.0, 0.0, 0.0, 0.0,
          0.0, 0.8, 0.0, 0.0, 0.0,
          0.0, 0.0, 0.5, 0.0, 0.0,
          0.0, 0.0, 0.0, 1.0, 0.0,
        ]);
      case 'warm':
        return const ColorFilter.matrix([
          1.2, 0.0, 0.0, 0.0, 10.0,
          0.0, 1.0, 0.0, 0.0, 5.0,
          0.0, 0.0, 0.8, 0.0, -10.0,
          0.0, 0.0, 0.0, 1.0, 0.0,
        ]);
      case 'cool':
        return const ColorFilter.matrix([
          0.8, 0.0, 0.0, 0.0, -10.0,
          0.0, 1.0, 0.0, 0.0, 5.0,
          0.0, 0.0, 1.2, 0.0, 15.0,
          0.0, 0.0, 0.0, 1.0, 0.0,
        ]);
      case 'original':
      default:
        return const ColorFilter.matrix([
          1, 0, 0, 0, 0,
          0, 1, 0, 0, 0,
          0, 0, 1, 0, 0,
          0, 0, 0, 1, 0,
        ]);
    }
  }
}
