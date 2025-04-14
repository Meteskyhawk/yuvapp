import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/color_model.dart';
import 'dart:developer' as developer;

/// API service class - for managing color palettes from TheColorAPI
class ApiService {
  // TheColorAPI base URL
  static const String baseUrl = 'https://www.thecolorapi.com';

  // HTTP client
  http.Client _client;

  // Singleton pattern
  static final ApiService _instance = ApiService._internal();

  factory ApiService({http.Client? client}) {
    if (client != null) {
      _instance._client = client;
    }
    return _instance;
  }

  ApiService._internal() : _client = http.Client();

  /// To set API URL from outside
  static String? _customBaseUrl;

  static void setBaseUrl(String url) {
    _customBaseUrl = url;
    developer.log('API URL set to: $url', name: 'ApiService');
  }

  static String get apiBaseUrl => _customBaseUrl ?? baseUrl;

  /// Get colors from API
  Future<List<CartridgeColor>> getColors() async {
    try {
      // Get color scheme from TheColorAPI (using analogic mode by default)
      final url = '$apiBaseUrl/scheme?hex=8a4b3a&mode=analogic&count=5';
      developer.log('Fetching colors from: $url', name: 'ApiService');

      final response = await _client.get(Uri.parse(url)).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          developer.log('API request timed out after 10 seconds',
              name: 'ApiService');
          throw Exception('API request timed out');
        },
      );

      developer.log('API response status: ${response.statusCode}',
          name: 'ApiService');

      if (response.statusCode == 200) {
        // Parse colors from TheColorAPI response
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> colorsData = data['colors'] as List<dynamic>;

        // Convert to CartridgeColor list
        return colorsData.map((colorData) {
          final hex = colorData['hex']['value'] as String;
          final name = colorData['name']['value'] as String;

          return CartridgeColor(
            code: name
                .substring(0, name.length > 3 ? 3 : name.length)
                .toUpperCase(),
            displayName: name,
            backgroundColor: _hexToColor(hex),
            textColor: _getContrastingTextColor(_hexToColor(hex)),
            hasBorder: _isLightColor(_hexToColor(hex)),
          );
        }).toList();
      } else {
        throw Exception('Failed to load colors: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('Error fetching colors: $e', name: 'ApiService');
      rethrow;
    }
  }

  /// Test API connection for testing purposes
  Future<bool> testApiConnection() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/id?hex=FF0000'))
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      developer.log('Test API connection error: $e', name: 'ApiService');
      return false;
    }
  }

  /// Add new color (TheColorAPI doesn't have a real save function, so we're simulating
  /// it to work locally)
  Future<bool> addColor(CartridgeColor color) async {
    try {
      // Simulated successful response
      await Future.delayed(const Duration(milliseconds: 800));
      return true;
    } catch (e) {
      developer.log('Error adding color: $e', name: 'ApiService');
      return false;
    }
  }

  /// Update color (Simulated)
  Future<bool> updateColor(CartridgeColor color) async {
    try {
      // Simulated successful response
      await Future.delayed(const Duration(milliseconds: 800));
      return true;
    } catch (e) {
      developer.log('Error updating color: $e', name: 'ApiService');
      return false;
    }
  }

  /// Delete color (Simulated)
  Future<bool> deleteColor(String colorCode) async {
    try {
      // Simulated successful response
      await Future.delayed(const Duration(milliseconds: 800));
      return true;
    } catch (e) {
      developer.log('Error deleting color: $e', name: 'ApiService');
      return false;
    }
  }

  /// Convert hex string to Color object
  Color _hexToColor(String hex) {
    try {
      if (hex.startsWith('#')) {
        hex = hex.substring(1);
      }
      if (hex.length == 6) {
        hex = 'FF$hex';
      }
      return Color(int.parse(hex, radix: 16));
    } catch (e) {
      developer.log('Error converting hex to color: $e, hex: $hex',
          name: 'ApiService');
      return Colors.black; // Default color
    }
  }

  /// Convert Color object to hex string
  String _colorToHex(Color color) {
    try {
      return '#${color.value.toRadixString(16).substring(2)}';
    } catch (e) {
      developer.log('Error converting color to hex: $e', name: 'ApiService');
      return '#000000'; // Default hex value
    }
  }

  /// Check if color is light or dark
  bool _isLightColor(Color color) {
    // Calculate color brightness (between 0-255)
    final brightness =
        (0.299 * color.red + 0.587 * color.green + 0.114 * color.blue);
    // If greater than 128, it's considered a light color
    return brightness > 128;
  }

  /// Returns contrasting text color based on background color
  Color _getContrastingTextColor(Color backgroundColor) {
    return _isLightColor(backgroundColor) ? Colors.black : Colors.white;
  }
}
