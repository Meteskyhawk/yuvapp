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
      // Note: Since there is no real API, we're removing the API data simulation
      // and returning an empty list each time to prevent automatic additions
      print('Using empty cartridges list from remote source');
      return []; // Return empty list, do not make automatic additions
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
    // Note: TheColorAPI doesn't support this operation, simulate it
    print('Simulating insert cartridge: ${cartridge.id}');
    return Future.delayed(const Duration(milliseconds: 300));
  }

  @override
  Future<void> updateCartridge(CartridgeModel cartridge) async {
    // Note: TheColorAPI doesn't support this operation, simulate it
    print('Simulating update cartridge: ${cartridge.id}');
    return Future.delayed(const Duration(milliseconds: 300));
  }

  @override
  Future<void> deleteCartridge(String id) async {
    // Note: TheColorAPI doesn't support this operation, simulate it
    print('Simulating delete cartridge: $id');
    return Future.delayed(const Duration(milliseconds: 300));
  }

  @override
  Future<void> syncCartridges(List<CartridgeModel> cartridges) async {
    // Note: TheColorAPI doesn't support this operation, simulate it
    print('Simulating sync cartridges: ${cartridges.length} items');
    return Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Future<void> fetchColors() async {
    try {
      // Use the correct endpoint for TheColorAPI
      final response = await client
          .get(Uri.parse('$apiUrl/scheme?hex=8a4b3a&mode=analogic&count=5'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // TODO: Process and store the colors returned from the API
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
