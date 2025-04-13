import 'package:flutter/material.dart';
import 'color_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';

class CartridgeColors {
  // Sabit renk listesi (varsayılan)
  static const Map<String, CartridgeColor> _defaultColors = {
    'BLA': CartridgeColor(
      code: 'BLA',
      backgroundColor: Colors.black,
      textColor: Colors.white,
    ),
    'BRN': CartridgeColor(
      code: 'BRN',
      backgroundColor: Color(0xFF8B4513), // Brown color
      textColor: Colors.white,
    ),
    'BLN': CartridgeColor(
      code: 'BLN',
      backgroundColor: Color(0xFFF5F5DC), // Beige/Blonde color
      textColor: Colors.black,
      hasBorder: true,
    ),
    'RED': CartridgeColor(
      code: 'RED',
      backgroundColor: Colors.red,
      textColor: Colors.white,
    ),
    'BLU': CartridgeColor(
      code: 'BLU',
      backgroundColor: Colors.blue,
      textColor: Colors.white,
    ),
    'YEL': CartridgeColor(
      code: 'YEL',
      backgroundColor: Colors.yellow,
      textColor: Colors.black,
      hasBorder: true,
    ),
    'CLR': CartridgeColor(
      code: 'CLR',
      backgroundColor: Colors.white,
      textColor: Colors.black,
      hasBorder: true,
    ),
    'PH': CartridgeColor(
      code: 'PH',
      backgroundColor: Color(0xFFFFA500), // Orange/Peach color
      textColor: Colors.white,
    ),
    'CB': CartridgeColor(
      code: 'CB',
      backgroundColor: Color(0xFF87CEEB), // Sky Blue color
      textColor: Colors.white,
    ),
    '40V': CartridgeColor(
      code: '40V',
      backgroundColor: Color(0xFF8A2BE2), // Purple/Violet color
      textColor: Colors.white,
    ),
    '5V': CartridgeColor(
      code: '5V',
      backgroundColor: Color(0xFFE6E6FA), // Light violet color
      textColor: Colors.black,
      hasBorder: true,
    ),
  };

  // Dinamik renk listesi (API'dan ve yerel değişikliklerden)
  static Map<String, CartridgeColor> _customColors = {};

  // Sistem başlatıldığında kayıtlı renkleri yükle
  static Future<void> loadSavedColors() async {
    try {
      SharedPreferences? prefs;
      try {
        // Timeout ile yakalayabilmek için try-catch kullanıyoruz
        prefs = await SharedPreferences.getInstance()
            .timeout(const Duration(seconds: 5));
      } catch (timeoutError) {
        print('SharedPreferences timed out, using default colors');
        prefs = null;
      }

      // Prefs null ise işlemi sonlandır
      if (prefs == null) return;

      final savedColors = prefs.getStringList('custom_colors');

      if (savedColors != null) {
        _customColors = {};
        for (final colorJson in savedColors) {
          final Map<String, dynamic> colorMap = json.decode(colorJson);
          final color = CartridgeColor(
            code: colorMap['code'],
            displayName: colorMap['displayName'] ?? '',
            backgroundColor: Color(colorMap['backgroundColor']),
            textColor: Color(colorMap['textColor']),
            hasBorder: colorMap['hasBorder'] ?? false,
            description: colorMap['description'],
          );
          _customColors[color.code] = color;
        }
      }
    } catch (e) {
      // Hata durumunda sadece logla, uygulamayı çökertme
      print('Failed to load saved colors: $e');
      // Hatanın kaynağını daha detaylı görmek için
      print('Error type: ${e.runtimeType}');
      print('Error stack: ${StackTrace.current}');

      // Hata oluşursa boş bir map ile devam et
      _customColors = {};
    }
  }

  // Renkleri SharedPreferences'e kaydet
  static Future<void> _saveColors() async {
    try {
      SharedPreferences? prefs;
      try {
        // Timeout ile yakalayabilmek için try-catch kullanıyoruz
        prefs = await SharedPreferences.getInstance()
            .timeout(const Duration(seconds: 5));
      } catch (timeoutError) {
        print('SharedPreferences save timed out');
        prefs = null;
      }

      // Prefs null ise işlemi sonlandır
      if (prefs == null) return;

      final colorsList = _customColors.values.map((color) {
        return json.encode({
          'code': color.code,
          'displayName': color.displayName,
          'backgroundColor': color.backgroundColor.value,
          'textColor': color.textColor.value,
          'hasBorder': color.hasBorder,
          'description': color.description,
        });
      }).toList();

      await prefs.setStringList('custom_colors', colorsList);
    } catch (e) {
      print('Failed to save colors: $e');
      // Hata stackini logla
      print('Error stack: ${StackTrace.current}');
    }
  }

  // Yeni renk ekle veya varsa güncelle
  static Future<bool> addOrUpdateColor(CartridgeColor color) async {
    _customColors[color.code] = color;
    await _saveColors();
    return true;
  }

  // Renk silme
  static Future<bool> deleteColor(String code) async {
    // Varsayılan renkleri silmeye izin verme
    if (_defaultColors.containsKey(code)) return false;

    _customColors.remove(code);
    await _saveColors();
    return true;
  }

  static CartridgeColor? getColorByCode(String code) {
    // Önce özel renklere bak, yoksa varsayılan renklere
    return _customColors[code] ?? _defaultColors[code];
  }

  static List<CartridgeColor> getAllColors() {
    // Tüm renkleri birleştir (özel renkler öncelikli)
    final Map<String, CartridgeColor> allColors = {}
      ..addAll(_defaultColors)
      ..addAll(_customColors);
    return allColors.values.toList();
  }

  static List<String> getAllColorCodes() {
    final Map<String, CartridgeColor> allColors = {}
      ..addAll(_defaultColors)
      ..addAll(_customColors);
    return allColors.keys.toList();
  }
}
