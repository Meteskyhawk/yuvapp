import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/cartridge_model.dart';

/// Abstract class defining the contract for any remote data source.
abstract class RemoteDataSource {
  Future<List<CartridgeModel>> getAllCartridges();
  Future<List<CartridgeModel>> fetchCartridges();
  Future<void> insertCartridge(CartridgeModel cartridge);
  Future<void> updateCartridge(CartridgeModel cartridge);
  Future<void> deleteCartridge(String id);
  Future<void> syncCartridges(List<CartridgeModel> cartridges);
  Future<void> fetchColors();
}

/// HTTP-based implementation of [RemoteDataSource]
class HttpRemoteDataSource implements RemoteDataSource {
  final String apiUrl;
  final http.Client client;

  HttpRemoteDataSource({
    required this.apiUrl,
    http.Client? client,
  }) : client = client ?? http.Client();

  @override
  Future<List<CartridgeModel>> getAllCartridges() async {
    try {
      // Not: Gerçek API olmadığı için, API verisi simülasyonunu kaldırıyoruz
      // ve her seferinde boş liste döndürüyoruz, böylece otomatik ekleme olmayacak
      print('Using empty cartridges list from remote source');
      return []; // Boş liste döndür, otomatik ekleme yapma
    } catch (e) {
      print('Network error in getAllCartridges: $e');
      return [];
    }
  }

  @override
  Future<List<CartridgeModel>> fetchCartridges() async {
    try {
      // Same implementation as getAllCartridges as this is just an alias
      // for backward compatibility
      print('Using fetchCartridges method (alias for getAllCartridges)');
      return getAllCartridges();
    } catch (e) {
      print('Network error in fetchCartridges: $e');
      return [];
    }
  }

  @override
  Future<void> insertCartridge(CartridgeModel cartridge) async {
    // Not: TheColorAPI bu operasyonu desteklemiyor, simüle et
    print('Simulating insert cartridge: ${cartridge.id}');
    return Future.delayed(const Duration(milliseconds: 300));
  }

  @override
  Future<void> updateCartridge(CartridgeModel cartridge) async {
    // Not: TheColorAPI bu operasyonu desteklemiyor, simüle et
    print('Simulating update cartridge: ${cartridge.id}');
    return Future.delayed(const Duration(milliseconds: 300));
  }

  @override
  Future<void> deleteCartridge(String id) async {
    // Not: TheColorAPI bu operasyonu desteklemiyor, simüle et
    print('Simulating delete cartridge: $id');
    return Future.delayed(const Duration(milliseconds: 300));
  }

  @override
  Future<void> syncCartridges(List<CartridgeModel> cartridges) async {
    // Not: TheColorAPI bu operasyonu desteklemiyor, simüle et
    print('Simulating sync cartridges: ${cartridges.length} items');
    return Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Future<void> fetchColors() async {
    try {
      // TheColorAPI için doğru endpoint'i kullan
      final response = await client
          .get(Uri.parse('$apiUrl/scheme?hex=8a4b3a&mode=analogic&count=5'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // TODO: API'den dönen renkleri işle ve depolama işlemini gerçekleştir
        print('Colors fetched successfully: $data');
      } else {
        print('Failed to load colors: ${response.statusCode}');
        throw Exception('Failed to load colors: ${response.statusCode}');
      }
    } catch (e) {
      print('Network error in fetchColors: $e');
      throw Exception('Network error: $e');
    }
  }
}
