import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/color_model.dart';
import 'dart:developer' as developer;

/// API servis sınıfı - renk paletlerini TheColorAPI'den yönetmek için
class ApiService {
  // TheColorAPI base URL
  static const String baseUrl = 'https://www.thecolorapi.com';

  // HTTP istemcisi
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

  /// API URL'sini dışarıdan ayarlamak için
  static String? _customBaseUrl;

  static void setBaseUrl(String url) {
    _customBaseUrl = url;
    developer.log('API URL set to: $url', name: 'ApiService');
  }

  static String get apiBaseUrl => _customBaseUrl ?? baseUrl;

  /// Renkleri API'den getir
  Future<List<CartridgeColor>> getColors() async {
    try {
      // TheColorAPI'den renk şeması al (default olarak analogic mod kullanıyoruz)
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
        // TheColorAPI'nin yanıtındaki renkleri parse et
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> colorsData = data['colors'] as List<dynamic>;

        // CartridgeColor listesine dönüştür
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

  /// Test amacıyla API bağlantısını kontrol et
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

  /// Yeni renk ekle (TheColorAPI gerçek bir kaydetme işlevine sahip değil, bu yüzden sadece
  /// yerel olarak çalışacak şekilde bir simülasyon yapıyoruz)
  Future<bool> addColor(CartridgeColor color) async {
    try {
      // Simüle edilmiş başarılı bir cevap
      await Future.delayed(const Duration(milliseconds: 800));
      return true;
    } catch (e) {
      developer.log('Error adding color: $e', name: 'ApiService');
      return false;
    }
  }

  /// Renk güncelle (Simüle edilmiş)
  Future<bool> updateColor(CartridgeColor color) async {
    try {
      // Simüle edilmiş başarılı bir cevap
      await Future.delayed(const Duration(milliseconds: 800));
      return true;
    } catch (e) {
      developer.log('Error updating color: $e', name: 'ApiService');
      return false;
    }
  }

  /// Renk sil (Simüle edilmiş)
  Future<bool> deleteColor(String colorCode) async {
    try {
      // Simüle edilmiş başarılı bir cevap
      await Future.delayed(const Duration(milliseconds: 800));
      return true;
    } catch (e) {
      developer.log('Error deleting color: $e', name: 'ApiService');
      return false;
    }
  }

  /// Hex string'i Color nesnesine çevirir
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
      return Colors.black; // Varsayılan renk
    }
  }

  /// Color nesnesini hex string'e çevirir
  String _colorToHex(Color color) {
    try {
      return '#${color.value.toRadixString(16).substring(2)}';
    } catch (e) {
      developer.log('Error converting color to hex: $e', name: 'ApiService');
      return '#000000'; // Varsayılan hex değeri
    }
  }

  /// Rengin açık veya koyu olduğunu kontrol eder
  bool _isLightColor(Color color) {
    // Rengin parlaklığını hesapla (0-255 arasında)
    final brightness =
        (0.299 * color.red + 0.587 * color.green + 0.114 * color.blue);
    // 128'den büyükse açık renk olarak kabul edilir
    return brightness > 128;
  }

  /// Arka plan rengine göre kontrastlı metin rengi döndürür
  Color _getContrastingTextColor(Color backgroundColor) {
    return _isLightColor(backgroundColor) ? Colors.black : Colors.white;
  }
}
